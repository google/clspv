// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include "ArgKind.h"
#include "BitcastUtils.h"

#include "Types.h"
#include "clspv/Option.h"

#include "RewritePackedStructs.h"

using namespace llvm;

#define DEBUG_TYPE "RewritePackedStructs"

namespace {

unsigned getStructAlignment(Type *Ty, const DataLayout *DL) {
  unsigned structAlignment = 1;
  for (unsigned i = 0; i < Ty->getNumContainedTypes(); i++) {
    Type *ElemTy = Ty->getContainedType(i);

    if (ElemTy->isAggregateType() || ElemTy->isVectorTy()) {
      structAlignment =
          std::max(structAlignment, getStructAlignment(ElemTy, DL));
    } else {
      structAlignment =
          std::max(structAlignment, (unsigned)DL->getTypeAllocSize(ElemTy));
    }
  }
  return structAlignment;
}

} // namespace

PreservedAnalyses clspv::RewritePackedStructs::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  DL = &M.getDataLayout();

  for (auto &F : M.functions()) {
    if (structsShouldBeLowered(F)) {
      runOnFunction(F);
    }
  }

  return PA;
}

bool clspv::RewritePackedStructs::structsShouldBeLowered(Function &F) {
  for (Instruction &I : instructions(F)) {
    if (auto gep = dyn_cast<GetElementPtrInst>(&I)) {
      Type *source_ty = clspv::InferType(gep->getPointerOperand(),
                                         F.getContext(), &type_cache_);
      Type *dest_ty = gep->getSourceElementType();
      if (auto STy = dyn_cast<StructType>(dest_ty)) {
        if (STy->isPacked())
          return true;
      }
      if (source_ty && dest_ty &&
          (source_ty->isStructTy() || dest_ty->isStructTy()) &&
          source_ty != dest_ty) {
        return true;
      }
    }
  }
  return false;
}

Type *clspv::RewritePackedStructs::getEquivalentType(Type *Ty) {
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

Type *clspv::RewritePackedStructs::getEquivalentTypeImpl(Type *Ty) {
  if (!Ty->isPointerTy() && !Ty->isStructTy() && !Ty->isFunctionTy()) {
    // No rewriting required.
    return nullptr;
  }

  if (Ty->isPointerTy()) {
    return nullptr;
  }

  if (auto *StructTy = dyn_cast<StructType>(Ty)) {
    if (StructTy->getStructNumElements() == 0)
      return nullptr;
    LLVMContext &Ctx = StructTy->getContainedType(0)->getContext();
    SmallVector<Type *, 16> Types;
    bool Packed = StructTy->isPacked();
    uint32_t structSize = DL->getTypeAllocSize(StructTy);
    uint32_t structAlignment = getStructAlignment(StructTy, DL);

    ArrayType *ArrayTy = ArrayType::get(Type::getInt8Ty(Ctx), structSize);
    if (Packed && structSize % structAlignment != 0) {
      return StructType::get(Ctx, {ArrayTy}, Packed);
    } else {
      return ArrayTy;
    }
  }

  if (auto *FunctionTy = dyn_cast<FunctionType>(Ty)) {
    if (FunctionTy->isVarArg()) {
      llvm_unreachable("varargs not supported");
    }

    bool RequireRewriting = false;

    // Convert parameter types.
    SmallVector<Type *, 16> EquivalentParamTys;
    EquivalentParamTys.reserve(FunctionTy->getNumParams());
    for (auto *ParamTy : FunctionTy->params()) {
      auto *EquivalentParamTy = getEquivalentTypeOrSelf(ParamTy);
      EquivalentParamTys.push_back(EquivalentParamTy);
      RequireRewriting |= (EquivalentParamTy != ParamTy);
    }

    if (RequireRewriting) {
      return FunctionType::get(FunctionTy->getReturnType(), EquivalentParamTys,
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

bool clspv::RewritePackedStructs::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return false;
  }

  SmallVector<GetElementPtrInst *, 16> WorkList;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto gep = dyn_cast<GetElementPtrInst>(&I)) {
        if (gep->getSourceElementType()->isStructTy()) {
          WorkList.push_back(gep);
        }
      }
    }
  }

  bool changed = false;

  for (auto gep : WorkList) {
    auto EquivalentTy = getEquivalentType(gep->getSourceElementType());
    if (EquivalentTy == gep->getSourceElementType()) {
      continue;
    }
    auto NewGEP =
        GetElementPtrInst::Create(EquivalentTy, gep->getPointerOperand(),
                                  {gep->getOperand(1)}, "", gep->getIterator());
    if (gep->getNumOperands() > 2) {
      SmallVector<Value *, 2> Indices;
      Indices.push_back(ConstantInt::get(Type::getInt32Ty(F.getContext()), 0));
      for (unsigned i = 2; i < gep->getNumOperands(); i++) {
        Indices.push_back(gep->getOperand(i));
      }
      NewGEP = GetElementPtrInst::Create(gep->getSourceElementType(), NewGEP,
                                         Indices, "", gep->getIterator());
    }
    gep->replaceAllUsesWith(NewGEP);
    gep->eraseFromParent();
    changed = true;
  }

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << F << '\n');

  return changed;
}
