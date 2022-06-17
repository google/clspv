// Copyright 2018 The Clspv Authors. All rights reserved.
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

#include <utility>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

#include "ZeroInitializeAllocasPass.h"

using namespace llvm;

#define DEBUG_TYPE "rewriteconstantexpressions"

namespace {

llvm::cl::opt<bool>
    no_zero_allocas("no-zero-allocas", llvm::cl::init(false),
                    llvm::cl::desc("Don't zero-initialize stack variables"));

} // namespace

PreservedAnalyses
clspv::ZeroInitializeAllocasPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (no_zero_allocas)
    return PA;

  SmallVector<AllocaInst *, 8> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (auto iter = BB.begin(); iter != BB.end(); ++iter) {
        if (auto *alloca = dyn_cast<AllocaInst>(&*iter)) {
          WorkList.push_back(alloca);
        }
      }
    }
  }

  for (AllocaInst *alloca : WorkList) {
    auto *valueTy = alloca->getAllocatedType();
    auto *store = new StoreInst(Constant::getNullValue(valueTy), alloca, false,
                                Align(alloca->getAlign()));
    store->insertAfter(alloca);
  }

  return PA;
}
