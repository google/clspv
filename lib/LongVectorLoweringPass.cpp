// Copyright 2020-2021 The Clspv Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include "BuiltinsEnum.h"
#include "Constants.h"
#include "clspv/Passes.h"

#include "Builtins.h"
#include "LongVectorLoweringPass.h"
#include "BitcastUtils.h"

#include <array>
#include <functional>
#include <map>

using namespace llvm;

#define DEBUG_TYPE "LongVectorLowering"

namespace {

using PartitionCallback = std::function<void(Instruction *)>;

Type *getPaddingArray(LLVMContext &Ctx, uint64_t Size) {
  if (Size % sizeof(uint32_t) == 0) {
    return ArrayType::get(Type::getInt32Ty(Ctx), Size / sizeof(uint32_t));
  } else if (Size % sizeof(uint16_t) == 0) {
    return ArrayType::get(Type::getInt16Ty(Ctx), Size / sizeof(uint16_t));
  } else {
    return ArrayType::get(Type::getInt8Ty(Ctx), Size / sizeof(uint8_t));
  }
}

/// Partition the @p Instructions based on their liveness.
void partitionInstructions(ArrayRef<WeakTrackingVH> Instructions,
                           PartitionCallback OnDead,
                           PartitionCallback OnAlive) {
  for (auto OldValueHandle : Instructions) {
    // Handle situations when the weak handle is no longer valid.
    if (!OldValueHandle.pointsToAliveValue()) {
      continue; // Nothing else to do for this handle.
    }

    auto *OldInstruction = cast<Instruction>(OldValueHandle);
    bool Dead = OldInstruction->use_empty();
    if (Dead) {
      OnDead(OldInstruction);
    } else {
      OnAlive(OldInstruction);
    }
  }
}

/// Get the scalar overload for the given LLVM @p Intrinsic.
Function *getIntrinsicScalarVersion(Function &Intrinsic) {
  auto id = Intrinsic.getIntrinsicID();
  assert(id != Intrinsic::not_intrinsic);

  switch (id) {
  default:
#ifndef NDEBUG
    dbgs() << "Intrinsic " << Intrinsic.getName() << " is not yet supported";
#endif
    llvm_unreachable("Missing support for intrinsic.");
    break;

  case Intrinsic::abs:
  case Intrinsic::ceil:
  case Intrinsic::copysign:
  case Intrinsic::cos:
  case Intrinsic::ctlz:
  case Intrinsic::exp:
  case Intrinsic::fabs:
  case Intrinsic::floor:
  case Intrinsic::fmuladd:
  case Intrinsic::fshl:
  case Intrinsic::log:
  case Intrinsic::pow:
  case Intrinsic::sin:
  case Intrinsic::sadd_sat:
  case Intrinsic::uadd_sat:
  case Intrinsic::ssub_sat:
  case Intrinsic::usub_sat: {
    SmallVector<Type *, 16> ParamTys;
    bool Success = Intrinsic::getIntrinsicSignature(&Intrinsic, ParamTys);
    assert(Success);
    (void)Success;

    // Map vectors to scalars.
    for (auto *&Param : ParamTys) {
      // TODO Need support for other types, like pointers. Need test case.
      assert(Param->isVectorTy());
      Param = Param->getScalarType();
    }

    return Intrinsic::getDeclaration(Intrinsic.getParent(), id, ParamTys);
    break;
  }
  }
}

std::string
getMangledScalarName(const clspv::Builtins::FunctionInfo &VectorInfo) {
  // Copy the informations about the vector version.
  // Return type is not important for mangling.
  // Only update arguments to make them scalars.
  clspv::Builtins::FunctionInfo ScalarInfo = VectorInfo;
  for (size_t i = 0; i < ScalarInfo.getParameterCount(); ++i) {
    ScalarInfo.getParameter(i).vector_size = 0;
  }
  return clspv::Builtins::GetMangledFunctionName(ScalarInfo);
}

std::string getSpirvCompliantName(const clspv::Builtins::FunctionInfo &IInfo) {
  // Copy the informations about the vector version.
  // Return type is not important for mangling.
  // Only update arguments to have spirv compatible vectors.
  clspv::Builtins::FunctionInfo Info = IInfo;
  for (size_t i = 0; i < Info.getParameterCount(); ++i) {
    if (Info.getParameter(i).vector_size > (int)clspv::SPIRVMaxVectorSize()) {
      Info.getParameter(i).vector_size = clspv::SPIRVMaxVectorSize();
    }
  }
  return clspv::Builtins::GetMangledFunctionName(Info);
}

Type *getScalarPointerType(Function &Builtin) {
  const auto &Info = clspv::Builtins::Lookup(&Builtin);
  switch (Info.getType()) {
    case clspv::Builtins::kSincos:
    case clspv::Builtins::kModf:
    case clspv::Builtins::kFract:
      return Builtin.getReturnType()->getScalarType();
    case clspv::Builtins::kFrexp:
    case clspv::Builtins::kRemquo:
    case clspv::Builtins::kLgammaR:
      return Type::getInt32Ty(Builtin.getParent()->getContext());
    case clspv::Builtins::kVloadHalf:
    case clspv::Builtins::kVloadaHalf:
    case clspv::Builtins::kVstoreHalf:
    case clspv::Builtins::kVstoreaHalf:
      return Type::getHalfTy(Builtin.getParent()->getContext());
    case clspv::Builtins::kVstore:
      return Builtin.getArg(0)->getType()->getScalarType();
    case clspv::Builtins::kVload:
      return Builtin.getReturnType()->getScalarType();
    default:
      // What about llvm intrinsics (e.g. memcpy) or other OpenCL builtins?
      return nullptr;
  }
}


/// Get the scalar overload for the given OpenCL builtin function @p Builtin.
Function *getBIFScalarVersion(Function &Builtin) {
  assert(!Builtin.isIntrinsic());
  const auto &Info = clspv::Builtins::Lookup(&Builtin);
  assert(Info.getType() != clspv::Builtins::kBuiltinNone);

  FunctionType *FunctionTy = nullptr;
  switch (Info.getType()) {
  default: {
#ifndef NDEBUG
    dbgs() << "BIF " << Builtin.getName() << " is not yet supported\n";
#endif
    llvm_unreachable("BIF not handled yet.");
  }

  // TODO Add support for other builtins by providing testcases and listing the
  // builtins here.
  case clspv::Builtins::kAbs:
  case clspv::Builtins::kAcosh:
  case clspv::Builtins::kAcos:
  case clspv::Builtins::kAcospi:
  case clspv::Builtins::kAsin:
  case clspv::Builtins::kAsinh:
  case clspv::Builtins::kAsinpi:
  case clspv::Builtins::kAtanh:
  case clspv::Builtins::kCeil:
  case clspv::Builtins::kClamp:
  case clspv::Builtins::kClspvFract:
  case clspv::Builtins::kCos:
  case clspv::Builtins::kCosh:
  case clspv::Builtins::kCospi:
  case clspv::Builtins::kDegrees:
  case clspv::Builtins::kExp:
  case clspv::Builtins::kExp2:
  case clspv::Builtins::kExpm1:
  case clspv::Builtins::kFabs:
  case clspv::Builtins::kFloor:
  case clspv::Builtins::kFma:
  case clspv::Builtins::kFmax:
  case clspv::Builtins::kFmin:
  case clspv::Builtins::kFract:
  case clspv::Builtins::kFrexp:
  case clspv::Builtins::kHalfCos:
  case clspv::Builtins::kHalfExp:
  case clspv::Builtins::kHalfExp2:
  case clspv::Builtins::kHalfLog:
  case clspv::Builtins::kHalfLog2:
  case clspv::Builtins::kHalfPowr:
  case clspv::Builtins::kHalfRsqrt:
  case clspv::Builtins::kHalfSin:
  case clspv::Builtins::kHalfTan:
  case clspv::Builtins::kLog:
  case clspv::Builtins::kLog2:
  case clspv::Builtins::kMax:
  case clspv::Builtins::kMin:
  case clspv::Builtins::kPopcount:
  case clspv::Builtins::kPow:
  case clspv::Builtins::kPowr:
  case clspv::Builtins::kRadians:
  case clspv::Builtins::kRint:
  case clspv::Builtins::kSign:
  case clspv::Builtins::kSin:
  case clspv::Builtins::kSinh:
  case clspv::Builtins::kSinpi:
  case clspv::Builtins::kSmoothstep:
  case clspv::Builtins::kSpirvOp:
  case clspv::Builtins::kStep:
  case clspv::Builtins::kTan:
  case clspv::Builtins::kTanh:
  case clspv::Builtins::kTrunc: {
    // Scalarise all the input/output types. Here we intentionally do not rely
    // on getEquivalentType because we want the scalar overload.
    SmallVector<Type *, 16> ScalarParamTys;
    for (auto &Param : Builtin.args()) {
      auto *ParamTy = Param.getType();

      Type *ScalarParamTy = nullptr;
      if (ParamTy->isPointerTy()) {
        ScalarParamTy = ParamTy;
        // TODO(#816): remove after final transition.
        if (!ParamTy->isOpaquePointerTy()) {
          auto *PointeeTy = ParamTy->getNonOpaquePointerElementType();
          assert(PointeeTy->isVectorTy() &&
                 "Unsupported kind of pointer type.");
          ScalarParamTy = PointerType::get(PointeeTy->getScalarType(),
                                           ParamTy->getPointerAddressSpace());
        }
      } else {
        assert((ParamTy->isVectorTy() || ParamTy->isFloatingPointTy() ||
                ParamTy->isIntegerTy()) &&
               "Unsupported kind of parameter type.");
        ScalarParamTy = ParamTy->getScalarType();
      }

      assert(ScalarParamTy);
      ScalarParamTys.push_back(ScalarParamTy);
    }

    Type *ReturnTy;
    if (!Builtin.getReturnType()->isVectorTy()) {
      SmallVector<Type *, 16> RetTys;
      assert(Builtin.getReturnType()->isStructTy());
      StructType *RetTy = cast<StructType>(Builtin.getReturnType());
      for (unsigned int eachRetTy = 0;
           eachRetTy < RetTy->getStructNumElements(); eachRetTy++) {
        assert(RetTy->getStructElementType(eachRetTy)->isVectorTy());
        RetTys.push_back(
            RetTy->getStructElementType(eachRetTy)->getScalarType());
      }
      ReturnTy = StructType::create(RetTys);
    } else {
      ReturnTy = Builtin.getReturnType()->getScalarType();
    }

    FunctionTy =
        FunctionType::get(ReturnTy, ScalarParamTys, Builtin.isVarArg());
    break;
  }
  }

  // Handle signedness of parameters by using clspv::Builtins API.
  std::string ScalarName = getMangledScalarName(Info);

  // Get the scalar version, which might not already exist in the module.
  auto *M = Builtin.getParent();
  auto *ScalarFn = M->getFunction(ScalarName);

  if (ScalarFn == nullptr) {
    ScalarFn = Function::Create(FunctionTy, Builtin.getLinkage(), ScalarName);
    ScalarFn->setCallingConv(Builtin.getCallingConv());
    ScalarFn->copyAttributesFrom(&Builtin);

    M->getFunctionList().push_front(ScalarFn);
  }

  assert(Builtin.getCallingConv() == ScalarFn->getCallingConv());

  return ScalarFn;
}

/// Convert the given value @p V to a value of the given @p EquivalentTy.
///
/// @return @p V when @p V's type is @p newType.
/// @return an equivalent pointer when both @p V and @p newType are pointers.
/// @return an equivalent vector when @p V is an aggregate.
/// @return an equivalent aggregate when @p V is a vector.
Value *convertEquivalentValue(IRBuilder<> &B, Value *V, Type *EquivalentTy,
                              const DataLayout *DL) {
  if (V->getType() == EquivalentTy) {
    return V;
  }

  if (EquivalentTy->isPointerTy()) {
    assert(V->getType()->isPointerTy());
    return B.CreateBitCast(V, EquivalentTy);
  }

  assert(EquivalentTy->isVectorTy() || EquivalentTy->isArrayTy() ||
         EquivalentTy->isStructTy());

  Value *NewValue = UndefValue::get(EquivalentTy);

  if (EquivalentTy->isStructTy()) {
    StructType *StructTy = dyn_cast<StructType>(EquivalentTy);
    StructType *VStructTy = dyn_cast<StructType>(V->getType());
    unsigned Arity = StructTy->getStructNumElements();
    // We use convertEquivalentValue to convert in both ways (vector to array
    // and array to vector). Thus, the structure with added padding elements
    // might not be the one we expect.
    bool inverse = false;
    if (Arity > VStructTy->getStructNumElements()) {
      inverse = true;
      Arity = VStructTy->getStructNumElements();
    }
    if (Arity == 0)
      return nullptr;
    for (unsigned i = 0; i < Arity; ++i) {
      unsigned idx_struct = i;
      unsigned idx_V =
          DL->getStructLayout(VStructTy)->getElementContainingOffset(
              DL->getStructLayout(StructTy)->getElementOffset(i));
      if (inverse) {
        idx_struct = DL->getStructLayout(StructTy)->getElementContainingOffset(
            DL->getStructLayout(VStructTy)->getElementOffset(i));
        idx_V = i;
      }
      Type *ElementType = StructTy->getContainedType(idx_struct);
      Value *Element = B.CreateExtractValue(V, {idx_V});
      Value *NewElement = convertEquivalentValue(B, Element, ElementType, DL);
      NewValue = B.CreateInsertValue(NewValue, NewElement, {idx_struct});
    }
  } else if (EquivalentTy->isVectorTy()) {
    assert(V->getType()->isArrayTy());

    unsigned Arity = V->getType()->getArrayNumElements();
    for (unsigned i = 0; i < Arity; ++i) {
      Value *Scalar = B.CreateExtractValue(V, i);
      NewValue = B.CreateInsertElement(NewValue, Scalar, i);
    }
  } else {
    assert(EquivalentTy->isArrayTy());
    assert(V->getType()->isVectorTy());

    unsigned Arity = EquivalentTy->getArrayNumElements();
    for (unsigned i = 0; i < Arity; ++i) {
      Value *Scalar = B.CreateExtractElement(V, i);
      NewValue = B.CreateInsertValue(NewValue, Scalar, i);
    }
  }

  return NewValue;
}

using ScalarOperationFactory =
    std::function<Value *(IRBuilder<> & /* B */, ArrayRef<Value *> /* Args */)>;

/// Scalarise the vector instruction @p I element-wise by invoking the operation
/// @p ScalarOperation.
Value *convertVectorOperation(Instruction &I, Type *EquivalentReturnTy,
                              ArrayRef<Value *> EquivalentArgs,
                              ScalarOperationFactory ScalarOperation,
                              Type *pointer_scalar_ty = nullptr) {
  assert(EquivalentReturnTy != nullptr);

  unsigned Arity;
  if (!EquivalentReturnTy->isArrayTy()) {
    assert(EquivalentReturnTy->isStructTy());
    assert(EquivalentReturnTy->getStructNumElements() != 0);
    StructType *RetTy = cast<StructType>(EquivalentReturnTy);
    Arity = UINT_MAX;
    for (unsigned int eachRetTy = 0; eachRetTy < RetTy->getStructNumElements();
         eachRetTy++) {
      assert(RetTy->getStructElementType(eachRetTy)->isArrayTy());
      assert(Arity == UINT_MAX ||
             Arity ==
                 RetTy->getStructElementType(eachRetTy)->getArrayNumElements());
      Arity = RetTy->getStructElementType(eachRetTy)->getArrayNumElements();
    }
  } else {
    Arity = EquivalentReturnTy->getArrayNumElements();
  }

  Value *ReturnValue = UndefValue::get(EquivalentReturnTy);

  auto &C = I.getContext();
  auto *IntTy = IntegerType::get(C, 32);
  auto *Zero = ConstantInt::get(IntTy, 0);

  // Invoke the scalar operation once for each vector element.
  IRBuilder<> B(&I);
  for (unsigned i = 0; i < Arity; ++i) {
    SmallVector<Value *, 16> Args;
    Args.resize(EquivalentArgs.size());

    for (unsigned j = 0; j < Args.size(); ++j) {
      auto *ArgTy = EquivalentArgs[j]->getType();
      if (ArgTy->isPointerTy()) {
        assert(pointer_scalar_ty && "Missing pointer scalar type");
        Args[j] = B.CreateInBoundsGEP(ArrayType::get(pointer_scalar_ty, Arity),
                                      EquivalentArgs[j],
                                      {Zero, ConstantInt::get(IntTy, i)});
      } else if (ArgTy->isArrayTy()) {
        Args[j] = B.CreateExtractValue(EquivalentArgs[j], i);
      } else {
        assert((ArgTy->isFloatingPointTy() || ArgTy->isIntegerTy()) &&
               "Unsupported kind of parameter type.");
        Args[j] = EquivalentArgs[j];
      }
    }

    Value *Scalar = ScalarOperation(B, Args);

    if (isa<Instruction>(Scalar)) {
      cast<Instruction>(Scalar)->copyIRFlags(&I);
    }

    if (!EquivalentReturnTy->isArrayTy()) {
      StructType *RetTy = cast<StructType>(EquivalentReturnTy);
      for (unsigned int eachRetTy = 0;
           eachRetTy < RetTy->getStructNumElements(); eachRetTy++) {
        auto Val = B.CreateExtractValue(Scalar, eachRetTy);
        ReturnValue = B.CreateInsertValue(ReturnValue, Val, {eachRetTy, i});
      }
    } else {
      ReturnValue = B.CreateInsertValue(ReturnValue, Scalar, i);
    }
  }

  return ReturnValue;
}

/// Map the arguments of the wrapper function (which are either not long-vectors
/// or aggregates of scalars) to the original arguments of the user-defined
/// function (which can be long-vectors). Handle pointers as well.
SmallVector<Value *, 16> mapWrapperArgsToWrappeeArgs(IRBuilder<> &B,
                                                     Function &Wrappee,
                                                     Function &Wrapper,
                                                     const DataLayout *DL) {
  SmallVector<Value *, 16> Args;

  std::size_t ArgumentCount = Wrapper.arg_size();
  Args.reserve(ArgumentCount);

  for (std::size_t i = 0; i < ArgumentCount; ++i) {
    auto *Arg = Wrappee.getArg(i);
    auto *NewArg = Wrapper.getArg(i);
    NewArg->takeName(Arg);
    auto *OldArgTy = Wrappee.getFunctionType()->getParamType(i);
    auto *EquivalentArg = convertEquivalentValue(B, NewArg, OldArgTy, DL);
    Args.push_back(EquivalentArg);
  }

  return Args;
}

/// Create a new, equivalent function with no long-vector types.
///
/// This is achieved by creating a new function (the "wrapper") which inlines
/// the given function (the "wrappee"). Only the parameters and return types are
/// mapped. The function body still needs to be lowered.
Function *createFunctionWithMappedTypes(Function &F,
                                        FunctionType *EquivalentFunctionTy,
                                        const DataLayout *DL) {
  assert(!F.isVarArg() && "varargs not supported");

  auto *Wrapper = Function::Create(EquivalentFunctionTy, F.getLinkage());
  Wrapper->takeName(&F);
  Wrapper->setCallingConv(F.getCallingConv());
  Wrapper->copyAttributesFrom(&F);
  Wrapper->copyMetadata(&F, /* offset */ 0);

  BasicBlock::Create(F.getContext(), "", Wrapper);
  IRBuilder<> B(&Wrapper->getEntryBlock());

  // Fill in the body of the wrapper function.
  auto WrappeeArgs = mapWrapperArgsToWrappeeArgs(B, F, *Wrapper, DL);
  CallInst *Call = B.CreateCall(&F, WrappeeArgs);
  if (Call->getType()->isVoidTy()) {
    B.CreateRetVoid();
  } else {
    auto *EquivalentReturnTy = EquivalentFunctionTy->getReturnType();
    Value *ReturnValue = convertEquivalentValue(B, Call, EquivalentReturnTy, DL);
    B.CreateRet(ReturnValue);
  }

  // Ensure wrapper has a parent or InlineFunction will crash.
  F.getParent()->getFunctionList().push_front(Wrapper);

  // Inline the original function.
  InlineFunctionInfo Info;
  auto Result = InlineFunction(*Call, Info);
  if (!Result.isSuccess()) {
    LLVM_DEBUG(dbgs() << "Failed to inline " << F.getName() << '\n');
    LLVM_DEBUG(dbgs() << "Reason: " << Result.getFailureReason() << '\n');
    llvm_unreachable("Unexpected failure when inlining function.");
  }

  return Wrapper;
}

FixedVectorType *getSpirvCompliantVectorType(FixedVectorType *VectorTy) {
  while (VectorTy->getNumElements() > clspv::SPIRVMaxVectorSize()) {
    VectorTy = FixedVectorType::getHalfElementsVectorType(VectorTy);
  }
  return VectorTy;
}

Value *convertOpCopyMemoryOperation(CallInst &VectorCall,
                                    ArrayRef<Value *> EquivalentArgs) {
  auto *DstOperand = EquivalentArgs[1];
  auto *SrcOperand = EquivalentArgs[2];
  auto *DstTy = DstOperand->getType()->getPointerElementType();
  assert(DstTy->isArrayTy());
  ArrayType *Ty = dyn_cast<ArrayType>(DstTy);

  IRBuilder<> B(&VectorCall);
  Value *ReturnValue = nullptr;
  unsigned int InitNumElements = Ty->getNumElements();
  // for each element
  for (unsigned eachElem = 0; eachElem < InitNumElements; eachElem++) {
    auto *SrcGEP = B.CreateGEP(
        SrcOperand->getType()->getScalarType()->getPointerElementType(),
        SrcOperand, {B.getInt32(0), B.getInt32(eachElem)});
    auto *Val =
        B.CreateLoad(SrcGEP->getType()->getPointerElementType(), SrcGEP);
    auto *DstGEP = B.CreateGEP(
        DstOperand->getType()->getScalarType()->getPointerElementType(),
        DstOperand, {B.getInt32(0), B.getInt32(eachElem)});
    ReturnValue = B.CreateStore(Val, DstGEP);
  }

  return ReturnValue;
}

using ReduceOperationFactory =
    std::function<Value *(IRBuilder<> &, Value *, Value *)>;

/*
 * Convert Any/All Operation on long vectors by using Any/All operators on
 * smaller sub-vectors.
 * Then reduce the severals results with Or/And operator.
 */
Value *convertOpAnyOrAllOperation(CallInst &VectorCall,
                                  ArrayRef<Value *> EquivalentArgs,
                                  ReduceOperationFactory Reduce) {
  assert(EquivalentArgs.size() == 2);
  auto *VectorOperand = VectorCall.getOperand(1);
  auto *VectorTy = VectorOperand->getType();
  assert(VectorTy->isVectorTy());
  FixedVectorType *FixedVectorTy = dyn_cast<FixedVectorType>(VectorTy);
  FixedVectorType *DstType = getSpirvCompliantVectorType(FixedVectorTy);

  Function *OpAnyOrAllInitialFunction = VectorCall.getCalledFunction();

  std::string OpAnyOrAllFunctionName =
      getSpirvCompliantName(clspv::Builtins::Lookup(OpAnyOrAllInitialFunction));

  auto *M = OpAnyOrAllInitialFunction->getParent();
  Function *OpAnyOrAllFunction = M->getFunction(OpAnyOrAllFunctionName);

  /* Create the function if it does not exist in the module */
  if (OpAnyOrAllFunction == nullptr) {
    SmallVector<Type *, 2> ParamTys;
    ParamTys.push_back(VectorCall.getOperand(0)->getType());
    ParamTys.push_back(DstType);

    OpAnyOrAllFunction = Function::Create(
        FunctionType::get(VectorCall.getFunctionType()->getReturnType(),
                          ParamTys, false),
        OpAnyOrAllInitialFunction->getLinkage(), OpAnyOrAllFunctionName);

    OpAnyOrAllFunction->setCallingConv(
        OpAnyOrAllInitialFunction->getCallingConv());
    OpAnyOrAllFunction->copyAttributesFrom(OpAnyOrAllInitialFunction);

    M->getFunctionList().push_front(OpAnyOrAllFunction);
  }

  IRBuilder<> B(&VectorCall);
  Value *ReturnValue = nullptr;
  Value *Vector = UndefValue::get(DstType);
  unsigned int InitNumElements = FixedVectorTy->getNumElements();
  unsigned int DstNumElements = DstType->getNumElements();
  // for each sub-vector calls
  for (unsigned eachCall = 0; eachCall < InitNumElements / DstNumElements;
       eachCall++) {

    // recreate the sub-vector
    for (unsigned eachVecElement = 0; eachVecElement < DstNumElements;
         eachVecElement++) {
      auto *Val = B.CreateExtractValue(
          EquivalentArgs[1], eachVecElement + eachCall * DstNumElements);
      Vector = B.CreateInsertElement(Vector, Val, B.getInt64(eachVecElement));
    }

    SmallVector<Value *, 2> Args;
    Args.push_back(EquivalentArgs[0]);
    Args.push_back(Vector);

    CallInst *Call = B.CreateCall(OpAnyOrAllFunction, Args);
    Call->copyIRFlags(&VectorCall);
    Call->copyMetadata(VectorCall);
    Call->setCallingConv(VectorCall.getCallingConv());

    if (eachCall == 0) {
      ReturnValue = Call;
    } else {
      ReturnValue = Reduce(B, ReturnValue, Call);
    }
  }

  assert(ReturnValue != nullptr);

  return ReturnValue;
}

} // namespace

