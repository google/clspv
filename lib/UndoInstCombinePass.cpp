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

#include "UndoInstCombinePass.h"

#define DEBUG_TYPE "undoinstcombine"

using namespace llvm;

PreservedAnalyses clspv::UndoInstCombinePass::run(Module &M,
                                                  ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  for (auto &F : M) {
    runOnFunction(F);
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

  return PA;
}

bool clspv::UndoInstCombinePass::runOnFunction(Function &F) {
  bool changed = false;

  for (auto &BB : F) {
    for (auto &I : BB) {
      changed |= UndoWideVectorExtractCast(&I);
      changed |= UndoWideVectorShuffleCast(&I);
    }
  }

  return changed;
}

bool clspv::UndoInstCombinePass::UndoWideVectorExtractCast(Instruction *inst) {
  auto extract = dyn_cast<ExtractElementInst>(inst);
  if (!extract)
    return false;

  auto vec_ty = extract->getVectorOperandType();
  auto vec_size = vec_ty->getElementCount().getKnownMinValue();
  if (vec_size <= 4)
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto const_idx = dyn_cast<ConstantInt>(extract->getIndexOperand());
  if (!const_idx)
    return false;

  auto load = dyn_cast<LoadInst>(extract->getVectorOperand());
  if (load && load->getPointerOperand()->getType()->isOpaquePointerTy()) {
    // calculate the smallest vector we can create and still access the target
    // bytes
    uint64_t idx = const_idx->getZExtValue();
    uint64_t new_size = 4;
    while (vec_size % new_size) { // will always break at new_size == 1
      new_size -= 1;
    }
    uint64_t divisor = vec_size / new_size;

    uint64_t new_idx = idx / divisor;
    IRBuilder<> builder(inst);
    const auto old_type = llvm::cast<VectorType>(load->getType());

    auto new_bit_width =
        cast<IntegerType>(old_type->getElementType())->getBitWidth() * divisor;

    Value *new_load = builder.CreateLoad(
        VectorType::get(IntegerType::get(old_type->getContext(), new_bit_width),
                        new_size, old_type->getElementCount().isScalable()),
        load->getPointerOperand());

    Value *new_src =
        builder.CreateExtractElement(new_load, builder.getInt32(new_idx));
    auto trunc = builder.CreateTrunc(new_src, extract->getType());

    extract->replaceAllUsesWith(trunc);
    dead_.push_back(extract);

    potentially_dead_.insert(load);
    return true;
  } else {

    auto cast = load ? dyn_cast<BitCastOperator>(load->getPointerOperand())
                     : dyn_cast<BitCastOperator>(extract->getVectorOperand());

    if (!cast)
      return false;

    auto src = cast->getOperand(0);
    auto src_ty = src->getType();
    VectorType *src_vec_ty = nullptr;
    // TODO: #816 remove after final switch. would not do a bitcast on a pointer
    if (isa<PointerType>(src_ty)) {
      // In the load cast, go through the pointer first.
      src_vec_ty =
          dyn_cast<VectorType>(src_ty->getNonOpaquePointerElementType());
    } else {
      src_vec_ty = dyn_cast<VectorType>(src_ty);
    }

    if (!src_vec_ty)
      return false;

    uint64_t src_elements = src_vec_ty->getElementCount().getKnownMinValue();
    uint64_t dst_elements = vec_ty->getElementCount().getKnownMinValue();

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
    // TODO: #816 remove after final switch. (load handled by opaque pointer
    // case)
    if (load) {
      potentially_dead_.insert(load);
      new_src = builder.CreateLoad(src_vec_ty, src);
      src = new_src;
    }
    new_src = builder.CreateExtractElement(src, builder.getInt32(new_idx));
    auto trunc = builder.CreateTrunc(new_src, extract->getType());
    extract->replaceAllUsesWith(trunc);
    dead_.push_back(extract);
    potentially_dead_.insert(cast);

    return true;
  }
}

bool clspv::UndoInstCombinePass::UndoWideVectorShuffleCast(Instruction *inst) {
  auto shuffle = dyn_cast<ShuffleVectorInst>(inst);
  if (!shuffle)
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  auto vec_ty = cast<VectorType>(shuffle->getType());
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto in1 = shuffle->getOperand(0);
  auto in1_vec_ty = cast<VectorType>(in1->getType());
  if (in1_vec_ty->getElementCount().getKnownMinValue() <= 4)
    return false;

  auto in1_load = dyn_cast<LoadInst>(in1);
  auto in1_cast = dyn_cast<BitCastOperator>(in1);
  if (in1_load) {
    // If this is a load, check for a cast on the pointer operand
    in1_cast = dyn_cast<BitCastOperator>(in1_load->getPointerOperand());
  }

  if (!in1_cast)
    return false;

  // Instcombine only produces shuffles with an undef second input, so don't
  // handle other cases for now.
  if (!isa<UndefValue>(shuffle->getOperand(1)))
    return false;

  auto src = in1_cast->getOperand(0);
  auto src_ty = src->getType();
  VectorType *src_vec_ty = nullptr;
  // TODO: #816 remove after final switch.
  if (isa<PointerType>(src_ty)) {
    // In the load cast, go through the pointer first.
    if (src_ty->isOpaquePointerTy())
      return false;
    src_vec_ty = dyn_cast<VectorType>(src_ty->getNonOpaquePointerElementType());
  } else {
    src_vec_ty = dyn_cast<VectorType>(src_ty);
  }

  if (!src_vec_ty)
    return false;

  uint64_t src_elements = src_vec_ty->getElementCount().getKnownMinValue();
  uint64_t dst_elements = in1_vec_ty->getElementCount().getKnownMinValue();

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
    src = builder.CreateLoad(src_vec_ty, src);
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
