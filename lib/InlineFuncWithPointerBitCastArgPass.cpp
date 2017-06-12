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

#include <llvm/ADT/UniqueVector.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/Utils/Cloning.h>

using namespace llvm;

#define DEBUG_TYPE "inlinefuncwithpointerbitcastarg"

namespace {
struct InlineFuncWithPointerBitCastArgPass : public ModulePass {
  static char ID;
  InlineFuncWithPointerBitCastArgPass() : ModulePass(ID) {}

  bool InlineFunctions(Module &M);
  bool runOnModule(Module &M) override;
};
}

char InlineFuncWithPointerBitCastArgPass::ID = 0;
static RegisterPass<InlineFuncWithPointerBitCastArgPass>
    X("InlineFuncWithPointerBitCastArg",
      "Inline Function with Pointer Bitcast Argument Pass");

namespace clspv {
llvm::ModulePass *createInlineFuncWithPointerBitCastArgPass() {
  return new InlineFuncWithPointerBitCastArgPass();
}
}

bool InlineFuncWithPointerBitCastArgPass::runOnModule(Module &M) {
  bool Changed = false;

  // Loop through our inline pass until they stop changing thing.
  for (bool localChanged = true; localChanged; Changed |= localChanged) {
    localChanged = false;

    localChanged |= InlineFunctions(M);
  }

  return Changed;
}

bool InlineFuncWithPointerBitCastArgPass::InlineFunctions(Module &M) {
  bool Changed = false;

  UniqueVector<CallInst *> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a bitcast instruction...
        if (auto Bitcast = dyn_cast<BitCastInst>(&I)) {
          // ... which is a pointer bitcast...
          if (Bitcast->getType()->isPointerTy()) {
            // ... we need to recursively check all the users to find any call
            // instructions.
            SmallVector<Value *, 8> ToChecks(Bitcast->user_begin(),
                                             Bitcast->user_end());
            SmallSet<Instruction *, 8> CheckedPhis;

            while (!ToChecks.empty()) {
              auto ToCheck = ToChecks.back();
              ToChecks.pop_back();

              if (auto Inst = dyn_cast<Instruction>(ToCheck)) {
                switch (Inst->getOpcode()) {
                default:
                  break;
                case Instruction::Call:
                  // We found a call instruction which needs to be inlined!
                  WorkList.insert(cast<CallInst>(Inst));
                case Instruction::PHI:
                  // If we previously checked this phi...
                  if (0 < CheckedPhis.count(Inst)) {
                    // ... then we don't need to check it again!
                    break;
                  }

                  CheckedPhis.insert(Inst);
                case Instruction::GetElementPtr:
                case Instruction::BitCast:
                  // These pointer users could have a call user, and so we
                  // must check them also.
                  ToChecks.append(Inst->user_begin(), Inst->user_end());
                }
              }
            }
          }
        }
      }
    }
  }

  // TODO: Need to check pointer bitcast, stored to an alloca, then loaded,
  // then passed into a function?

  for (CallInst *Call : WorkList) {
    InlineFunctionInfo IFI;
    CallSite CS(Call);
    // Disable generation of lifetime intrinsic.
    Changed |= InlineFunction(CS, IFI, nullptr, false);
  }

  return Changed;
}