PreservedAnalyses clspv::LongVectorLoweringPass::run(Module &M,
                                                     ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  DL = &M.getDataLayout();
  runOnGlobals(M);

  for (auto &F : M.functions()) {
    runOnFunction(F);
  }

  cleanDeadFunctions();
  cleanDeadGlobals();

  return PA;
}

Value *clspv::LongVectorLoweringPass::visit(Value *V) {
  // Already handled?
  auto it = ValueMap.find(V);
  if (it != ValueMap.end()) {
    return it->second;
  }

  if (isa<Argument>(V)) {
    assert(getEquivalentType(V->getType()) == nullptr &&
           "Argument not handled when visiting function.");
    return nullptr;
  }

  assert(isa<User>(V) && "Kind of llvm::Value not yet supported.");
  if (!handlingRequired(*cast<User>(V))) {
    return nullptr;
  }

  if (auto *I = dyn_cast<Instruction>(V)) {
    // Dispatch to the appropriate method using InstVisitor.
    return visit(I);
  }

  if (auto *C = dyn_cast<Constant>(V)) {
    return visitConstant(*C);
  }

#ifndef NDEBUG
  dbgs() << "Value not handled: " << *V << '\n';
#endif
  llvm_unreachable("Kind of value not handled yet.");
}

Value *clspv::LongVectorLoweringPass::visitConstant(Constant &Cst) {
  if (auto *GV = dyn_cast<GlobalVariable>(&Cst)) {
    auto *EquivalentGV = GlobalVariableMap[GV];
    assert(EquivalentGV &&
           "Global variable should have been already processed.");
    return EquivalentGV;
  }

  auto *EquivalentTy = getEquivalentType(Cst.getType());
  assert(EquivalentTy && "Nothing to lower.");

  if (Cst.isZeroValue()) {
    return Constant::getNullValue(EquivalentTy);
  }

  if (isa<UndefValue>(Cst)) {
    return UndefValue::get(EquivalentTy);
  }

  if (auto *Vector = dyn_cast<ConstantDataVector>(&Cst)) {
    assert(isa<ArrayType>(EquivalentTy));

    SmallVector<Constant *, 16> Scalars;
    for (unsigned i = 0; i < Vector->getNumElements(); ++i) {
      Scalars.push_back(Vector->getElementAsConstant(i));
    }

    return ConstantArray::get(cast<ArrayType>(EquivalentTy), Scalars);
  }

  if (auto *Vector = dyn_cast<ConstantVector>(&Cst)) {
    assert(isa<ArrayType>(EquivalentTy));

    SmallVector<Constant *, 16> Scalars;
    for (unsigned i = 0; i < Vector->getNumOperands(); ++i) {
      Scalars.push_back(dyn_cast<Constant>(visitOrSelf(Vector->getOperand(i))));
    }

    return ConstantArray::get(cast<ArrayType>(EquivalentTy), Scalars);
  }

  // TODO(#874): this pass needs updated to handle constantexpr more robustly.
  if (auto *CE = dyn_cast<ConstantExpr>(&Cst)) {
    switch (CE->getOpcode()) {
    case Instruction::GetElementPtr: {
      auto *GEP = cast<GEPOperator>(CE);
      auto *EquivalentSourceTy = getEquivalentType(GEP->getSourceElementType());
      Constant *EquivalentPointer = cast<Constant>(GEP->getPointerOperand());
      // TODO(#816): remove after final transition, but see also #874.
      if (!GEP->getType()->isOpaquePointerTy()) {
        EquivalentPointer = cast<Constant>(visit(GEP->getPointerOperand()));
      }
      SmallVector<Value *, 4> Indices(GEP->idx_begin(), GEP->idx_end());

      auto *EquivalentGEP = ConstantExpr::getGetElementPtr(
          EquivalentSourceTy, EquivalentPointer, Indices, GEP->isInBounds(),
          GEP->getInRangeIndex());

      return EquivalentGEP;
    }

    default:
#ifndef NDEBUG
      dbgs() << "Constant Expression not handled: " << *CE << '\n';
      dbgs() << "Constant Expression Opcode: " << CE->getOpcodeName() << '\n';
#endif
      llvm_unreachable("Unsupported kind of ConstantExpr");
    }
  }

#ifndef NDEBUG
  dbgs() << "Constant not handled: " << Cst << '\n';
#endif
  llvm_unreachable("Unsupported kind of constant");
}

