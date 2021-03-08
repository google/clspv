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

#include "clspv/Passes.h"

#include "Builtins.h"
#include "Passes.h"

#include <array>
#include <functional>

using namespace llvm;

#define DEBUG_TYPE "LongVectorLowering"

namespace {

class LongVectorLoweringPass final
    : public ModulePass,
      public InstVisitor<LongVectorLoweringPass, Value *> {
public:
  static char ID;

public:
  LongVectorLoweringPass() : ModulePass(ID) {}

  /// Lower the content of the given module @p M.
  bool runOnModule(Module &M) override;

private:
  // Implementation details for InstVisitor.

  using Visitor = InstVisitor<LongVectorLoweringPass, Value *>;
  using Visitor::visit;
  friend Visitor;

  /// Higher-level dispatcher. This is not provided by InstVisitor.
  /// Returns nullptr if no lowering is required.
  Value *visit(Value *V);

  /// Visit Constant. This is not provided by InstVisitor.
  Value *visitConstant(Constant &Cst);

  /// Visit Unary or Binary Operator. This is not provided by InstVisitor.
  Value *visitNAryOperator(Instruction &I);

  /// InstVisitor impl, general "catch-all" function.
  Value *visitInstruction(Instruction &I);

  // InstVisitor impl, specific cases.
  Value *visitAllocaInst(AllocaInst &I);
  Value *visitBinaryOperator(BinaryOperator &I);
  Value *visitCallInst(CallInst &I);
  Value *visitCastInst(CastInst &I);
  Value *visitCmpInst(CmpInst &I);
  Value *visitExtractElementInst(ExtractElementInst &I);
  Value *visitGetElementPtrInst(GetElementPtrInst &I);
  Value *visitInsertElementInst(InsertElementInst &I);
  Value *visitLoadInst(LoadInst &I);
  Value *visitPHINode(PHINode &I);
  Value *visitSelectInst(SelectInst &I);
  Value *visitShuffleVectorInst(ShuffleVectorInst &I);
  Value *visitStoreInst(StoreInst &I);
  Value *visitUnaryOperator(UnaryOperator &I);

private:
  // Helpers for lowering values.

  /// Return true if the given @p U needs to be lowered.
  ///
  /// This only looks at the types involved, not the opcodes or anything else.
  bool handlingRequired(User &U);

  /// Return the lowered version of @p U or @p U itself when no lowering is
  /// required.
  Value *visitOrSelf(Value *U) {
    auto *V = visit(U);
    return V ? V : U;
  }

  /// Register the replacement of @p U with @p V.
  ///
  /// If @p U and @p V have the same type, replace the relevant usages as well
  /// to ensure the rest of the program is using the new instructions.
  void registerReplacement(Value &U, Value &V);

private:
  // Helpers for lowering types.

  /// Get a struct equivalent for this type, if it uses a long vector.
  /// Returns nullptr if no lowering is required.
  Type *getEquivalentType(Type *Ty);

  /// Implementation details of getEquivalentType.
  Type *getEquivalentTypeImpl(Type *Ty);

  /// Return the equivalent type for @p Ty or @p Ty if no lowering is needed.
  Type *getEquivalentTypeOrSelf(Type *Ty) {
    auto *EquivalentTy = getEquivalentType(Ty);
    return EquivalentTy ? EquivalentTy : Ty;
  }

private:
  // Hight-level implementation details of runOnModule.

  /// Lower all global variables in the module.
  bool runOnGlobals(Module &M);

  /// Lower the given function.
  bool runOnFunction(Function &F);

  /// Map the call @p CI to an OpenCL builtin function or an LLVM intrinsic to
  /// calls to its scalar version.
  Value *convertBuiltinCall(CallInst &CI, Type *EquivalentReturnTy,
                            ArrayRef<Value *> EquivalentArgs);

  /// Create an alternative version of @p F that doesn't have long vectors as
  /// parameter or return types.
  /// Returns nullptr if no lowering is required.
  Function *convertUserDefinedFunction(Function &F);

  /// Create (and insert) a call to the equivalent user-defined function.
  CallInst *convertUserDefinedFunctionCall(CallInst &CI,
                                           ArrayRef<Value *> EquivalentArgs);

  /// Clears the dead instructions and others that might be rendered dead
  /// by their removal.
  void cleanDeadInstructions();

  /// Remove all long-vector functions that were lowered.
  void cleanDeadFunctions();

  /// Remove all long-vector globals that were lowered.
  void cleanDeadGlobals();

private:
  /// A map between long-vector types and their equivalent representation.
  DenseMap<Type *, Type *> TypeMap;

  /// A map between original values and their replacement.
  ///
  /// The content of this mapping is valid only for the function being visited
  /// at a given time. The keys in this mapping should be removed from the
  /// function once all instructions in the current function have been visited
  /// and transformed. Instructions are not removed from the function as they
  /// are visited because this would invalidate iterators.
  DenseMap<Value *, Value *> ValueMap;

  /// A map between functions and their replacement. This includes OpenCL
  /// builtin declarations.
  ///
  /// The keys in this mapping should be deleted when finishing processing the
  /// module.
  DenseMap<Function *, Function *> FunctionMap;

  /// A map between global variables and their replacement.
  ///
  /// The map is filled before any functions are visited, yet the original
  /// globals are not removed from the module. Their removal is deferred once
  /// all functions have been visited.
  DenseMap<GlobalVariable *, GlobalVariable *> GlobalVariableMap;
};

char LongVectorLoweringPass::ID = 0;

using PartitionCallback = std::function<void(Instruction *)>;

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

