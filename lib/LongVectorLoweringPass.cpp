// Copyright 2020 The Clspv Authors. All rights reserved.
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
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"

#include "clspv/Passes.h"

#include "Passes.h"

#include <functional>

using namespace llvm;

#define DEBUG_TYPE "LongVectorLowering"

namespace {

class LongVectorLoweringPass final : public ModulePass {
public:
  static char ID;

public:
  LongVectorLoweringPass() : ModulePass(ID) {}

  /// Lower the content of the given module @p M.
  bool runOnModule(Module &M) override;

private:
  /// Higher-level dispatcher.
  /// Returns nullptr if no lowering is required.
  Value *visit(Value *V);

private:
  // Helpers for lowering types.

  /// Get a struct equivalent for this type, if it uses a long vector.
  /// Returns nullptr if no lowering is required.
  Type *getEquivalentType(Type *Ty);

private:
  // Hight-level implementation details of runOnModule.

  /// Lower the given function.
  bool runOnFunction(Function &F);
};

char LongVectorLoweringPass::ID = 0;

/// Convert the given value @p V to a value of the given @p EquivalentTy.
///
/// @return @p V when @p V's type is @p newType.
/// @return an equivalent vector when @p V is an aggregate.
/// @return an equivalent aggregate when @p V is a vector.
Value *convertEquivalentValue(IRBuilder<> &B, Value *V, Type *EquivalentTy) {
  if (V->getType() == EquivalentTy) {
    return V;
  }

  // TODO Support pointer types.
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

/// Scalarise a vector instruction element-wise by invoking the operation
/// @p ScalarOperation.
Value *convertVectorOperation(IRBuilder<> &B, Type *EquivalentReturnTy,
                              ArrayRef<Value *> EquivalentArgs,
                              ScalarOperationFactory ScalarOperation) {
  assert(EquivalentReturnTy != nullptr);
  assert(EquivalentReturnTy->isStructTy());

  Value *ReturnValue = UndefValue::get(EquivalentReturnTy);
  unsigned Arity = EquivalentReturnTy->getNumContainedTypes();

  // Invoke the scalar operation once for each vector element.
  for (unsigned i = 0; i < Arity; ++i) {
    SmallVector<Value *, 16> Args;
    Args.resize(EquivalentArgs.size());

    for (unsigned j = 0; j < Args.size(); ++j) {
      assert(EquivalentArgs[j]->getType()->isStructTy());
      Args[j] = B.CreateExtractValue(EquivalentArgs[j], i);
    }

    Value *Scalar = ScalarOperation(B, Args);
    ReturnValue = B.CreateInsertValue(ReturnValue, Scalar, i);
  }

  return ReturnValue;
}

bool LongVectorLoweringPass::runOnModule(Module &M) {
  bool Modified = false;

  for (auto &F : M.functions()) {
    Modified |= runOnFunction(F);
  }

  return Modified;
}

Value *LongVectorLoweringPass::visit(Value *V) {
  if (auto *BinOp = dyn_cast<BinaryOperator>(V)) {
    if (auto *EquivalentType = getEquivalentType(BinOp->getType())) {
      IRBuilder<> B(BinOp);

      SmallVector<Value *, 16> EquivalentArgs;
      for (auto &Operand : BinOp->operands()) {
        auto *Arg = Operand.get();
        // TODO Visit argument to lower it.
        // Instead, for now, we create an equivalent aggregate.
        auto *EquivalentArgTy = getEquivalentType(Arg->getType());
        auto *EquivalentArg = convertEquivalentValue(B, Arg, EquivalentArgTy);
        EquivalentArgs.push_back(EquivalentArg);
      }

      auto ScalarFactory = [Opcode = BinOp->getOpcode()](auto &B, auto Args) {
        return B.CreateNAryOp(Opcode, Args);
      };
      Value *EquivalentValue = convertVectorOperation(
          B, EquivalentType, EquivalentArgs, ScalarFactory);

      // TODO Implement support for additional instructions.
      // Because support is very limited, as an initial step we convert the
      // aggregate back to a vector to generate a valid module.
      auto *ReplacementValue =
          convertEquivalentValue(B, EquivalentValue, BinOp->getType());
      BinOp->replaceAllUsesWith(ReplacementValue);

      return ReplacementValue;
    }
  }

#ifndef NDEBUG
  dbgs() << "Value not handled: " << *V << '\n';
#endif
  // TODO Once additional features are implemented, turn this into an error by
  // uncommenting the next line.
  // llvm_unreachable("Kind of value not handled yet.");
  return nullptr;
}

Type *LongVectorLoweringPass::getEquivalentType(Type *Ty) {
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

#ifndef NDEBUG
  dbgs() << "Unsupported type: " << *Ty << '\n';
#endif
  // TODO Once additional features are implemented, turn this into an error by
  // uncommenting the next line.
  // llvm_unreachable("Unsupported kind of Type.");
  return nullptr;
}

bool LongVectorLoweringPass::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return false;
  }

  // TODO Support long-vector types as parameters of non-kernel functions.
  Function *FunctionToVisit = &F;

  bool Modified = (FunctionToVisit != &F);
  for (Instruction &I : instructions(FunctionToVisit)) {
    Modified |= (visit(&I) != nullptr);
  }

  // TODO Clean dead instructions.

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << *FunctionToVisit << '\n');

  return Modified;
}

} // namespace

INITIALIZE_PASS(LongVectorLoweringPass, "LongVectorLowering",
                "Long Vector Lowering Pass", false, false)

llvm::ModulePass *clspv::createLongVectorLoweringPass() {
  return new LongVectorLoweringPass();
}
