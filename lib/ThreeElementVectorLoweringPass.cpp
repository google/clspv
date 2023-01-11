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
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include "BuiltinsEnum.h"
#include "Constants.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"

#include "BitcastUtils.h"
#include "Builtins.h"
#include "ThreeElementVectorLoweringPass.h"
#include "Types.h"

#include <array>
#include <functional>
#include <map>

using namespace llvm;

#define DEBUG_TYPE "ThreeElementVectorLowering"

namespace {

using PartitionCallback = std::function<void(Instruction *)>;

bool isSpirvGlobalVariable(llvm::StringRef Name) {
  return Name.startswith("__spirv_") || Name == "__push_constants";
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

/// Convert the given value @p V to a value of the given @p EquivalentTy.
///
/// @return @p V when @p V's type is @p newType.
/// @return an equivalent pointer when both @p V and @p newType are pointers.
/// @return an equivalent 4 elements vector when @p V is a 3 elements vector.
Value *convertEquivalentValue(IRBuilder<> &B, Value *V, Type *EquivalentTy) {
  Type *Ty = V->getType();
  if (Ty == EquivalentTy) {
    return V;
  }

  if (EquivalentTy->isPointerTy()) {
    assert(Ty->isPointerTy());
    return B.CreateBitCast(V, EquivalentTy);
  }

  Value *NewValue = UndefValue::get(EquivalentTy);

  if (EquivalentTy->isStructTy()) {
    StructType *StructTy = dyn_cast<StructType>(EquivalentTy);
    unsigned Arity = StructTy->getStructNumElements();
    if (Arity == 0)
      return nullptr;
    for (unsigned i = 0; i < Arity; ++i) {
      Type *ElementType = StructTy->getContainedType(i);
      Value *Element = B.CreateExtractValue(V, {i});
      Value *NewElement = convertEquivalentValue(B, Element, ElementType);
      NewValue = B.CreateInsertValue(NewValue, NewElement, {i});
    }
  } else if (EquivalentTy->isVectorTy()) {
    assert(Ty->isVectorTy());

    unsigned OldArity = dyn_cast<FixedVectorType>(Ty)->getNumElements();
    unsigned NewArity =
        dyn_cast<FixedVectorType>(EquivalentTy)->getNumElements();
    SmallVector<int, 4> Idxs;
    for (unsigned i = 0; i < NewArity; i++) {
      if (i < OldArity) {
        Idxs.push_back(i);
      } else {
        Idxs.push_back(-1);
      }
    }
    NewValue = B.CreateShuffleVector(V, Idxs);
  } else {
    return nullptr;
  }

  if (V->hasName()) {
    NewValue->takeName(V);
  }

  return NewValue;
}

/// Map the arguments of the wrapper function (which are either not vec3
/// or aggregates of scalars) to the original arguments of the user-defined
/// function (which can be vec3). Handle pointers as well.
SmallVector<Value *, 16> mapWrapperArgsToWrappeeArgs(IRBuilder<> &B,
                                                     Function &Wrappee,
                                                     Function &Wrapper) {
  SmallVector<Value *, 16> Args;

  std::size_t ArgumentCount = Wrapper.arg_size();
  Args.reserve(ArgumentCount);

  for (std::size_t i = 0; i < ArgumentCount; ++i) {
    auto *NewArg = Wrapper.getArg(i);
    auto *OldArgTy = Wrappee.getFunctionType()->getParamType(i);
    auto *EquivalentArg = convertEquivalentValue(B, NewArg, OldArgTy);
    Args.push_back(EquivalentArg);
  }

  return Args;
}

/// Create a new, equivalent function with no vec3 types.
///
/// This is achieved by creating a new function (the "wrapper") which inlines
/// the given function (the "wrappee"). Only the parameters and return types are
/// mapped. The function body still needs to be lowered.
Function *createFunctionWithMappedTypes(Function &F,
                                        FunctionType *EquivalentFunctionTy) {
  assert(!F.isVarArg() && "varargs not supported");

  auto *Wrapper = Function::Create(EquivalentFunctionTy, F.getLinkage());
  Wrapper->takeName(&F);
  Wrapper->setCallingConv(F.getCallingConv());
  Wrapper->copyAttributesFrom(&F);
  Wrapper->copyMetadata(&F, /* offset */ 0);

  for (std::size_t i = 0; i < Wrapper->arg_size(); ++i) {
    auto *WrapperArg = Wrapper->getArg(i);
    auto *FArg = F.getArg(i);

    if (FArg->hasName()) {
      WrapperArg->takeName(FArg);
    }
  }

  BasicBlock::Create(F.getContext(), "", Wrapper);
  IRBuilder<> B(&Wrapper->getEntryBlock());

  // Fill in the body of the wrapper function.
  auto WrappeeArgs = mapWrapperArgsToWrappeeArgs(B, F, *Wrapper);
  CallInst *Call = B.CreateCall(&F, WrappeeArgs);
  if (Call->getType()->isVoidTy()) {
    B.CreateRetVoid();
  } else {
    auto *EquivalentReturnTy = EquivalentFunctionTy->getReturnType();
    Value *ReturnValue = convertEquivalentValue(B, Call, EquivalentReturnTy);
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

  // Inlining a function can introduce constant expression that we could not
  // handle afterwards.
  BitcastUtils::RemoveCstExprFromFunction(Wrapper);

  return Wrapper;
}

std::string getVec4Name(const clspv::Builtins::FunctionInfo &IInfo) {
  // Copy the informations about the vector version.
  // Return type is not important for mangling.
  // Only update arguments to have vec4 instead of vec3.
  clspv::Builtins::FunctionInfo Info = IInfo;
  for (size_t i = 0; i < Info.getParameterCount(); ++i) {
    if (Info.getParameter(i).vector_size == 3) {
      Info.getParameter(i).vector_size = 4;
    }
  }
  return clspv::Builtins::GetMangledFunctionName(Info);
}

/// SIMD Builtin are builtin where the instruction uses only 1 data element
bool isBuiltinSIMD(clspv::Builtins::BuiltinType Builtin) {
  if (Builtin > clspv::Builtins::kType_Math_Start &&
      Builtin < clspv::Builtins::kType_Math_End)
    return true;
  if (Builtin > clspv::Builtins::kType_Integer_Start &&
      Builtin < clspv::Builtins::kType_Integer_End)
    return true;
  switch (Builtin) {
  default:
    return false;
  }
}

} // namespace

PreservedAnalyses
clspv::ThreeElementVectorLoweringPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (!vec3ShouldBeLowered(M))
    return PA;

  runOnGlobals(M);
  for (auto &F : M.functions()) {
    BitcastUtils::RemoveCstExprFromFunction(&F);
    runOnFunction(F);
  }

  replaceAllVec3Instances();

  cleanDeadInstructions();
  cleanDeadFunctions();
  cleanDeadGlobals();
#ifdef DEBUG
  for (auto &F : M.functions()) {
    LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
    LLVM_DEBUG(dbgs() << F << '\n');
  }
#endif
  return PA;
}

bool clspv::ThreeElementVectorLoweringPass::vec3ShouldBeLowered(Module &M) {
  switch (clspv::Option::Vec3ToVec4()) {
  case clspv::Option::Vec3ToVec4SupportClass::vec3ToVec4SupportForce:
    return true;
  case clspv::Option::Vec3ToVec4SupportClass::vec3ToVec4SupportDisable:
    return false;
  default:
    for (auto &F : M.functions()) {
      if (vec3BitcastInFunction(F))
        return true;
    }
    return false;
  }
}

bool clspv::ThreeElementVectorLoweringPass::vec3BitcastInFunction(Function &F) {
  // TODO(#816): remove this loop after final transition.
  // Explicit casts with non opaque pointers.
  for (Instruction &I : instructions(F)) {
    if (auto *Inst = dyn_cast<CastInst>(&I)) {
      auto *Type = Inst->getSrcTy();
      if (Type->isPointerTy() && !Type->isOpaquePointerTy()) {
        auto *PointeeType = Type->getNonOpaquePointerElementType();
        if (auto *VectorType = dyn_cast<FixedVectorType>(PointeeType)) {
          if (VectorType->getElementCount().getKnownMinValue() == 3)
            return true;
        }
      }
    }
  }

  // Implicit casts with opaque pointers.
  for (auto &arg : F.args()) {
    if (arg.getType()->isOpaquePointerTy()) {
      if (haveImplicitCast(&arg)) {
        return true;
      }
    }
  }

  for (Instruction &I : instructions(F)) {
    if (I.getType()->isOpaquePointerTy()) {
      if (haveImplicitCast(&I)) {
        return true;
      }
    }
  }
  return false;
}

bool clspv::ThreeElementVectorLoweringPass::haveImplicitCast(Value *Value) {
  auto InferredType =
      clspv::InferType(Value, Value->getContext(), &type_cache_);
  if (InferredType && InferredType->isVectorTy()) {
    auto *VectorType = dyn_cast<FixedVectorType>(InferredType);
    if (VectorType && VectorType->getElementCount().getKnownMinValue() == 3) {
      for (auto user : Value->users()) {
        auto userInferredType =
            clspv::InferType(user, Value->getContext(), &type_cache_);
        if (userInferredType && userInferredType != InferredType) {
          return true;
        }
      }
    }
  }
  return false;
}

Value *clspv::ThreeElementVectorLoweringPass::visit(Value *V) {
  // Already handled?
  auto it = ValueMap.find(V);
  if (it != ValueMap.end()) {
    return it->second;
  }

  if (isa<Argument>(V)) {
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

Value *clspv::ThreeElementVectorLoweringPass::visitConstant(Constant &Cst) {
  auto *EquivalentTy = getEquivalentType(Cst.getType());
  // Can happen because of the recursive call of visitConstant
  if (EquivalentTy == nullptr) {
    return dyn_cast<Value>(&Cst);
  }

  if (Cst.isZeroValue()) {
    return Constant::getNullValue(EquivalentTy);
  }

  if (isa<UndefValue>(Cst)) {
    return UndefValue::get(EquivalentTy);
  }

  if (auto *Vector = dyn_cast<ConstantDataVector>(&Cst)) {
    SmallVector<Constant *, 16> Elements;
    for (unsigned i = 0; i < Vector->getNumElements(); ++i) {
      Elements.push_back(Vector->getElementAsConstant(i));
    }
    Elements.push_back(Vector->getElementAsConstant(0));

    return ConstantVector::get(Elements);
  }

  if (auto *Vector = dyn_cast<ConstantVector>(&Cst)) {
    SmallVector<Constant *, 16> Elements;
    for (unsigned i = 0; i < Vector->getNumOperands(); ++i) {
      Elements.push_back(
          dyn_cast<Constant>(visitConstant(*Vector->getOperand(i))));
    }
    Elements.push_back(
        dyn_cast<Constant>(visitConstant(*Vector->getOperand(0))));

    return ConstantVector::get(Elements);
  }

  if (auto *Array = dyn_cast<ConstantArray>(&Cst)) {
    SmallVector<Constant *, 16> Elements;
    for (unsigned i = 0; i < Array->getNumOperands(); ++i) {
      Elements.push_back(
          dyn_cast<Constant>(visitConstant(*Array->getOperand(i))));
    }
    return ConstantArray::get(dyn_cast<ArrayType>(EquivalentTy), Elements);
  }

  if (auto *GV = dyn_cast<GlobalVariable>(&Cst)) {
    auto *EquivalentGV = GlobalVariableMap[GV];

    // Can happen due to '__spirv_' global variables not been lower to vec4
    if (EquivalentGV == nullptr)
      return GV;

    return EquivalentGV;
  }

  if (auto *CE = dyn_cast<ConstantExpr>(&Cst)) {
    switch (CE->getOpcode()) {
    case Instruction::GetElementPtr: {
      auto *GEP = cast<GEPOperator>(CE);
      if (isSpirvGlobalVariable(GEP->getPointerOperand()->getName())) {
        return CE;
      }
      auto *EquivalentSourceTy = getEquivalentType(GEP->getSourceElementType());
      auto *EquivalentPointer =
          cast<Constant>(visitOrSelf(GEP->getPointerOperand()));
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

Value *
clspv::ThreeElementVectorLoweringPass::visitNAryOperator(Instruction &I) {
  SmallVector<Value *, 16> EquivalentArgs;
  bool NothingLowered = true;
  for (auto &Operand : I.operands()) {
    Value *EquivalentOperand = visit(Operand.get());
    if (EquivalentOperand == nullptr) {
      EquivalentArgs.push_back(Operand.get());
    } else {
      NothingLowered = false;
      EquivalentArgs.push_back(EquivalentOperand);
    }
  }
  if (NothingLowered)
    return nullptr;

  IRBuilder<> B(&I);
  Value *V = B.CreateNAryOp(I.getOpcode(), EquivalentArgs);
  if (isa<Instruction>(V))
    cast<Instruction>(V)->copyIRFlags(&I);

  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitInstruction(Instruction &I) {
#ifndef NDEBUG
  dbgs() << "Instruction not handled: " << I << '\n';
#endif
  llvm_unreachable("Missing support for instruction");
}

Value *clspv::ThreeElementVectorLoweringPass::visitAllocaInst(AllocaInst &I) {
  auto *EquivalentTy = getEquivalentType(I.getAllocatedType());
  if (EquivalentTy == nullptr)
    return nullptr;

  IRBuilder<> B(&I);
  unsigned AS = I.getType()->getAddressSpace();
  auto *V = B.CreateAlloca(EquivalentTy, AS);
  V->setAlignment(I.getAlign());
  registerReplacement(I, *V);
  return V;
}

Value *
clspv::ThreeElementVectorLoweringPass::visitBinaryOperator(BinaryOperator &I) {
  return visitNAryOperator(I);
}

Value *clspv::ThreeElementVectorLoweringPass::visitCallInst(CallInst &I) {
  SmallVector<Value *, 16> EquivalentArgs;
  for (auto &ArgUse : I.args()) {
    Value *Arg = ArgUse.get();
    Value *EquivalentArg = visitOrSelf(Arg);
    EquivalentArgs.push_back(EquivalentArg);
  }

  auto *ReturnTy = I.getType();
  auto *EquivalentReturnTy = getEquivalentTypeOrSelf(ReturnTy);
// disable for opaque pointers as they will have Equivalent Arg of nullptr until
// they are inferred from other instructions.
#ifndef NDEBUG
  bool NeedHandling = false;
  NeedHandling |=
      ReturnTy->isOpaquePointerTy() || (EquivalentReturnTy != ReturnTy);
  NeedHandling |=
      !std::equal(I.arg_begin(), I.arg_end(), std::begin(EquivalentArgs),
                  [](auto const &ArgUse, Value *EquivalentArg) {
                    return !EquivalentArg->getType()->isOpaquePointerTy() &&
                           ArgUse.get() == EquivalentArg;
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
    if (isBuiltinSIMD(Info.getType())) {
      V = convertSIMDBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
    } else {
      V = convertBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
    }
  } else if (SpirvOpBuiltin && F->isDeclaration()) {
    V = convertSpirvOpBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
  } else {
    V = convertUserDefinedFunctionCall(I, EquivalentArgs);
  }

  if (V == nullptr)
    return nullptr;

  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitCastInst(CastInst &I) {
  auto *OriginalValue = I.getOperand(0);
  auto *EquivalentValue = visitOrSelf(OriginalValue);
  auto *OriginalDestTy = I.getDestTy();
  auto *EquivalentDestTy = getEquivalentTypeOrSelf(OriginalDestTy);

  if (EquivalentValue == OriginalValue &&
      EquivalentDestTy == OriginalDestTy) // Nothing Lowered
    return nullptr;

  IRBuilder<> B(&I);
  Value *V = B.CreateCast(I.getOpcode(), EquivalentValue, EquivalentDestTy,
                          I.getName());
  if (isa<Instruction>(V))
    cast<Instruction>(V)->copyIRFlags(&I);

  assert(V);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitCmpInst(CmpInst &I) {
  std::array<Value *, 2> EquivalentArgs{{
      visitOrSelf(I.getOperand(0)),
      visitOrSelf(I.getOperand(1)),
  }};

  if (EquivalentArgs[0] == I.getOperand(0) &&
      EquivalentArgs[1] == I.getOperand(1)) // Nothing lowered
    return nullptr;

  IRBuilder<> B(&I);
  Value *V = nullptr;
  if (I.isIntPredicate()) {
    V = B.CreateICmp(I.getPredicate(), EquivalentArgs[0], EquivalentArgs[1]);
  } else {
    V = B.CreateFCmp(I.getPredicate(), EquivalentArgs[0], EquivalentArgs[1]);
  }
  if (isa<Instruction>(V))
    cast<Instruction>(V)->copyIRFlags(&I);

  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitExtractElementInst(
    ExtractElementInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  if (EquivalentValue == nullptr)
    return nullptr;

  Value *Index = I.getOperand(1);

  assert(EquivalentValue->getType()->isVectorTy());

  IRBuilder<> B(&I);
  Value *V = B.CreateExtractElement(EquivalentValue, Index);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitExtractValueInst(
    ExtractValueInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  if (EquivalentValue == nullptr)
    return nullptr;

  auto Indices = I.getIndices();

  IRBuilder<> B(&I);
  Value *V = B.CreateExtractValue(EquivalentValue, Indices);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitGetElementPtrInst(
    GetElementPtrInst &I) {
  // do not lower GEP of spirv global variables as we do not lower them to vec4
  if (isSpirvGlobalVariable(I.getPointerOperand()->getName())) {
    return &I;
  }
  Value *EquivalentPointer = visitOrSelf(I.getPointerOperand());

  bool isOpaque = I.getPointerOperand()->getType()->isOpaquePointerTy();

  Type *EquivalentType = isOpaque ? getEquivalentType(I.getSourceElementType())
                                  : EquivalentPointer->getType()
                                        ->getScalarType()
                                        ->getNonOpaquePointerElementType();

  if (EquivalentType == nullptr ||
      (!isOpaque && EquivalentPointer == I.getPointerOperand()))
    return nullptr;

  IRBuilder<> B(&I);
  SmallVector<Value *, 4> Indices(I.indices());
  auto *V = B.CreateInBoundsGEP(EquivalentType, EquivalentPointer, Indices);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitInsertElementInst(
    InsertElementInst &I) {
  Value *EquivalentValue = visit(I.getOperand(0));
  if (EquivalentValue == nullptr)
    return nullptr;

  Value *ScalarElement = I.getOperand(1);
  assert(ScalarElement->getType()->isIntegerTy() ||
         ScalarElement->getType()->isFloatingPointTy());

  ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2));
  assert(CI && "Dynamic indices not supported yet");
  unsigned Index = CI->getZExtValue();

  assert(EquivalentValue->getType()->isVectorTy());

  IRBuilder<> B(&I);
  Value *V = B.CreateInsertElement(EquivalentValue, ScalarElement, Index);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitInsertValueInst(
    InsertValueInst &I) {
  Value *EquivalentAggregate = visitOrSelf(I.getOperand(0));
  Value *EquivalentInsertValue = visitOrSelf(I.getOperand(1));

  if (EquivalentAggregate == I.getOperand(0) &&
      EquivalentInsertValue == I.getOperand(1)) // Nothing lowered
    return nullptr;

  auto Idxs = I.getIndices();

  IRBuilder<> B(&I);
  Value *V =
      B.CreateInsertValue(EquivalentAggregate, EquivalentInsertValue, Idxs);
  registerReplacement(I, *V);

  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitLoadInst(LoadInst &I) {
  // do not lower load of spirv global variables as we do not lower them to vec4
  if (isSpirvGlobalVariable(I.getPointerOperand()->getName())) {
    return &I;
  }
  Value *EquivalentPointer = visitOrSelf(I.getPointerOperand());

  bool isOpaque = I.getPointerOperand()->getType()->isOpaquePointerTy();

  Type *EquivalentType = isOpaque ? getEquivalentType(I.getType())
                                  : EquivalentPointer->getType()
                                        ->getScalarType()
                                        ->getNonOpaquePointerElementType();

  if (EquivalentType == nullptr ||
      (!isOpaque && EquivalentPointer == I.getPointerOperand()))
    return nullptr;

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedLoad(EquivalentType, EquivalentPointer, I.getAlign(),
                                I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitPHINode(PHINode &I) {
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

Value *clspv::ThreeElementVectorLoweringPass::visitSelectInst(SelectInst &I) {
  auto *EquivalentCondition = visitOrSelf(I.getCondition());
  auto *EquivalentTrueValue = visitOrSelf(I.getTrueValue());
  auto *EquivalentFalseValue = visitOrSelf(I.getFalseValue());

  IRBuilder<> B(&I);
  Value *V = B.CreateSelect(EquivalentCondition, EquivalentTrueValue,
                            EquivalentFalseValue);

  if (isa<Instruction>(V))
    cast<Instruction>(V)->copyIRFlags(&I);
  registerReplacement(I, *V);
  return V;
}

Value *clspv::ThreeElementVectorLoweringPass::visitShuffleVectorInst(
    ShuffleVectorInst &I) {
  assert(isa<FixedVectorType>(I.getType()) &&
         "shufflevector on scalable vectors is not supported.");

  auto *EquivalentLHS = visitOrSelf(I.getOperand(0));
  auto *EquivalentRHS = visitOrSelf(I.getOperand(1));
  auto *EquivalentType = getEquivalentTypeOrSelf(I.getType());

  IRBuilder<> B(&I);

  // Extract the scalar at the given index using the appropriate method.
  auto getScalar = [&B](Value *Vector, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateExtractElement(Vector, Index);
    } else {
      assert(Vector->getType()->isStructTy());
      return B.CreateExtractValue(Vector, Index);
    }
  };

  auto setScalar = [&B](Value *Vector, Value *Scalar, unsigned Index) {
    if (Vector->getType()->isVectorTy()) {
      return B.CreateInsertElement(Vector, Scalar, Index);
    } else {
      assert(Vector->getType()->isStructTy());
      return B.CreateInsertValue(Vector, Scalar, Index);
    }
  };

  unsigned Arity = I.getShuffleMask().size();
  auto *ScalarTy = I.getType()->getElementType();

  auto *LHSTy = cast<VectorType>(I.getOperand(0)->getType());
  assert(!LHSTy->getElementCount().isScalable() && "broken assumption");
  unsigned LHSArity = LHSTy->getElementCount().getFixedValue();

  // Construct the equivalent shuffled vector, as a struct or a vector.
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

Value *clspv::ThreeElementVectorLoweringPass::visitStoreInst(StoreInst &I) {
  Value *EquivalentValue = visit(I.getValueOperand());
  Value *EquivalentPointer = nullptr;

  if (I.getPointerOperand()->getType()->isOpaquePointerTy()) {
    EquivalentPointer = I.getPointerOperand();
  } else {
    EquivalentPointer = visit(I.getPointerOperand());
  }

  if (EquivalentValue == nullptr || EquivalentPointer == nullptr)
    return nullptr;

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedStore(EquivalentValue, EquivalentPointer,
                                 I.getAlign(), I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *
clspv::ThreeElementVectorLoweringPass::visitUnaryOperator(UnaryOperator &I) {
  return visitNAryOperator(I);
}

bool clspv::ThreeElementVectorLoweringPass::handlingRequired(User &U) {
  auto UserTy = clspv::InferType(&U, U.getContext(), &type_cache_);
  if (UserTy && getEquivalentType(UserTy) != nullptr) {
    return true;
  }

  for (auto &Operand : U.operands()) {
    auto *OperandTy = Operand.get()->getType();
    if (OperandTy->isOpaquePointerTy()) {
      OperandTy = clspv::InferType(Operand, U.getContext(), &type_cache_);
    }
    if (OperandTy && getEquivalentType(OperandTy) != nullptr) {
      return true;
    }
  }

  return false;
}

void clspv::ThreeElementVectorLoweringPass::registerReplacement(Value &U,
                                                                Value &V) {
  assert(ValueMap.count(&U) == 0 && "Value already registered");
  ValueMap.insert({&U, &V});
}

void clspv::ThreeElementVectorLoweringPass::replaceAllVec3Instances() {
  for (auto mapping : ValueMap) {
    auto U = mapping.first;
    auto V = mapping.second;
    LLVM_DEBUG(dbgs() << "Replacement for " << *U << ": " << *V << '\n');
    if (U->getType() == V->getType()) {
      LLVM_DEBUG(dbgs() << "\tAnd replace its usages.\n");
      U->replaceAllUsesWith(V);
    }

    if (U->hasName()) {
      V->takeName(U);
    }

    auto *I = dyn_cast<Instruction>(U);
    auto *J = dyn_cast<Instruction>(V);
    if (I && J) {
      J->copyMetadata(*I);
    }
  }
}

Type *clspv::ThreeElementVectorLoweringPass::getEquivalentType(Type *Ty) {
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

Type *clspv::ThreeElementVectorLoweringPass::getEquivalentTypeImpl(Type *Ty) {
  if (Ty->isIntegerTy() || Ty->isFloatingPointTy() || Ty->isVoidTy() ||
      Ty->isLabelTy() || Ty->isMetadataTy() || Ty->isOpaquePointerTy()) {
    // No lowering required.
    return nullptr;
  }

  if (auto *VectorTy = dyn_cast<VectorType>(Ty)) {
    unsigned Arity = VectorTy->getElementCount().getKnownMinValue();
    bool RequireLowering = (Arity == 3);

    if (RequireLowering) {
      assert(!VectorTy->getElementCount().isScalable() &&
             "Unsupported scalable vector");

      // This assumes that the element type of the vector is a primitive scalar.
      // That is, no vectors of pointers for example.
      Type *ScalarTy = VectorTy->getElementType();
      assert((ScalarTy->isFloatingPointTy() || ScalarTy->isIntegerTy()) &&
             "Unsupported scalar type");

      return VectorType::get(ScalarTy, 4, false);
    }

    return nullptr;
  }

  // TODO(#816): remove condition after final transition.
  if (auto *PointerTy = dyn_cast<PointerType>(Ty)) {
    if (auto *ElementTy =
            getEquivalentType(PointerTy->getNonOpaquePointerElementType())) {
      return ElementTy->getPointerTo(PointerTy->getAddressSpace());
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
    if (StructTy->isPacked())
      return nullptr;
    unsigned Arity = StructTy->getStructNumElements();
    if (Arity == 0)
      return nullptr;
    LLVMContext &Ctx = StructTy->getContainedType(0)->getContext();
    SmallVector<Type *, 16> Types;
    bool RequiredLowering = false;
    for (unsigned i = 0; i < Arity; ++i) {
      Type *CTy = StructTy->getContainedType(i);
      auto *EquivalentTy = getEquivalentType(CTy);
      if (EquivalentTy != nullptr) {
        Types.push_back(EquivalentTy);
        RequiredLowering = true;
      } else {
        Types.push_back(CTy);
      }
    }

    if (RequiredLowering) {
      return StructType::get(Ctx, Types, false);
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

bool clspv::ThreeElementVectorLoweringPass::runOnGlobals(Module &M) {
  assert(GlobalVariableMap.empty());

  // Iterate over the globals, generate equivalent ones when needed. Insert the
  // new globals before the existing one in the module's list to avoid visiting
  // it again.
  for (auto &GV : M.globals()) {
    if (isSpirvGlobalVariable(GV.getName())) {
      continue;
    }
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

      if (GV.getType() == EquivalentGV->getType()) {
        GV.replaceAllUsesWith(EquivalentGV);
      }

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

bool clspv::ThreeElementVectorLoweringPass::runOnFunction(Function &F) {
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

  return Modified;
}

Value *clspv::ThreeElementVectorLoweringPass::convertOpCopyMemoryOperation(
    CallInst &VectorCall, ArrayRef<Value *> EquivalentArgs) {
  auto *DstOperand = EquivalentArgs[1];
  auto *SrcOperand = EquivalentArgs[2];

#ifdef DEBUG
  if (DstOperand->getType()->isOpaquePointerTy()) {
    auto ptrTy =
        clspv::InferType(DstOperand, VectorCall.getContext(), &type_cache_);
    assert(ptrTy->isVectorTy());
    auto *VectorType = cast<FixedVectorType>(ptrTy);
    assert(VectorType->getElementCount().getKnownMinValue() == 4);
  } else {
    assert(
        DstOperand->getType()->getNonOpaquePointerElementType()->isVectorTy());
    assert(cast<VectorType>(
               DstOperand->getType()->getNonOpaquePointerElementType())
               ->getElementCount()
               .getKnownMinValue() == 4);
  }
#endif
  IRBuilder<> B(&VectorCall);
  Value *ReturnValue = nullptr;

  // for each element
  for (unsigned eachElem = 0; eachElem < 3; eachElem++) {
    auto SrcOperandTy = SrcOperand->getType();
    auto DstOperandTy = DstOperand->getType();
    if (SrcOperandTy->isOpaquePointerTy() ||
        DstOperandTy->isOpaquePointerTy()) {
      SrcOperandTy =
          clspv::InferType(SrcOperand, VectorCall.getContext(), &type_cache_);
      DstOperandTy =
          clspv::InferType(DstOperand, VectorCall.getContext(), &type_cache_);
      auto *SrcGEP = B.CreateGEP(SrcOperandTy, SrcOperand,
                                 {B.getInt32(0), B.getInt32(eachElem)});
      auto *Val = B.CreateLoad(SrcOperandTy->getScalarType(), SrcGEP);
      auto *DstGEP = B.CreateGEP(DstOperandTy, DstOperand,
                                 {B.getInt32(0), B.getInt32(eachElem)});
      ReturnValue = B.CreateStore(Val, DstGEP);
    } else {
      auto *SrcGEP = B.CreateGEP(
          SrcOperandTy->getScalarType()->getNonOpaquePointerElementType(),
          SrcOperand, {B.getInt32(0), B.getInt32(eachElem)});
      auto *Val = B.CreateLoad(
          SrcGEP->getType()->getNonOpaquePointerElementType(), SrcGEP);
      auto *DstGEP = B.CreateGEP(
          DstOperandTy->getScalarType()->getNonOpaquePointerElementType(),
          DstOperand, {B.getInt32(0), B.getInt32(eachElem)});
      ReturnValue = B.CreateStore(Val, DstGEP);
    }
  }

  return ReturnValue;
}

Value *clspv::ThreeElementVectorLoweringPass::convertBuiltinCall(
    CallInst &VectorCall, Type *EquivalentReturnTy,
    ArrayRef<Value *> EquivalentArgs) {
  Function *VectorFunction = VectorCall.getCalledFunction();
  assert(VectorFunction);

  IRBuilder<> B(&VectorCall);

  SmallVector<Value *, 16> Args;
  for (Value *Arg : EquivalentArgs) {
    if (Arg->getType()->isVectorTy()) {
      Args.push_back(B.CreateShuffleVector(Arg, {0, 1, 2}));
    } else {
      Args.push_back(Arg);
    }
  }

  CallInst *NewVectorCall = B.CreateCall(VectorFunction, Args);
  NewVectorCall->copyIRFlags(&VectorCall);
  NewVectorCall->copyMetadata(VectorCall);
  NewVectorCall->setCallingConv(VectorCall.getCallingConv());

  Type *RetTy = VectorFunction->getReturnType();

  if (RetTy->isVectorTy()) {
    Value *NewRet = B.CreateShuffleVector(NewVectorCall, {0, 1, 2, -1});

    return NewRet;
  }

  return dyn_cast<Value>(NewVectorCall);
}

Value *clspv::ThreeElementVectorLoweringPass::convertSIMDBuiltinCall(
    CallInst &VectorCall, Type *EquivalentReturnTy,
    ArrayRef<Value *> EquivalentArgs) {
  Function *InitialFunction = VectorCall.getCalledFunction();

  std::string FunctionName =
      getVec4Name(clspv::Builtins::Lookup(InitialFunction));

  auto *M = InitialFunction->getParent();

  SmallVector<Type *, 4> ParamTys;
  for (Value *Arg : EquivalentArgs) {
    ParamTys.push_back(Arg->getType());
  }

  Function *Fct =
      Function::Create(FunctionType::get(EquivalentReturnTy, ParamTys, false),
                       InitialFunction->getLinkage(), FunctionName);

  Fct->setCallingConv(InitialFunction->getCallingConv());
  Fct->copyAttributesFrom(InitialFunction);

  M->getFunctionList().push_front(Fct);

  IRBuilder<> B(&VectorCall);

  CallInst *Call = B.CreateCall(Fct, EquivalentArgs);
  Call->copyIRFlags(&VectorCall);
  Call->copyMetadata(VectorCall);
  Call->setCallingConv(VectorCall.getCallingConv());

  return Call;
}

Value *clspv::ThreeElementVectorLoweringPass::convertSpirvOpBuiltinCall(
    CallInst &VectorCall, Type *EquivalentReturnTy,
    ArrayRef<Value *> EquivalentArgs) {
  if (auto *SpirvIdValue = dyn_cast<ConstantInt>(VectorCall.getOperand(0))) {
    switch (SpirvIdValue->getZExtValue()) {
    case 63: // OpCopyMemory
      return convertOpCopyMemoryOperation(VectorCall, EquivalentArgs);
    case 151: // OpUMulExtended
    case 152: // OpSMulExtended
    case 156: // OpIsNan
    case 157: // OpIsInf
      return convertSIMDBuiltinCall(VectorCall, EquivalentReturnTy,
                                    EquivalentArgs);
    }
  }
  return convertBuiltinCall(VectorCall, EquivalentReturnTy, EquivalentArgs);
}

Function *
clspv::ThreeElementVectorLoweringPass::convertUserDefinedFunction(Function &F) {
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
      createFunctionWithMappedTypes(F, EquivalentFunctionTy);

  LLVM_DEBUG(dbgs() << "Wrapper function:\n" << *EquivalentFunction << "\n");

  // The body of the new function is intentionally not visited right now because
  // we could be currently visiting a call instruction. Instead, it is being
  // visited in runOnFunction. This is to ensure the state of the lowering pass
  // remains valid.
  FunctionMap.insert({&F, EquivalentFunction});
  return EquivalentFunction;
}

CallInst *clspv::ThreeElementVectorLoweringPass::convertUserDefinedFunctionCall(
    CallInst &Call, ArrayRef<Value *> EquivalentArgs) {
  Function *Callee = Call.getCalledFunction();
  assert(Callee);

  Function *EquivalentFunction = convertUserDefinedFunction(*Callee);
  if (EquivalentFunction == nullptr) {
    return nullptr;
  }

  IRBuilder<> B(&Call);
  CallInst *NewCall = B.CreateCall(EquivalentFunction, EquivalentArgs);

  NewCall->copyIRFlags(&Call);
  NewCall->copyMetadata(Call);
  NewCall->setCallingConv(Call.getCallingConv());

  return NewCall;
}

void clspv::ThreeElementVectorLoweringPass::cleanDeadInstructions() {
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

void clspv::ThreeElementVectorLoweringPass::cleanDeadFunctions() {
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

void clspv::ThreeElementVectorLoweringPass::cleanDeadGlobals() {
  for (auto const &Mapping : GlobalVariableMap) {
    auto *GV = Mapping.first;
    GV->eraseFromParent();
  }
}