Value *clspv::LongVectorLoweringPass::visitNAryOperator(Instruction &I) {
  SmallVector<Value *, 16> EquivalentArgs;
  for (auto &Operand : I.operands()) {
    Value *EquivalentOperand = visit(Operand.get());
    assert(EquivalentOperand && "operand not lowered");
    EquivalentArgs.push_back(EquivalentOperand);
  }
  Type *EquivalentReturnTy = getEquivalentType(I.getType());
  assert(EquivalentReturnTy && "return type not lowered");

  auto ScalarFactory = [Opcode = I.getOpcode()](auto &B, auto Args) {
    return B.CreateNAryOp(Opcode, Args);
  };

  Value *V = convertVectorOperation(I, EquivalentReturnTy, EquivalentArgs,
                                    ScalarFactory);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitInstruction(Instruction &I) {
#ifndef NDEBUG
  dbgs() << "Instruction not handled: " << I << '\n';
#endif
  llvm_unreachable("Missing support for instruction");
}

Value *clspv::LongVectorLoweringPass::visitAllocaInst(AllocaInst &I) {
  auto *EquivalentTy = getEquivalentType(I.getAllocatedType());
  assert(EquivalentTy && "type not lowered");

  Value *ArraySize = I.getArraySize();
  assert(visit(ArraySize) == nullptr && "TODO Need test case");

  IRBuilder<> B(&I);
  unsigned AS = I.getType()->getAddressSpace();
  auto *V = B.CreateAlloca(EquivalentTy, AS, ArraySize);
  V->setAlignment(I.getAlign());
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitBinaryOperator(BinaryOperator &I) {
  return visitNAryOperator(I);
}

Value *clspv::LongVectorLoweringPass::visitCallInst(CallInst &I) {
  SmallVector<Value *, 16> EquivalentArgs;
  for (auto &ArgUse : I.args()) {
    Value *Arg = ArgUse.get();
    Value *EquivalentArg = visitOrSelf(Arg);
    EquivalentArgs.push_back(EquivalentArg);
  }

  auto *ReturnTy = I.getType();
  auto *EquivalentReturnTy = getEquivalentTypeOrSelf(ReturnTy);

#ifndef NDEBUG
  bool NeedHandling = false;
  NeedHandling |= (EquivalentReturnTy != ReturnTy);
  NeedHandling |=
      !std::equal(I.arg_begin(), I.arg_end(), std::begin(EquivalentArgs),
                  [](auto const &ArgUse, Value *EquivalentArg) {
                    return ArgUse.get() == EquivalentArg;
                  });
  assert(NeedHandling && "Expected something to lower for this call.");
#endif

  Function *F = I.getCalledFunction();
  assert(F && "Only function calls are supported.");

  const auto &Info = clspv::Builtins::Lookup(F);
  bool SpirvOpBuiltin = (Info.getType() == clspv::Builtins::kSpirvOp);
  bool OpenCLBuiltin = (Info.getType() != clspv::Builtins::kBuiltinNone);
  bool Builtin = (OpenCLBuiltin || F->isIntrinsic());

  Value *V = nullptr;
  if (Builtin && F->isDeclaration() && !SpirvOpBuiltin) {
    V = convertAllBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
  } else if (SpirvOpBuiltin && F->isDeclaration()) {
    V = convertSpirvOpBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
  } else {
    V = convertUserDefinedFunctionCall(I, EquivalentArgs);
  }

  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitCastInst(CastInst &I) {
  auto *OriginalValue = I.getOperand(0);
  auto *EquivalentValue = visitOrSelf(OriginalValue);
  auto *OriginalDestTy = I.getDestTy();
  auto *EquivalentDestTy = getEquivalentTypeOrSelf(OriginalDestTy);

  // We expect something to lower, or this function shouldn't have been called.
  assert(((OriginalValue != EquivalentValue) ||
          (OriginalDestTy != EquivalentDestTy)) &&
         "nothing to lower");

  Value *V = nullptr;
  switch (I.getOpcode()) {
  case Instruction::BitCast: {
    if (OriginalDestTy->isPointerTy()) {
      // Bitcast over pointers are lowered to one bitcast.
      assert(EquivalentDestTy->isPointerTy());
      IRBuilder<> B(&I);
      V = B.CreateBitCast(EquivalentValue, EquivalentDestTy, I.getName());
    } else {
      IRBuilder<> B(&I);
      SmallVector<Value *, 8> Values;
      Values.push_back(EquivalentValue);
      if (EquivalentValue->getType()->isArrayTy()) {
        BitcastUtils::ExtractFromArray(B, Values);
      }
      BitcastUtils::ConvertInto(EquivalentDestTy, B, Values);
      V = Values[0];
    }
    break;
  }
  case Instruction::Trunc:
  case Instruction::ZExt:
  case Instruction::SExt:
  case Instruction::FPToUI:
  case Instruction::FPToSI:
  case Instruction::UIToFP:
  case Instruction::SIToFP:
  case Instruction::FPTrunc:
  case Instruction::FPExt: {
    // Scalarise the cast.
    //
    // Because all the elements of EquivalentDestTy have the same type, we can
    // simply pick the first.
    assert(EquivalentDestTy->isArrayTy());
    Type *ScalarTy = EquivalentDestTy->getArrayElementType();
    auto ScalarFactory = [&I, ScalarTy](auto &B, auto Args) {
      assert(Args.size() == 1);
      return B.CreateCast(I.getOpcode(), Args[0], ScalarTy, I.getName());
    };
    V = convertVectorOperation(I, EquivalentDestTy, EquivalentValue,
                               ScalarFactory);
    break;
  }

  default:
    llvm_unreachable("Cast unsupported.");
    break;
  }

  assert(V);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitCmpInst(CmpInst &I) {
  auto *EquivalentType = getEquivalentType(I.getType());
  assert(EquivalentType && "type not lowered");

  std::array<Value *, 2> EquivalentArgs{{
      visit(I.getOperand(0)),
      visit(I.getOperand(1)),
  }};
  assert(EquivalentArgs[0] && EquivalentArgs[1] && "argument(s) not lowered");

  Value *V = convertVectorOperation(
      I, EquivalentType, EquivalentArgs,
      [Int = I.isIntPredicate(), P = I.getPredicate()](auto &B, auto Args) {
        assert(Args.size() == 2);
        if (Int) {
          return B.CreateICmp(P, Args[0], Args[1]);
        } else {
          return B.CreateFCmp(P, Args[0], Args[1]);
        }
      });

  registerReplacement(I, *V);
  return V;
}

Value *
clspv::LongVectorLoweringPass::visitExtractElementInst(ExtractElementInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  assert(EquivalentValue && "value not lowered");

  ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1));
  // Non-constant indices could be done with a gep + load pair.
  assert(CI && "Dynamic indices not supported yet");
  unsigned Index = CI->getZExtValue();

  IRBuilder<> B(&I);
  auto *V = B.CreateExtractValue(EquivalentValue, Index);
  registerReplacement(I, *V);
  return V;
}

void clspv::LongVectorLoweringPass::reworkIndices(
    SmallVector<unsigned, 4> &Indices, Type *Ty) {
  auto EqTy = getEquivalentType(Ty);
  if (!EqTy)
    return;
  SmallVector<unsigned, 4> Idxs(Indices);
  SmallVector<uint64_t, 4> Indices_64b;
  Indices.clear();
  for (auto Idx : Idxs) {
    Indices.push_back(Idx);
    Indices_64b.push_back((uint64_t)Idx);
    auto IndexedTy = GetElementPtrInst::getIndexedType(Ty, Indices_64b);
    if (getEquivalentType(IndexedTy)) {
      auto id = Indices.pop_back_val();
      Indices_64b.pop_back();
      if (auto STy = dyn_cast<StructType>(
              GetElementPtrInst::getIndexedType(Ty, Indices_64b))) {
        auto off = DL->getStructLayout(STy)->getElementOffset(id);
        auto newId =
            DL->getStructLayout(dyn_cast<StructType>(getEquivalentType(STy)))
                ->getElementContainingOffset(off);
        Indices.push_back(newId);
        Indices_64b.push_back((uint64_t)newId);
      } else {
        Indices.push_back(id);
        Indices_64b.push_back((uint64_t)id);
      }
    }
  }
}

Value *
clspv::LongVectorLoweringPass::visitExtractValueInst(ExtractValueInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  if (!EquivalentValue)
    return nullptr;

  SmallVector<unsigned, 4> Indices(I.indices());
  reworkIndices(Indices, I.getOperand(0)->getType());

  IRBuilder<> B(&I);
  Value *V = B.CreateExtractValue(EquivalentValue, Indices);
  registerReplacement(I, *V);
  return V;
}

void clspv::LongVectorLoweringPass::reworkIndices(
    SmallVector<Value *, 4> &Indices, Type *Ty) {
  auto EqTy = getEquivalentType(Ty);
  if (!EqTy)
    return;
  assert(Indices.size() > 0);
  SmallVector<Value *, 4> Idxs(Indices);
  Indices.clear();
  Indices.push_back(Idxs[0]);
  for (unsigned i = 1; i < Idxs.size(); i++) {
    Indices.push_back(Idxs[i]);
    auto IndexedTy = GetElementPtrInst::getIndexedType(Ty, Indices);
    if (getEquivalentType(IndexedTy)) {
      auto Idx = Indices.pop_back_val();
      if (auto STy = dyn_cast<StructType>(
              GetElementPtrInst::getIndexedType(Ty, Indices))) {
        auto Cst = dyn_cast<ConstantInt>(Idx);
        if (!Cst) {
          llvm_unreachable("unexpected index for gep on struct type");
        }
        auto id = Cst->getZExtValue();
        auto off = DL->getStructLayout(STy)->getElementOffset(id);
        auto newId =
            DL->getStructLayout(dyn_cast<StructType>(getEquivalentType(STy)))
                ->getElementContainingOffset(off);
        Indices.push_back(ConstantInt::get(Idx->getType(), newId));
      } else {
        Indices.push_back(Idx);
      }
    }
  }
}

Value *
clspv::LongVectorLoweringPass::visitGetElementPtrInst(GetElementPtrInst &I) {
  auto *EquivalentPointer = I.getPointerOperand();
  auto *Type = getEquivalentType(I.getSourceElementType());
  // TODO(#816): remove after final transition.
  if (!I.getType()->isOpaquePointerTy()) {
    EquivalentPointer = visit(I.getPointerOperand());
    if (!EquivalentPointer)
      return nullptr;

    Type = EquivalentPointer->getType()
               ->getScalarType()
               ->getNonOpaquePointerElementType();
  } else if (!Type) {
    return nullptr;
  }

  IRBuilder<> B(&I);
  SmallVector<Value *, 4> Indices(I.indices());
  reworkIndices(Indices, I.getSourceElementType());

  Value *V;
  if (I.isInBounds()) {
    V = B.CreateInBoundsGEP(Type, EquivalentPointer, Indices);
  } else {
    V = B.CreateGEP(Type, EquivalentPointer, Indices);
  }
  registerReplacement(I, *V);
  return V;
}

Value *
clspv::LongVectorLoweringPass::visitInsertElementInst(InsertElementInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  assert(EquivalentValue && "value not lowered");

  Value *ScalarElement = I.getOperand(1);
  assert(ScalarElement->getType()->isIntegerTy() ||
         ScalarElement->getType()->isFloatingPointTy());

  ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2));
  // We'd have to lower this to a store-store-load sequence.
  assert(CI && "Dynamic indices not supported yet");
  unsigned Index = CI->getZExtValue();

  IRBuilder<> B(&I);
  auto *V = B.CreateInsertValue(EquivalentValue, ScalarElement, {Index});
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitInsertValueInst(InsertValueInst &I) {
  Value *EquivalentAggregate = visitOrSelf(I.getOperand(0));
  Value *EquivalentInsertValue = visitOrSelf(I.getOperand(1));

  if (EquivalentAggregate == I.getOperand(0) &&
      EquivalentInsertValue == I.getOperand(1)) // Nothing lowered
    return nullptr;

  SmallVector<unsigned, 4> Idxs(I.indices());
  reworkIndices(Idxs, I.getOperand(0)->getType());

  IRBuilder<> B(&I);
  Value *V =
      B.CreateInsertValue(EquivalentAggregate, EquivalentInsertValue, Idxs);
  registerReplacement(I, *V);

  return V;
}

Value *clspv::LongVectorLoweringPass::visitLoadInst(LoadInst &I) {
  Type *EquivalentTy = getEquivalentType(I.getType());
  assert(EquivalentTy && "type not lowered");
  auto *EquivalentPointer = I.getPointerOperand();
  // TODO(#816): remove after final transition.
  if (!I.getPointerOperand()->getType()->isOpaquePointerTy()) {
    EquivalentPointer = visit(I.getPointerOperand());
    assert(EquivalentPointer && "pointer not lowered");
  }

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedLoad(EquivalentTy, EquivalentPointer, I.getAlign(),
                                I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitPHINode(PHINode &I) {
  static std::map<PHINode *, Value *> PHIMap;
  if (PHIMap.count(&I) > 0) {
    return PHIMap[&I];
  }

  Type *EquivalentTy = getEquivalentType(I.getType());
  assert(EquivalentTy && "type not lowered");
  IRBuilder<> B(&I);
  auto NbVal = I.getNumIncomingValues();
  auto *V = B.CreatePHI(EquivalentTy, NbVal);
  PHIMap[&I] = V;

  for (unsigned EachVal = 0; EachVal < NbVal; EachVal++) {
    auto BB = I.getIncomingBlock(0);
    auto *NewVal = visitOrSelf(I.getIncomingValue(0));
    V->addIncoming(NewVal, BB);
    I.removeIncomingValue(BB, false);
  }

  registerReplacement(I, *V);
  PHIMap.erase(&I);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitSelectInst(SelectInst &I) {
  auto *EquivalentCondition = visitOrSelf(I.getCondition());
  auto *EquivalentTrueValue = visitOrSelf(I.getTrueValue());
  auto *EquivalentFalseValue = visitOrSelf(I.getFalseValue());

  assert(((EquivalentCondition != I.getCondition()) ||
          (EquivalentTrueValue != I.getTrueValue()) ||
          (EquivalentFalseValue != I.getFalseValue())) &&
         "nothing to lower");

  auto *EquivalentReturnTy = EquivalentTrueValue->getType();
  assert(EquivalentFalseValue->getType() == EquivalentReturnTy);

  // We have two cases to handle here:
  // - when the condition is a scalar to select one of the two long-vector
  //   alternatives. In this case, we would ideally create a single select
  //   instruction. However, the SPIR-V producer does not yet handle aggregate
  //   selections correctly. Therefore, we scalarise the selection when
  //   vectors/aggregates are involved.
  // - when the condition is a long-vector, too. In this case, we do an
  //   element-wise select and construct an aggregate for the result.
  Value *V = nullptr;
  if (EquivalentCondition->getType()->isSingleValueType()) {
    assert(EquivalentTrueValue->getType()->isAggregateType());
    assert(EquivalentFalseValue->getType()->isAggregateType());

    std::array<Value *, 2> EquivalentArgs{{
        EquivalentTrueValue,
        EquivalentFalseValue,
    }};
    auto ScalarFactory = [EquivalentCondition](auto &B, auto Args) {
      assert(Args.size() == 2);
      return B.CreateSelect(EquivalentCondition, Args[0], Args[1]);
    };

    V = convertVectorOperation(I, EquivalentReturnTy, EquivalentArgs,
                               ScalarFactory);
  } else {
    assert(EquivalentCondition->getType()->isAggregateType());

    std::array<Value *, 3> EquivalentArgs{{
        EquivalentCondition,
        EquivalentTrueValue,
        EquivalentFalseValue,
    }};

    auto ScalarFactory = [](auto &B, auto Args) {
      assert(Args.size() == 3);
      return B.CreateSelect(Args[0], Args[1], Args[2]);
    };
    V = convertVectorOperation(I, EquivalentReturnTy, EquivalentArgs,
                               ScalarFactory);
  }

  assert(V);
  registerReplacement(I, *V);
  return V;
}

Value *
clspv::LongVectorLoweringPass::visitShuffleVectorInst(ShuffleVectorInst &I) {
  assert(isa<FixedVectorType>(I.getType()) &&
         "shufflevector on scalable vectors is not supported.");

  auto *EquivalentLHS = visitOrSelf(I.getOperand(0));
  auto *EquivalentRHS = visitOrSelf(I.getOperand(1));
  auto *EquivalentType = getEquivalentTypeOrSelf(I.getType());

  assert(((EquivalentLHS != I.getOperand(0)) ||
          (EquivalentRHS != I.getOperand(1)) ||
          (EquivalentType != I.getType())) &&
         "nothing to lower");

  IRBuilder<> B(&I);

  // The arguments (LHS and RHS) could be either short-vector or long-vector
  // types. The latter are already lowered to an aggregate type.
  //
  // Extract the scalar at the given index using the appropriate method.
  auto getScalar = [&B](Value *Vector, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateExtractElement(Vector, Index);
    } else {
      assert(Vector->getType()->isArrayTy());
      return B.CreateExtractValue(Vector, Index);
    }
  };

  // The resulting value could be a short or a long vector as well.
  auto setScalar = [&B](Value *Vector, Value *Scalar, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateInsertElement(Vector, Scalar, Index);
    } else {
      assert(Vector->getType()->isArrayTy());
      return B.CreateInsertValue(Vector, Scalar, Index);
    }
  };

  unsigned Arity = I.getShuffleMask().size();
  auto *ScalarTy = I.getType()->getElementType();

  auto *LHSTy = cast<VectorType>(I.getOperand(0)->getType());
  assert(!LHSTy->getElementCount().isScalable() && "broken assumption");
  unsigned LHSArity = LHSTy->getElementCount().getFixedValue();

  // Construct the equivalent shuffled vector, as an array or a vector.
  Value *V = UndefValue::get(EquivalentType);
  for (unsigned i = 0; i < Arity; ++i) {
    int Mask = I.getMaskValue(i);
    assert(-1 <= Mask && "Unexpected mask value.");

    Value *Scalar = nullptr;
    if (Mask == -1) {
      Scalar = UndefValue::get(ScalarTy);
    } else if (static_cast<unsigned>(Mask) < LHSArity) {
      Scalar = getScalar(EquivalentLHS, Mask);
    } else {
      Scalar = getScalar(EquivalentRHS, Mask - LHSArity);
    }

    V = setScalar(V, Scalar, i);
  }

  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitStoreInst(StoreInst &I) {
  Value *EquivalentValue = visit(I.getValueOperand());
  assert(EquivalentValue && "value not lowered");
  Value *EquivalentPointer = I.getPointerOperand();
  // TODO(#816): remove after final transition.
  if (!I.getPointerOperand()->getType()->isOpaquePointerTy()) {
    EquivalentPointer = visit(I.getPointerOperand());
    assert(EquivalentPointer && "pointer not lowered");
  }

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedStore(EquivalentValue, EquivalentPointer,
                                 I.getAlign(), I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *clspv::LongVectorLoweringPass::visitUnaryOperator(UnaryOperator &I) {
  return visitNAryOperator(I);
}

bool clspv::LongVectorLoweringPass::handlingRequired(User &U) {
  if (getEquivalentType(U.getType()) != nullptr) {
    return true;
  }

  for (auto &Operand : U.operands()) {
    auto *OperandTy = Operand.get()->getType();
    if (getEquivalentType(OperandTy) != nullptr) {
      return true;
    }
  }

  // With opaque pointers, some users require special examination.
  if (auto *alloca = dyn_cast<AllocaInst>(&U)) {
    if (getEquivalentType(alloca->getAllocatedType()) != nullptr)
      return true;
  } else if (auto *gep = dyn_cast<GetElementPtrInst>(&U)) {
    if (getEquivalentType(gep->getSourceElementType()) != nullptr)
        return true;
  }

  return false;
}

void clspv::LongVectorLoweringPass::registerReplacement(Value &U, Value &V) {
  LLVM_DEBUG(dbgs() << "Replacement for " << U << ": " << V << '\n');
  assert(ValueMap.count(&U) == 0 && "Value already registered");
  ValueMap.insert({&U, &V});

  if (U.getType() == V.getType()) {
    LLVM_DEBUG(dbgs() << "\tAnd replace its usages.\n");
    U.replaceAllUsesWith(&V);
  }

  if (U.hasName()) {
    V.takeName(&U);
  }

  auto *I = dyn_cast<Instruction>(&U);
  auto *J = dyn_cast<Instruction>(&V);
  if (I && J) {
    J->copyMetadata(*I);
  }
}

Type *clspv::LongVectorLoweringPass::getEquivalentType(Type *Ty) {
  auto it = TypeMap.find(Ty);
  if (it != TypeMap.end()) {
    return it->second;
  }

  // Recursive implementation, taking advantage of the cache.
  auto *EquivalentTy = getEquivalentTypeImpl(Ty);
  TypeMap.insert({Ty, EquivalentTy});

  if (EquivalentTy) {
    LLVM_DEBUG(dbgs() << "Generating equivalent type for " << *Ty << ": "
                      << *EquivalentTy << '\n');
  }

  return EquivalentTy;
}

Type *clspv::LongVectorLoweringPass::getEquivalentTypeImpl(Type *Ty) {
  if (Ty->isIntegerTy() || Ty->isFloatingPointTy() || Ty->isVoidTy() ||
      Ty->isLabelTy() || Ty->isMetadataTy() || Ty->isOpaquePointerTy()) {
    // No lowering required.
    return nullptr;
  }

  if (auto *VectorTy = dyn_cast<VectorType>(Ty)) {
    unsigned Arity = VectorTy->getElementCount().getKnownMinValue();
    bool RequireLowering = (Arity >= 8);

    if (RequireLowering) {
      assert(!VectorTy->getElementCount().isScalable() &&
             "Unsupported scalable vector");

      // This assumes that the element type of the vector is a primitive scalar.
      // That is, no vectors of pointers for example.
      Type *ScalarTy = VectorTy->getElementType();
      assert((ScalarTy->isFloatingPointTy() || ScalarTy->isIntegerTy()) &&
             "Unsupported scalar type");

      return ArrayType::get(ScalarTy, Arity);
    }

    return nullptr;
  }

  // TODO(#816): remove after final transition.
  if (Ty->isPointerTy()) {
    if (auto *ElementTy =
            getEquivalentType(Ty->getNonOpaquePointerElementType())) {
      return ElementTy->getPointerTo(Ty->getPointerAddressSpace());
    }

    return nullptr;
  }

  if (auto *ArrayTy = dyn_cast<ArrayType>(Ty)) {
    if (auto *ElementTy = getEquivalentType(ArrayTy->getElementType())) {
      return ArrayType::get(ElementTy, ArrayTy->getNumElements());
    }

    return nullptr;
  }

  if (auto *StructTy = dyn_cast<StructType>(Ty)) {
    unsigned Arity = StructTy->getStructNumElements();
    if (Arity == 0)
      return nullptr;
    LLVMContext &Ctx = StructTy->getContainedType(0)->getContext();
    SmallVector<Type *, 16> Types;
    bool RequiredLowering = false;
    bool Packed = StructTy->isPacked();
    for (unsigned i = 0; i < Arity; ++i) {
      Type *CTy = StructTy->getContainedType(i);
      auto *EquivalentTy = getEquivalentType(CTy);
      if (EquivalentTy != nullptr) {
        Types.push_back(EquivalentTy);
        RequiredLowering = true;

        auto InitialOff = DL->getStructLayout(StructTy)->getElementOffset(i);
        auto NewOff = DL->getStructLayout(StructType::get(Ctx, Types, Packed))
                          ->getElementOffset(Types.size() - 1);
        if (InitialOff != NewOff) {
          Types.pop_back();
          Types.push_back(getPaddingArray(Ctx, InitialOff - NewOff));
          Types.push_back(EquivalentTy);
        }
      } else {
        Types.push_back(CTy);
      }
    }

    if (RequiredLowering) {
      auto InitialSize = DL->getTypeAllocSize(StructTy);
      auto NewSize = DL->getTypeAllocSize(StructType::get(Ctx, Types, Packed));
      if (InitialSize != NewSize) {
        Types.push_back(getPaddingArray(Ctx, InitialSize - NewSize));
      }
      return StructType::get(Ctx, Types, Packed);
    } else {
      return nullptr;
    }
  }

  if (auto *FunctionTy = dyn_cast<FunctionType>(Ty)) {
    assert(!FunctionTy->isVarArg() && "VarArgs not supported");

    bool RequireLowering = false;

    // Convert parameter types.
    SmallVector<Type *, 16> EquivalentParamTys;
    EquivalentParamTys.reserve(FunctionTy->getNumParams());
    for (auto *ParamTy : FunctionTy->params()) {
      auto *EquivalentParamTy = getEquivalentTypeOrSelf(ParamTy);
      EquivalentParamTys.push_back(EquivalentParamTy);
      RequireLowering |= (EquivalentParamTy != ParamTy);
    }

    // Convert return type.
    auto *ReturnTy = FunctionTy->getReturnType();
    auto *EquivalentReturnTy = getEquivalentTypeOrSelf(ReturnTy);
    RequireLowering |= (EquivalentReturnTy != ReturnTy);

    if (RequireLowering) {
      return FunctionType::get(EquivalentReturnTy, EquivalentParamTys,
                               FunctionTy->isVarArg());
    } else {
      return nullptr;
    }
  }

#ifndef NDEBUG
  dbgs() << "Unsupported type: " << *Ty << '\n';
#endif
  llvm_unreachable("Unsupported kind of Type.");
}

bool clspv::LongVectorLoweringPass::runOnGlobals(Module &M) {
  assert(GlobalVariableMap.empty());

  // Iterate over the globals, generate equivalent ones when needed. Insert the
  // new globals before the existing one in the module's list to avoid visiting
  // it again.
  for (auto &GV : M.globals()) {
    if (auto *EquivalentTy = getEquivalentType(GV.getValueType())) {
      Constant *EquivalentInitializer = nullptr;
      if (GV.hasInitializer()) {
        auto *Initializer = GV.getInitializer();
        EquivalentInitializer = cast<Constant>(visitConstant(*Initializer));
      }

      auto *EquivalentGV = new GlobalVariable(
          M, EquivalentTy, GV.isConstant(), GV.getLinkage(),
          EquivalentInitializer, "",
          /* insert before: */ &GV, GV.getThreadLocalMode(),
          GV.getAddressSpace(), GV.isExternallyInitialized());
      EquivalentGV->takeName(&GV);
      EquivalentGV->setAlignment(GV.getAlign());
      EquivalentGV->copyMetadata(&GV, /* offset: */ 0);
      EquivalentGV->copyAttributesFrom(&GV);

      LLVM_DEBUG(dbgs() << "Mapping global variable:\n\toriginal: " << GV
                        << "\n\toriginal type: " << *(GV.getValueType())
                        << "\n\treplacement: " << *EquivalentGV
                        << "\n\treplacement type: " << *EquivalentTy << "\n");

      GlobalVariableMap.insert({&GV, EquivalentGV});
    }
  }

  bool Modified = !GlobalVariableMap.empty();
  return Modified;
}

bool clspv::LongVectorLoweringPass::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return false;
  }

  // Lower the function parameters and return type if needed.
  // It is possible the function was already partially processed when visiting a
  // call site. If this is the case, a wrapper function has been created for it.
  // However, its instructions haven't been visited yet.
  Function *FunctionToVisit = convertUserDefinedFunction(F);
  if (FunctionToVisit == nullptr) {
    // The parameters don't rely on long vectors, but maybe some instructions in
    // the function body do.
    FunctionToVisit = &F;
  }

  bool Modified = (FunctionToVisit != &F);
  for (Instruction &I : instructions(FunctionToVisit)) {
    // Use the Value overload of visit to ensure cache is used.
    Modified |= (visit(static_cast<Value *>(&I)) != nullptr);
  }

  cleanDeadInstructions();

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << *FunctionToVisit << '\n');

  return Modified;
}

Value *clspv::LongVectorLoweringPass::convertBuiltinCall(
    CallInst &VectorCall, Type *EquivalentReturnTy,
    ArrayRef<Value *> EquivalentArgs) {
  Function *VectorFunction = VectorCall.getCalledFunction();
  assert(VectorFunction);

  // Use and update the FunctionMap cache.
  Function *ScalarFunction = FunctionMap[VectorFunction];
  if (ScalarFunction == nullptr) {
    // Handle both OpenCL builtin functions, available as simple declarations,
    // and LLVM intrinsics.
    auto getter = VectorFunction->isIntrinsic() ? getIntrinsicScalarVersion
                                                : getBIFScalarVersion;
    ScalarFunction = getter(*VectorFunction);
    FunctionMap[VectorFunction] = ScalarFunction;
  }
  assert(ScalarFunction);

  auto ScalarFactory = [ScalarFunction, &VectorCall](auto &B, auto Args) {
    CallInst *ScalarCall = B.CreateCall(ScalarFunction, Args);
    ScalarCall->copyIRFlags(&VectorCall);
    ScalarCall->copyMetadata(VectorCall);
    ScalarCall->setCallingConv(VectorCall.getCallingConv());
    return ScalarCall;
  };

  auto *ScalarPointerDataTy = getScalarPointerType(*VectorFunction);
  return convertVectorOperation(VectorCall, EquivalentReturnTy, EquivalentArgs,
                                ScalarFactory, ScalarPointerDataTy);
}

Value *clspv::LongVectorLoweringPass::convertAllBuiltinCall(
    CallInst &CI, Type *EquivalentReturnTy, ArrayRef<Value *> EquivalentArgs) {
  Function *Builtin = CI.getCalledFunction();
  assert(Builtin);
  const auto &Info = clspv::Builtins::Lookup(Builtin);

  switch (Info.getType()) {
  default:
    return convertBuiltinCall(CI, EquivalentReturnTy, EquivalentArgs);
  case clspv::Builtins::kShuffle: {
    auto Src = EquivalentArgs[0];
    auto Mask = EquivalentArgs[1];
    return convertBuiltinShuffle2(CI, EquivalentReturnTy, Src, Src, Mask);
  }
  case clspv::Builtins::kShuffle2: {
    auto SrcA = EquivalentArgs[0];
    auto SrcB = EquivalentArgs[1];
    auto Mask = EquivalentArgs[2];
    return convertBuiltinShuffle2(CI, EquivalentReturnTy, SrcA, SrcB, Mask);
  }
  }
}

Value *clspv::LongVectorLoweringPass::convertBuiltinShuffle2(
    CallInst &CI, Type *EquivalentReturnTy, Value *SrcA, Value *SrcB,
    Value *Mask) {
  auto MaskTy = Mask->getType();
  unsigned MaskArity;
  unsigned MaskElementSizeInBits;
  if (MaskTy->isVectorTy()) {
    MaskArity = cast<FixedVectorType>(MaskTy)->getNumElements();
    MaskElementSizeInBits =
        cast<FixedVectorType>(MaskTy)->getScalarSizeInBits();
  } else if (MaskTy->isArrayTy()) {
    MaskArity = cast<ArrayType>(MaskTy)->getArrayNumElements();
    MaskElementSizeInBits =
        cast<ArrayType>(MaskTy)->getElementType()->getScalarSizeInBits();
  } else {
    llvm_unreachable("unexpected Type for Mask in Shuffle");
  }

  IRBuilder<> B(&CI);
  IRBuilder<> BFront(&CI.getFunction()->front().front());

  bool isShuffle2 = SrcA != SrcB;

  assert(SrcA->getType() == SrcB->getType());
  auto SrcTy = SrcA->getType();
  Type *ScalarTy;
  unsigned NumElements;
  if (SrcTy->isArrayTy()) {
    auto SrcArrayTy = cast<ArrayType>(SrcTy);
    ScalarTy = SrcArrayTy->getElementType();

    // Because we cannot ExtractValue at a variable index from an array, we need
    // to copy it to something where we will be able to load from a variable
    // index
    auto *alloca = BFront.CreateAlloca(SrcTy);
    auto SrcArity = cast<ArrayType>(SrcTy)->getArrayNumElements();
    for (uint64_t i = 0; i < SrcArity; i++) {
      auto Val = B.CreateExtractValue(SrcA, i);
      auto Gep = B.CreateGEP(alloca->getAllocatedType(), alloca,
                             {B.getInt32(0), B.getInt32(i)});
      B.CreateStore(Val, Gep);
    }
    SrcA = alloca;

    if (isShuffle2) {
      // Because we cannot ExtractValue at a variable index from an array, we
      // need to copy it to something where we will be able to load from a
      // variable index
      alloca = BFront.CreateAlloca(SrcTy);
      for (uint64_t i = 0; i < SrcArity; i++) {
        auto Val = B.CreateExtractValue(SrcB, i);
        auto Gep = B.CreateGEP(alloca->getAllocatedType(), alloca,
                               {B.getInt32(0), B.getInt32(i)});
        B.CreateStore(Val, Gep);
      }
      SrcB = alloca;
    }
    NumElements = SrcTy->getArrayNumElements();
  } else {
    assert(SrcTy->isVectorTy());
    ScalarTy = SrcTy->getScalarType();
    NumElements = cast<FixedVectorType>(SrcTy)->getNumElements();
  }

  auto getScalar = [&B](Value *Vector, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateExtractElement(Vector, Index);
    } else {
      assert(Vector->getType()->isArrayTy());
      return B.CreateExtractValue(Vector, Index);
    }
  };

  auto getScalarWithIdValue = [&B, &ScalarTy](Value *Vector, Value *Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateExtractElement(Vector, Index);
    } else {
      assert(isa<AllocaInst>(Vector));
      auto gep = B.CreateGEP(cast<AllocaInst>(Vector)->getAllocatedType(),
                             Vector, {B.getInt32(0), Index});
      return (Value *)B.CreateLoad(ScalarTy, gep);
    }
  };

  auto setScalar = [&B](Value *Vector, Value *Scalar, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateInsertElement(Vector, Scalar, Index);
    } else {
      assert(Vector->getType()->isArrayTy());
      return B.CreateInsertValue(Vector, Scalar, Index);
    }
  };

  Value *Res = UndefValue::get(EquivalentReturnTy);
  for (unsigned i = 0; i < MaskArity; ++i) {

    Value *NumElementsVal = B.getIntN(MaskElementSizeInBits, NumElements);
    Value *Maski = getScalar(Mask, i);
    Value *Maskimod = B.CreateURem(Maski, NumElementsVal);

    Value *ScalarA = getScalarWithIdValue(SrcA, Maskimod);
    Value *Scalar;
    if (isShuffle2) {
      Value *ScalarB = getScalarWithIdValue(SrcB, Maskimod);

      Value *NumElementsValTimes2 =
          B.getIntN(MaskElementSizeInBits, NumElements * 2);
      Value *Maskimod2 = B.CreateURem(Maski, NumElementsValTimes2);
      Value *Cmp = B.CreateCmp(CmpInst::ICMP_SGE, Maskimod2, NumElementsVal);
      Scalar = B.CreateSelect(Cmp, ScalarB, ScalarA);
    } else {
      Scalar = ScalarA;
    }

    Res = setScalar(Res, Scalar, i);
  }
  return Res;
}

