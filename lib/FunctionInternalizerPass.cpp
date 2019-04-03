// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "clspv/Passes.h"

using namespace llvm;

#define DEBUG_TYPE "FunctionInternalizer"

namespace {
struct FunctionInternalizerPass : public ModulePass {
  static char ID;
  FunctionInternalizerPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char FunctionInternalizerPass::ID = 0;
INITIALIZE_PASS(FunctionInternalizerPass, "FunctionInternalizer",
                "Function Internalizer Pass", false, false)

namespace clspv {
ModulePass *createFunctionInternalizerPass() {
  return new FunctionInternalizerPass();
}
} // namespace clspv

bool FunctionInternalizerPass::runOnModule(Module &M) {
  SmallVector<Function *, 8> ToRemoves;

  for (auto &F : M) {
    if ((CallingConv::SPIR_KERNEL != F.getCallingConv()) && F.user_empty()) {
      ToRemoves.push_back(&F);
    }
  }

  for (auto *F : ToRemoves) {
    F->eraseFromParent();
  }

  return !ToRemoves.empty();
}
