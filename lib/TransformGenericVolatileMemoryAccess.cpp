// Copyright 2019 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "clspv/AddressSpace.h"

#include "TransformGenericVolatileMemoryAccess.h"

using namespace llvm;

PreservedAnalyses
clspv::TransformGenericVolatileMemoryAccess::run(Module &M,
                                                 ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  SmallVector<Instruction *> DeadInsts;

  for (auto &F : M.functions()) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        IRBuilder<> B(&I);

        if (auto *load = dyn_cast<LoadInst>(&I)) {
          if (load->isVolatile() &&
              getPointerAddressSpace(load->getPointerOperandType()) ==
                  clspv::AddressSpace::Generic) {
            auto NonVolatileLoad =
                B.CreateLoad(load->getType(), load->getPointerOperand());
            load->replaceAllUsesWith(NonVolatileLoad);
            DeadInsts.push_back(load);
          }
        } else if (auto *store = dyn_cast<StoreInst>(&I)) {
          if (store->isVolatile() &&
              getPointerAddressSpace(store->getPointerOperandType()) ==
                  clspv::AddressSpace::Generic) {
            B.CreateStore(store->getValueOperand(), store->getPointerOperand());
            DeadInsts.push_back(store);
          }
        }
      }
    }
  }

  for (auto Inst : DeadInsts) {
    Inst->eraseFromParent();
  }

  return PA;
}

unsigned clspv::TransformGenericVolatileMemoryAccess::getPointerAddressSpace(
    Type *PtrTy) const {
  if (PtrTy->getNonOpaquePointerElementType()->isPointerTy()) {
    return getPointerAddressSpace(PtrTy->getNonOpaquePointerElementType());
  }
  return PtrTy->getPointerAddressSpace();
}