Value *clspv::LongVectorLoweringPass::convertSpirvOpBuiltinCall(
    CallInst &VectorCall, Type *EquivalentReturnTy,
    ArrayRef<Value *> EquivalentArgs) {
  if (auto *SpirvIdValue = dyn_cast<ConstantInt>(VectorCall.getOperand(0))) {
    switch (SpirvIdValue->getZExtValue()) {
    case 154: { // OpAny
      auto ReduceFactory = [](auto &Builder, auto A, auto B) {
        return Builder.CreateOr(A, B);
      };
      return convertOpAnyOrAllOperation(VectorCall, EquivalentArgs,
                                        ReduceFactory);
    }
    case 155: { // OpAll
      auto ReduceFactory = [](auto &Builder, auto A, auto B) {
        return Builder.CreateAnd(A, B);
      };
      return convertOpAnyOrAllOperation(VectorCall, EquivalentArgs,
                                        ReduceFactory);
    }
    case 63: // OpCopyMemory
      return convertOpCopyMemoryOperation(VectorCall, EquivalentArgs);
    }
  }
  return convertBuiltinCall(VectorCall, EquivalentReturnTy, EquivalentArgs);
}

Function *
clspv::LongVectorLoweringPass::convertUserDefinedFunction(Function &F) {
  auto it = FunctionMap.find(&F);
  if (it != FunctionMap.end()) {
    return it->second;
  }

  LLVM_DEBUG(dbgs() << "Handling of user defined function:\n");
  LLVM_DEBUG(dbgs() << F << '\n');

  auto *FunctionTy = F.getFunctionType();
  auto *EquivalentFunctionTy =
      cast_or_null<FunctionType>(getEquivalentType(FunctionTy));

  // If no work is needed, mark it as so for future reference and bail out.
  if (EquivalentFunctionTy == nullptr) {
    LLVM_DEBUG(dbgs() << "No need of wrapper function\n");
    FunctionMap.insert({&F, nullptr});
    return nullptr;
  }

  Function *EquivalentFunction =
      createFunctionWithMappedTypes(F, EquivalentFunctionTy, DL);

  LLVM_DEBUG(dbgs() << "Wrapper function:\n" << *EquivalentFunction << "\n");

  // The body of the new function is intentionally not visited right now because
  // we could be currently visiting a call instruction. Instead, it is being
  // visited in runOnFunction. This is to ensure the state of the lowering pass
  // remains valid.
  FunctionMap.insert({&F, EquivalentFunction});
  return EquivalentFunction;
}

