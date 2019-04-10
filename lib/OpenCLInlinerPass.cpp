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

using namespace llvm;

#define DEBUG_TYPE "openclinliner"

namespace {
struct OpenCLInlinerPass : public ModulePass {
  static char ID;
  OpenCLInlinerPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char OpenCLInlinerPass::ID = 0;
static RegisterPass<OpenCLInlinerPass> X("OpenCLInliner",
                                         "OpenCL Inliner Pass");

namespace clspv {
ModulePass *createOpenCLInlinerPass() { return new OpenCLInlinerPass(); }
} // namespace clspv

bool OpenCLInlinerPass::runOnModule(Module &M) {
  StringRef FuncNames[] = {"_Z13get_global_idj",     "_Z14get_local_sizej",
                           "_Z12get_local_idj",      "_Z14get_num_groupsj",
                           "_Z12get_group_idj",      "_Z15get_global_sizej",
                           "_Z17get_global_offsetj", "_Z12get_work_dimj"};
  bool changed = false;

  for (StringRef FuncName : FuncNames) {
    if (Function *F = M.getFunction(FuncName)) {
      SmallVector<CallInst *, 4> Calls;

      // Walk the users of the function.
      for (User *U : F->users()) {
        // Find only the calls to the function.
        if (CallInst *CI = dyn_cast<CallInst>(U)) {
          // Check if the call instruction is using a constant argument.
          if (isa<Constant>(CI->getArgOperand(0))) {
            // We found a function we want to inline!
            Calls.push_back(CI);
          }
        }
      }

      for (CallInst *CI : Calls) {
        InlineFunctionInfo info;
        changed |= InlineFunction(CI, info);
      }

      // If we inlined all the calls to the function, remove it.
      if (0 == F->getNumUses()) {
        F->eraseFromParent();
      }
    }
  }

  return changed;
}