  case Intrinsic::ceil:
  case Intrinsic::copysign:
  case Intrinsic::cos:
  case Intrinsic::exp:
  case Intrinsic::fabs:
  case Intrinsic::fmuladd:
  case Intrinsic::log:
  case Intrinsic::pow:
  case Intrinsic::sin: {
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
  case clspv::Builtins::kAcosh:
  case clspv::Builtins::kAcos:
  case clspv::Builtins::kAcospi:
  case clspv::Builtins::kAsin:
  case clspv::Builtins::kAsinh:
  case clspv::Builtins::kAsinpi:
  case clspv::Builtins::kAtanh:
  case clspv::Builtins::kCeil:
  case clspv::Builtins::kCos:
  case clspv::Builtins::kCosh:
  case clspv::Builtins::kCospi:
  case clspv::Builtins::kExp:
  case clspv::Builtins::kExp2:
  case clspv::Builtins::kExpm1:
  case clspv::Builtins::kFabs:
  case clspv::Builtins::kFloor:
  case clspv::Builtins::kFma:
  case clspv::Builtins::kFmax:
  case clspv::Builtins::kFmin:
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
  case clspv::Builtins::kPow:
  case clspv::Builtins::kPowr:
  case clspv::Builtins::kRint:
  case clspv::Builtins::kSin:
  case clspv::Builtins::kSinh:
  case clspv::Builtins::kSinpi:
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
        auto *PointeeTy = ParamTy->getPointerElementType();
        assert(PointeeTy->isVectorTy() && "Unsupported kind of pointer type.");
        ScalarParamTy = PointerType::get(PointeeTy->getScalarType(),
                                         ParamTy->getPointerAddressSpace());
      } else {
        assert((ParamTy->isVectorTy() || ParamTy->isFloatingPointTy() ||
                ParamTy->isIntegerTy()) &&
               "Unsupported kind of parameter type.");
        ScalarParamTy = ParamTy->getScalarType();
      }