CallInst *clspv::LongVectorLoweringPass::convertUserDefinedFunctionCall(
    CallInst &Call, ArrayRef<Value *> EquivalentArgs) {
  Function *Callee = Call.getCalledFunction();
  assert(Callee);

  Function *EquivalentFunction = convertUserDefinedFunction(*Callee);
  assert(EquivalentFunction);

  IRBuilder<> B(&Call);
  CallInst *NewCall = B.CreateCall(EquivalentFunction, EquivalentArgs);

  NewCall->copyIRFlags(&Call);
  NewCall->copyMetadata(Call);
  NewCall->setCallingConv(Call.getCallingConv());

  return NewCall;
}

void clspv::LongVectorLoweringPass::cleanDeadInstructions() {
  // Collect all instructions that have been replaced by another one, and remove
  // them from the function. To address dependencies, use a fixed-point
  // algorithm:
  //  1. Collect the instructions that have been replaced.
  //  2. Collect among these instructions the ones which have no uses and remove
  //     them.
  //  3. Repeat step 2 until no progress is made.

  // Select instructions that were replaced by another one.
  // Ignore constants as they are not owned by the module and therefore don't
  // need to be removed.
  using WeakInstructions = SmallVector<WeakTrackingVH, 32>;
  WeakInstructions OldInstructions;
  for (const auto &Mapping : ValueMap) {
    if (Mapping.getSecond() != nullptr) {
      if (auto *OldInstruction = dyn_cast<Instruction>(Mapping.getFirst())) {
        OldInstructions.push_back(OldInstruction);
      } else {
        assert(isa<Constant>(Mapping.getFirst()) &&
               "Only Instruction and Constant are expected in ValueMap");
      }
    }
  }

  // Erase any mapping, as they won't be valid anymore.
  ValueMap.clear();

  for (bool Progress = true; Progress;) {
    std::size_t PreviousSize = OldInstructions.size();

    // Identify instructions that are actually dead and can be removed using
    // RecursivelyDeleteTriviallyDeadInstructions.
    // Use a third buffer to capture the instructions that are still alive to
    // avoid mutating OldInstructions while iterating over it.
    WeakInstructions NextBatch;
    WeakInstructions TriviallyDeads;
    partitionInstructions(
        OldInstructions,
        [&TriviallyDeads](Instruction *DeadInstruction) {
          // Additionally, manually remove from the parent instructions with
          // possible side-effect, generally speaking, such as call or alloca
          // instructions. Those are not trivially dead.
          if (isInstructionTriviallyDead(DeadInstruction)) {
            TriviallyDeads.push_back(DeadInstruction);
          } else {
            DeadInstruction->eraseFromParent();
          }
        },
        [&NextBatch](Instruction *AliveInstruction) {
          NextBatch.push_back(AliveInstruction);
        });

    RecursivelyDeleteTriviallyDeadInstructions(TriviallyDeads);

    // Update OldInstructions for the next iteration of the fixed-point.
    OldInstructions = std::move(NextBatch);
    Progress = (OldInstructions.size() < PreviousSize);
  }

#ifndef NDEBUG
  if (!OldInstructions.empty()) {
    dbgs() << "These values were expected to be removed:\n";
    for (auto ValueHandle : OldInstructions) {
      dbgs() << '\t' << *ValueHandle << '\n';
    }
    llvm_unreachable("Not all supposedly-dead instruction were removed!");
  }
#endif
}

