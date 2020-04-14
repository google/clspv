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

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "Builtins.h"
#include "Passes.h"

using namespace llvm;
using namespace clspv;

#define DEBUG_TYPE "openclinliner"

namespace {
struct OpenCLInlinerPass : public ModulePass {
  static char ID;
  OpenCLInlinerPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char OpenCLInlinerPass::ID = 0;
INITIALIZE_PASS(OpenCLInlinerPass, "OpenCLInliner", "OpenCL Inliner Pass",
                false, false)

namespace clspv {
ModulePass *createOpenCLInlinerPass() { return new OpenCLInlinerPass(); }
} // namespace clspv

bool OpenCLInlinerPass::runOnModule(Module &M) {
  bool changed = false;
  std::list<Function *> func_list;
  for (auto &F : M.getFunctionList()) {
    // process only WorkItem functions
    auto &func_info = Builtins::Lookup(&F);
    if (func_info.getType() > Builtins::kType_WorkItem_Start &&
        func_info.getType() < Builtins::kType_WorkItem_End) {
      SmallVector<CallInst *, 4> Calls;

      // Walk the users of the function.
      for (User *U : F.users()) {
        // Find only the calls to the function.
        if (CallInst *CI = dyn_cast<CallInst>(U)) {
          // If the called function doesn't take an argument or is using a
          // constant argument, add the call to the list of to-be-inlined calls.
          if (F.arg_empty() || isa<Constant>(CI->getArgOperand(0))) {
            Calls.push_back(CI);
          }
        }
      }

      for (CallInst *CI : Calls) {
        InlineFunctionInfo info;
        changed |= InlineFunction(*CI, info).isSuccess();
      }
      func_list.push_front(&F);
    }
  }
  if (func_list.size() != 0) {
    // remove dead
    for (auto *F : func_list) {
      if (F->use_empty()) {
        F->eraseFromParent();
      }
    }
  }
  return changed;
}