      assert(ScalarParamTy);
      ScalarParamTys.push_back(ScalarParamTy);
    }

    assert(Builtin.getReturnType()->isVectorTy());
    Type *ReturnTy = Builtin.getReturnType()->getScalarType();

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
Value *convertEquivalentValue(IRBuilder<> &B, Value *V, Type *EquivalentTy) {
  if (V->getType() == EquivalentTy) {
    return V;
  }

  if (EquivalentTy->isPointerTy()) {
    assert(V->getType()->isPointerTy());
    return B.CreateBitCast(V, EquivalentTy);
  }

  assert(EquivalentTy->isVectorTy() || EquivalentTy->isStructTy());

  Value *NewValue = UndefValue::get(EquivalentTy);

  if (EquivalentTy->isVectorTy()) {
    assert(V->getType()->isStructTy());

    unsigned Arity = V->getType()->getNumContainedTypes();
    for (unsigned i = 0; i < Arity; ++i) {
      Value *Scalar = B.CreateExtractValue(V, i);
      NewValue = B.CreateInsertElement(NewValue, Scalar, i);
    }
  } else {
    assert(EquivalentTy->isStructTy());
    assert(V->getType()->isVectorTy());

    unsigned Arity = EquivalentTy->getNumContainedTypes();
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
                              ScalarOperationFactory ScalarOperation) {
  assert(EquivalentReturnTy != nullptr);
  assert(EquivalentReturnTy->isStructTy());

  Value *ReturnValue = UndefValue::get(EquivalentReturnTy);
  unsigned Arity = EquivalentReturnTy->getNumContainedTypes();

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
        assert(ArgTy->getPointerElementType()->isStructTy() &&
               "Unsupported kind of pointer type.");
        Args[j] = B.CreateInBoundsGEP(EquivalentArgs[j],
                                      {Zero, ConstantInt::get(IntTy, i)});
      } else if (ArgTy->isStructTy()) {
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

    ReturnValue = B.CreateInsertValue(ReturnValue, Scalar, i);
  }

  return ReturnValue;
}

/// Map the arguments of the wrapper function (which are either not long-vectors
/// or aggregates of scalars) to the original arguments of the user-defined
/// function (which can be long-vectors). Handle pointers as well.
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

/// Create a new, equivalent function with no long-vector types.
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

  return Wrapper;
}

bool LongVectorLoweringPass::runOnModule(Module &M) {
  bool Modified = runOnGlobals(M);

  for (auto &F : M.functions()) {
    Modified |= runOnFunction(F);
  }

  cleanDeadFunctions();
  cleanDeadGlobals();

  return Modified;
}

