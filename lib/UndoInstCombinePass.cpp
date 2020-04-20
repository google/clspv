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

#include <vector>

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Pass.h"

#include "Passes.h"

#define DEBUG_TYPE "undoinstcombine"

using namespace llvm;

namespace {
class UndoInstCombinePass : public ModulePass {
public:
  static char ID;
  UndoInstCombinePass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  bool runOnFunction(Function &F);

  // Undoes wide vector casts that are used in an extract, for example:
  //  %cast = bitcast <4 x i32> %src to <16 x i8>
  //  %extract = extractelement <16 x i8> %cast, i32 4
  //
  // With:
  //  %extract = extractelement <4 x i32> %src, i32 1
  //  %trunc = trunc i32 %extract to i8
  //
  // Also handles casts that get loaded, for example:
  //  %cast = bitcast <3 x i32>* %src to <6 x i16>*
  //  %load = load <6 x i16>, <6 x i16>* %cast
  //  %extract = extractelement <6 x i16> %load, i32 0
  //
  // With:
  //  %load = load <3 x i32>, <3 x i32>* %src
  //  %extract = extractelement <3 x i32> %load, i32 0
  //  %trunc = trunc i32 %extract to i16
  bool UndoWideVectorExtractCast(Instruction *inst);

  // Undoes wide vector casts that are used in a shuffle, for example:
  //  %cast = bitcast <4 x i32> %src to <16 x i8>
  //  %s = shufflevector <16 x i8> %cast, <16 x i8> undef,
  //                       <2 x i8> <i32 4, i32 8>
  //
  // With:
  //  %extract0 = <4 x i32> %src, i32 1
  //  %trunc0 = trunc i32 %extract0 to i8
  //  %insert0 = insertelement <2 x i8> zeroinitializer, i8 %trunc0, i32 0
  //  %extract1 = <4 x i32> %src, i32 2
  //  %trunc1 = trunc i32 %extract1 to i8
  //  %insert1 = insertelement <2 x i8> %insert0, i8 %trunc1, i32 1
  //
  // Also handles shuffles casted through a load, for example:
  //  %cast = bitcast <3 x i32>* %src to <6 x i16>
  //  %load = load <6 x i16>* %cast
  //  %shuffle = shufflevector <6 x i16> %load, <6 x i16> undef,
  //                            <2 x i32> <i32 2, i32 4>
  //
  // With:
  //  %load = load <3 x i32>, <3 x i32>* %src
  //  %ex0 = extractelement <3 x i32> %load, i32 1
  //  %trunc0 = trunc i32 %ex0 to i16
  //  %in0 = insertelement <2 x i16> zeroinitializer, i16 %trunc0, i32 0
  //  %ex1 = extractelement <3 x i32> %load, i32 2
  //  %trunc1 = trunc i32 %ex1 to i16
  //  %in1 = insertelement <2 x i16> %in0, i16 %trunc1, i32 1
  bool UndoWideVectorShuffleCast(Instruction *inst);

  UniqueVector<Value *> potentially_dead_;
  std::vector<Instruction *> dead_;
};
} // namespace

char UndoInstCombinePass::ID = 0;
INITIALIZE_PASS(UndoInstCombinePass, "UndoInstCombine",
                "Undo specific harmful instcombine transformations", false,
                false)

namespace clspv {
ModulePass *createUndoInstCombinePass() { return new UndoInstCombinePass(); }
} // namespace clspv

bool UndoInstCombinePass::runOnModule(Module &M) {
  bool changed = false;

  for (auto &F : M) {
    changed |= runOnFunction(F);
  }

  // Cleanup.
  for (auto inst : dead_)
    inst->eraseFromParent();

  for (auto val : potentially_dead_) {
    if (auto inst = dyn_cast<Instruction>(val)) {
      if (inst->user_empty())
        inst->eraseFromParent();
    } else if (auto cast = dyn_cast<BitCastOperator>(val)) {
      if (auto constant = dyn_cast<Constant>(cast->getOperand(0)))
        constant->removeDeadConstantUsers();
    }
  }

  return changed;
}

bool UndoInstCombinePass::runOnFunction(Function &F) {
  bool changed = false;

  for (auto &BB : F) {
    for (auto &I : BB) {
      changed |= UndoWideVectorExtractCast(&I);
      changed |= UndoWideVectorShuffleCast(&I);
    }
  }

  return changed;
}

