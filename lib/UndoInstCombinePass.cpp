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

// This pass is run afer LongVectorLowering so the maximum vector size is 4
constexpr unsigned int max_vector_size = 4;

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

VectorType *InferTypeForOpaqueLoad(VectorType *old_type) {
  auto vec_size = old_type->getElementCount().getKnownMinValue();
  auto bit_width = cast<IntegerType>(old_type->getElementType())->getBitWidth();

  // All the integers in OpenCL C have a power of two bit width
  auto is_pow_of_two = [](auto x) { return (x & (x - 1)) == 0; };

  // If vec size 4 or 3 doesn't fit the index then smaller sizes won't allow
  // greater granularity
  uint64_t new_size =
      vec_size % 4 == 0 && is_pow_of_two((vec_size / 4) * bit_width) ? 4 : 3;
  uint64_t divisor = vec_size / new_size;

  auto new_bit_width = bit_width * divisor;

  return VectorType::get(
      IntegerType::get(old_type->getContext(), new_bit_width), new_size,
      old_type->getElementCount().isScalable());
}

bool clspv::UndoInstCombinePass::UndoWideVectorExtractCast(Instruction *inst) {
  auto extract = dyn_cast<ExtractElementInst>(inst);
  if (!extract)
    return false;

  auto vec_ty = extract->getVectorOperandType();
  auto vec_size = vec_ty->getElementCount().getKnownMinValue();
  if (vec_size <= max_vector_size)
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto const_idx = dyn_cast<ConstantInt>(extract->getIndexOperand());
  if (!const_idx)
    return false;

  auto extract_src = extract->getVectorOperand();
  auto load = dyn_cast<LoadInst>(extract_src);
  // If this is a load, check for a cast on the pointer operand
  auto cast =
      dyn_cast<BitCastOperator>(load ? load->getPointerOperand() : extract_src);

  Value *src =
      cast ? cast->getOperand(0) : (load ? load->getPointerOperand() : nullptr);
  if (!src)
    return false;

  auto src_ty = src->getType();
  VectorType *src_vec_ty = [src_ty, vec_ty] {
    if (src_ty->isOpaquePointerTy()) {
      return InferTypeForOpaqueLoad(vec_ty);
      // TODO: #816 remove after final switch.
    } else if (src_ty->isPointerTy()) {
      return dyn_cast<VectorType>(src_ty->getNonOpaquePointerElementType());
    } else {
      return dyn_cast<VectorType>(src_ty);
    }
  }();

  if (!src_vec_ty)
    return false;

  uint64_t src_elements = src_vec_ty->getElementCount().getKnownMinValue();

  if (vec_size <= src_elements)
    return false;

  uint64_t idx = const_idx->getZExtValue();
  uint64_t ratio = vec_size / src_elements;
  uint64_t new_idx = idx / ratio;

  // Instcombine should never have generated an odd index, so don't handle
  // right now.
  if (idx & 0x1)
    return false;

  IRBuilder<> builder(inst);
  src = load ? builder.CreateLoad(src_vec_ty, src) : src;
  if (load) {
    potentially_dead_.insert(load);
  }
  auto new_src = builder.CreateExtractElement(src, builder.getInt32(new_idx));
  auto trunc = builder.CreateTrunc(new_src, extract->getType());
  extract->replaceAllUsesWith(trunc);

  dead_.push_back(extract);
  if (cast)
    potentially_dead_.insert(cast);

  return true;
}

bool clspv::UndoInstCombinePass::UndoWideVectorShuffleCast(Instruction *inst) {
  auto shuffle = dyn_cast<ShuffleVectorInst>(inst);
  if (!shuffle)
    return false;

  // Instcombine only produces shuffles with an undef second input, so don't
  // handle other cases for now.
  if (!isa<UndefValue>(shuffle->getOperand(1)))
    return false;

  // Instcombine only transforms TruncInst (which operates on integers).
  auto vec_ty = cast<VectorType>(shuffle->getType());
  if (!vec_ty->getElementType()->isIntegerTy())
    return false;

  auto in1 = shuffle->getOperand(0);
  auto in1_vec_ty = cast<VectorType>(in1->getType());
  auto in1_vec_size = in1_vec_ty->getElementCount().getKnownMinValue();
  if (in1_vec_size <= max_vector_size)
    return false;

  auto in1_load = dyn_cast<LoadInst>(in1);
  // If this is a load, check for a cast on the pointer operand
  auto in1_cast =
      dyn_cast<BitCastOperator>(in1_load ? in1_load->getPointerOperand() : in1);

  Value *src = in1_cast ? in1_cast->getOperand(0)
                        : (in1_load ? in1_load->getPointerOperand() : nullptr);
  if (!src)
    return false;

  auto src_ty = src->getType();
  VectorType *src_vec_ty = [src_ty, in1_vec_ty] {
    if (src_ty->isOpaquePointerTy()) {
      return InferTypeForOpaqueLoad(in1_vec_ty);
      // TODO: #816 remove after final switch.
    } else if (src_ty->isPointerTy()) {
      return dyn_cast<VectorType>(src_ty->getNonOpaquePointerElementType());
    } else {
      return dyn_cast<VectorType>(src_ty);
    }
  }();

  if (!src_vec_ty)
    return false;

  uint64_t src_elements = src_vec_ty->getElementCount().getKnownMinValue();

  if (in1_vec_size <= src_elements)
    return false;

  uint64_t ratio = in1_vec_size / src_elements;
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

  // TODO could replace with a shuffle and vectorized trunc
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
  // TODO: #816 remove after final switch.
  if (in1_cast)
    potentially_dead_.insert(in1_cast);

  return true;
}