Value *LongVectorLoweringPass::visit(Value *V) {
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

Value *LongVectorLoweringPass::visitConstant(Constant &Cst) {
  auto *EquivalentTy = getEquivalentType(Cst.getType());
  assert(EquivalentTy && "Nothing to lower.");

  if (Cst.isZeroValue()) {
    return Constant::getNullValue(EquivalentTy);
  }

  if (isa<UndefValue>(Cst)) {
    return UndefValue::get(EquivalentTy);
  }

  if (auto *Vector = dyn_cast<ConstantDataVector>(&Cst)) {
    assert(isa<StructType>(EquivalentTy));

    SmallVector<Constant *, 16> Scalars;
    for (unsigned i = 0; i < Vector->getNumElements(); ++i) {
      Scalars.push_back(Vector->getElementAsConstant(i));
    }

    return ConstantStruct::get(cast<StructType>(EquivalentTy), Scalars);
  }

  if (auto *GV = dyn_cast<GlobalVariable>(&Cst)) {
    auto *EquivalentGV = GlobalVariableMap[GV];
    assert(EquivalentGV &&
           "Global variable should have been already processed.");
    return EquivalentGV;
  }

  if (auto *CE = dyn_cast<ConstantExpr>(&Cst)) {
    switch (CE->getOpcode()) {
    case Instruction::GetElementPtr: {
      auto *GEP = cast<GEPOperator>(CE);
      auto *EquivalentSourceTy = getEquivalentType(GEP->getSourceElementType());
      auto *EquivalentPointer = cast<Constant>(visit(GEP->getPointerOperand()));
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

Value *LongVectorLoweringPass::visitNAryOperator(Instruction &I) {
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

Value *LongVectorLoweringPass::visitInstruction(Instruction &I) {
#ifndef NDEBUG
  dbgs() << "Instruction not handled: " << I << '\n';
#endif
  llvm_unreachable("Missing support for instruction");
}

Value *LongVectorLoweringPass::visitAllocaInst(AllocaInst &I) {
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

Value *LongVectorLoweringPass::visitBinaryOperator(BinaryOperator &I) {
  return visitNAryOperator(I);
}

Value *LongVectorLoweringPass::visitCallInst(CallInst &I) {
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
  bool OpenCLBuiltin = (Info.getType() != clspv::Builtins::kBuiltinNone);
  bool Builtin = (OpenCLBuiltin || F->isIntrinsic());

  Value *V = nullptr;
  if (Builtin && F->isDeclaration()) {
    V = convertBuiltinCall(I, EquivalentReturnTy, EquivalentArgs);
  } else {
    V = convertUserDefinedFunctionCall(I, EquivalentArgs);
  }

  registerReplacement(I, *V);
  return V;
}

Value *LongVectorLoweringPass::visitCastInst(CastInst &I) {
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
      break;
    }
    LLVM_FALLTHROUGH;
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
    assert(EquivalentDestTy->isStructTy());
    Type *ScalarTy = EquivalentDestTy->getStructElementType(0);
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

Value *LongVectorLoweringPass::visitCmpInst(CmpInst &I) {
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

Value *LongVectorLoweringPass::visitExtractElementInst(ExtractElementInst &I) {
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

Value *LongVectorLoweringPass::visitGetElementPtrInst(GetElementPtrInst &I) {
  // GEP can be tricky so we implement support only for the available test
  // cases.
#ifndef NDEBUG
  {
    assert(I.isInBounds() && "Need test case to implement GEP not 'inbound'.");

    auto *ResultTy = I.getResultElementType();
    assert(ResultTy->isVectorTy() &&
           "Need test case to implement GEP with non-vector result type.");

    auto *ScalarTy = ResultTy->getScalarType();
    assert((ScalarTy->isIntegerTy() || ScalarTy->isFloatingPointTy()) &&
           "Expected a vector of integer or floating-point elements.");

    auto OperandTy = I.getPointerOperandType();
    assert(OperandTy->isPointerTy() &&
           "Need test case to implement GEP for non-pointer operand.");
    assert(!OperandTy->isVectorTy() &&
           "Need test case to implement GEP for vector of pointers.");
  }
#endif

  auto *EquivalentPointer = visit(I.getPointerOperand());
  assert(EquivalentPointer && "pointer not lowered");

  IRBuilder<> B(&I);
  SmallVector<Value *, 4> Indices(I.indices());
  auto *V = B.CreateInBoundsGEP(EquivalentPointer, Indices);
  registerReplacement(I, *V);
  return V;
}

Value *LongVectorLoweringPass::visitInsertElementInst(InsertElementInst &I) {
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

Value *LongVectorLoweringPass::visitLoadInst(LoadInst &I) {
  Value *EquivalentPointer = visit(I.getPointerOperand());
  assert(EquivalentPointer && "pointer not lowered");
  Type *EquivalentTy = getEquivalentType(I.getType());
  assert(EquivalentTy && "type not lowered");

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedLoad(EquivalentTy, EquivalentPointer, I.getAlign(),
                                I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *LongVectorLoweringPass::visitPHINode(PHINode &I) {
  // TODO Handle PHIs.
  //
  // PHIs are tricky because they require their incoming values
  // to be handled first, which may not have been defined yet.
  // We can't explicitly visit them because a PHI may depend on itself,
  // leading to infinite loops. Defer until we have a test case.
  //
  // TODO Add PHI instruction with fast math flag to fastmathflags.ll test.
  llvm_unreachable("PHI node not yet supported");
}

Value *LongVectorLoweringPass::visitSelectInst(SelectInst &I) {
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

Value *LongVectorLoweringPass::visitShuffleVectorInst(ShuffleVectorInst &I) {
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
      assert(Vector->getType()->isStructTy());
      return B.CreateExtractValue(Vector, Index);
    }
  };

  // The resulting value could be a short or a long vector as well.
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

Value *LongVectorLoweringPass::visitStoreInst(StoreInst &I) {
  Value *EquivalentValue = visit(I.getValueOperand());
  assert(EquivalentValue && "value not lowered");
  Value *EquivalentPointer = visit(I.getPointerOperand());
  assert(EquivalentPointer && "pointer not lowered");

  IRBuilder<> B(&I);
  auto *V = B.CreateAlignedStore(EquivalentValue, EquivalentPointer,
                                 I.getAlign(), I.isVolatile());
  registerReplacement(I, *V);
  return V;
}

Value *LongVectorLoweringPass::visitUnaryOperator(UnaryOperator &I) {
  return visitNAryOperator(I);
}

bool LongVectorLoweringPass::handlingRequired(User &U) {
  if (getEquivalentType(U.getType()) != nullptr) {
    return true;
  }

  for (auto &Operand : U.operands()) {
    auto *OperandTy = Operand.get()->getType();
    if (getEquivalentType(OperandTy) != nullptr) {
      return true;
    }
  }

  return false;
}

void LongVectorLoweringPass::registerReplacement(Value &U, Value &V) {
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

Type *LongVectorLoweringPass::getEquivalentType(Type *Ty) {
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

Type *LongVectorLoweringPass::getEquivalentTypeImpl(Type *Ty) {
  if (Ty->isIntegerTy() || Ty->isFloatingPointTy() || Ty->isVoidTy() ||
      Ty->isLabelTy()) {
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

      SmallVector<Type *, 16> AggregateBody(Arity, ScalarTy);
      auto &C = Ty->getContext();
      return StructType::get(C, AggregateBody);
    }

    return nullptr;
  }

  if (auto *PointerTy = dyn_cast<PointerType>(Ty)) {
    if (auto *ElementTy = getEquivalentType(PointerTy->getElementType())) {
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
    unsigned Arity = StructTy->getStructNumElements();
    for (unsigned i = 0; i < Arity; ++i) {
      if (getEquivalentType(StructTy->getContainedType(i)) != nullptr) {
        llvm_unreachable(
            "Nested types not yet supported, need test cases (struct)");
      }
    }

    return nullptr;
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

bool LongVectorLoweringPass::runOnGlobals(Module &M) {
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

bool LongVectorLoweringPass::runOnFunction(Function &F) {
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

Value *
LongVectorLoweringPass::convertBuiltinCall(CallInst &VectorCall,
                                           Type *EquivalentReturnTy,
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

  return convertVectorOperation(VectorCall, EquivalentReturnTy, EquivalentArgs,
                                ScalarFactory);
}

Function *LongVectorLoweringPass::convertUserDefinedFunction(Function &F) {
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

CallInst *LongVectorLoweringPass::convertUserDefinedFunctionCall(
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

void LongVectorLoweringPass::cleanDeadInstructions() {
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

void LongVectorLoweringPass::cleanDeadFunctions() {
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

void LongVectorLoweringPass::cleanDeadGlobals() {
  for (auto const &Mapping : GlobalVariableMap) {
    auto *GV = Mapping.first;
    GV->eraseFromParent();
  }
}

} // namespace

INITIALIZE_PASS(LongVectorLoweringPass, "LongVectorLowering",
                "Long Vector Lowering Pass", false, false)

llvm::ModulePass *clspv::createLongVectorLoweringPass() {
  return new LongVectorLoweringPass();
}