bool UndoInstCombinePass::UndoWideVectorExtractCast(Instruction *inst) {
  auto extract = dyn_cast<ExtractElementInst>(inst);
  if (!extract)
    return false;

  auto vec_ty = extract->getVectorOperandType();
  if (vec_ty->getElementCount().Min <= 4)
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto const_idx = dyn_cast<ConstantInt>(extract->getIndexOperand());
  if (!const_idx)
    return false;

  auto load = dyn_cast<LoadInst>(extract->getVectorOperand());
  auto cast = dyn_cast<BitCastOperator>(extract->getVectorOperand());
  if (load) {
    // If this is a laod, check for a cast on the pointer operand
    cast = dyn_cast<BitCastOperator>(load->getPointerOperand());
  }

  if (!cast)
    return false;

  auto src = cast->getOperand(0);
  VectorType *src_vec_ty = nullptr;
  if (isa<PointerType>(src->getType()))
    // In the load cast, go through the pointer first.
    src_vec_ty = dyn_cast<VectorType>(src->getType()->getPointerElementType());
  else
    src_vec_ty = dyn_cast<VectorType>(src->getType());

  if (!src_vec_ty)
    return false;

  uint64_t src_elements = src_vec_ty->getElementCount().Min;
  uint64_t dst_elements = vec_ty->getElementCount().Min;

  if (dst_elements < src_elements)
    return false;

  uint64_t idx = const_idx->getZExtValue();
  uint64_t ratio = dst_elements / src_elements;
  uint64_t new_idx = idx / ratio;

  // Instcombine should never have generated an odd index, so don't handle
  // right now.
  if (idx & 0x1)
    return false;

  // Create a truncate of an extract element.
  IRBuilder<> builder(inst);
  Value *new_src = nullptr;
  if (load) {
    potentially_dead_.insert(load);
    new_src = builder.CreateLoad(src);
    src = new_src;
  }
  new_src = builder.CreateExtractElement(src, builder.getInt32(new_idx));
  auto trunc = builder.CreateTrunc(new_src, extract->getType());
  extract->replaceAllUsesWith(trunc);
  dead_.push_back(extract);
  potentially_dead_.insert(cast);

  return true;
}

bool UndoInstCombinePass::UndoWideVectorShuffleCast(Instruction *inst) {
  auto shuffle = dyn_cast<ShuffleVectorInst>(inst);
  if (!shuffle)
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  auto vec_ty = cast<VectorType>(shuffle->getType());
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto in1 = shuffle->getOperand(0);
  auto in1_vec_ty = cast<VectorType>(in1->getType());
  if (in1_vec_ty->getElementCount().Min <= 4)
    return false;

  auto in1_load = dyn_cast<LoadInst>(in1);
  auto in1_cast = dyn_cast<BitCastOperator>(in1);
  if (in1_load) {
    // If this is a laod, check for a cast on the pointer operand
    in1_cast = dyn_cast<BitCastOperator>(in1_load->getPointerOperand());
  }

  if (!in1_cast)
    return false;

  // Instcombine only produces shuffles with an undef second input, so don't
  // handle other cases for now.
  if (!isa<UndefValue>(shuffle->getOperand(1)))
    return false;

  auto src = in1_cast->getOperand(0);
  VectorType *src_vec_ty = nullptr;
  if (isa<PointerType>(src->getType()))
    // In the load cast, go through the pointer first.
    src_vec_ty = dyn_cast<VectorType>(src->getType()->getPointerElementType());
  else
    src_vec_ty = dyn_cast<VectorType>(src->getType());

  if (!src_vec_ty)
    return false;

  uint64_t src_elements = src_vec_ty->getElementCount().Min;
  uint64_t dst_elements = in1_vec_ty->getElementCount().Min;

  if (dst_elements < src_elements)
    return false;

  uint64_t ratio = dst_elements / src_elements;
  auto dst_scalar_type = vec_ty->getElementType();

  SmallVector<int, 16> mask;
  shuffle->getShuffleMask(mask);
  for (auto i : mask) {
    // Instcombine should not have generated odd indices, so don't handle them
    // for now.
    if ((i != UndefMaskElem) && (i & 0x1))
      return false;
  }

  // For each index, create a truncate of an extract element and insert each
  // into the result vector.
  IRBuilder<> builder(inst);
  Value *insert = nullptr;
  if (in1_load) {
    potentially_dead_.insert(in1_load);
    src = builder.CreateLoad(src);
  }

  int i = 0;
  for (auto idx : mask) {
    if (idx == UndefMaskElem)
      continue;

    uint64_t new_idx = idx / ratio;
    auto extract = builder.CreateExtractElement(src, builder.getInt32(new_idx));
    auto trunc = builder.CreateTrunc(extract, dst_scalar_type);
    Value *prev = insert ? insert : Constant::getNullValue(vec_ty);
    insert = builder.CreateInsertElement(prev, trunc, builder.getInt32(i++));
  }
  if (!insert) {
    insert = Constant::getNullValue(vec_ty);
  }
  shuffle->replaceAllUsesWith(insert);
  dead_.push_back(shuffle);
  potentially_dead_.insert(in1_cast);

  return true;
}