void clspv::LongVectorLoweringPass::cleanDeadFunctions() {
  // Take into account dependencies between functions when removing them.
  // First collect all dead functions.
  using Functions = SmallVector<Function *, 32>;
  Functions DeadFunctions;
  for (const auto &Mapping : FunctionMap) {
    if (Mapping.getSecond() != nullptr) {
      Function *F = Mapping.getFirst();
      DeadFunctions.push_back(F);
    }
  }

  // Erase any mapping, as they won't be valid anymore.
  FunctionMap.clear();

  for (bool Progress = true; Progress;) {
    std::size_t PreviousSize = DeadFunctions.size();

    Functions NextBatch;
    for (auto *F : DeadFunctions) {
      bool Dead = F->use_empty();
      if (Dead) {
        LLVM_DEBUG(dbgs() << "Removing " << F->getName()
                          << " from the module.\n");
        F->eraseFromParent();
        Progress = true;
      } else {
        NextBatch.push_back(F);
      }
    }

    DeadFunctions = std::move(NextBatch);
    Progress = (DeadFunctions.size() < PreviousSize);
  }

  assert(DeadFunctions.empty() &&
         "Not all supposedly-dead functions were removed!");
}

void clspv::LongVectorLoweringPass::cleanDeadGlobals() {
  for (auto const &Mapping : GlobalVariableMap) {
    auto *GV = Mapping.first;
    GV->removeDeadConstantUsers();
    GV->eraseFromParent();
  }
}
