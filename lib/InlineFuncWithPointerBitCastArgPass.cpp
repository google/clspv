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

#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "InlineFuncWithPointerBitCastArgPass.h"
#include "Types.h"

using namespace llvm;

#define DEBUG_TYPE "inlinefuncwithpointerbitcastarg"

PreservedAnalyses
clspv::InlineFuncWithPointerBitCastArgPass::run(Module &M,
                                                ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  // Loop through our inline pass until they stop changing thing.
  bool changed = true;
  while (changed) {
    changed &= InlineFunctions(M);
  }

  return PA;
}

bool clspv::InlineFuncWithPointerBitCastArgPass::InlineFunctions(Module &M) {
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
                  // Fall-through
                case Instruction::PHI:
                  // If we previously checked this phi...
                  if (0 < CheckedPhis.count(Inst)) {
                    // ... then we don't need to check it again!
                    break;
                  }

                  CheckedPhis.insert(Inst);
                  // Fall-through
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

  // Check if any calls need inlined due to implicit pointer casts from opaque
  // pointers.
  DenseMap<Value *, Type *> type_cache;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        // All implicit casts of interest will be based on GEPs. There are two
        // scenarios:
        // 1. The GEP itself is the cast (e.g. source type doesn't
        //    match the inferred input type).
        // 2. The cast occurs through the call instruction (e.g. the inferred
        //    argument type doesn't match the GEP result element type).
        auto *gep = dyn_cast<GetElementPtrInst>(&I);
        if (!gep)
          continue;

        const auto *source_inferred_ty = clspv::InferType(
            gep->getPointerOperand(), M.getContext(), &type_cache);
        const auto *source_ele_ty = gep->getSourceElementType();
        const auto *result_ele_ty = gep->getResultElementType();
        bool add_all = source_inferred_ty && source_ele_ty &&
                       source_inferred_ty != source_ele_ty;
        SmallVector<std::pair<User *, unsigned>, 8> to_check;
        for (auto &use : gep->uses()) {
          to_check.push_back(std::make_pair(use.getUser(), use.getOperandNo()));
        }
        SmallSet<User *, 8> checked_phis;
        while (!to_check.empty()) {
          auto *user = to_check.back().first;
          auto operand = to_check.back().second;
          to_check.pop_back();

          if (auto *inst = dyn_cast<Instruction>(user)) {
            switch (inst->getOpcode()) {
            default:
              break;
            case Instruction::Call: {
              auto *call = cast<CallInst>(inst);
              if (add_all) {
                WorkList.insert(call);
              } else {
                const auto *arg_ty =
                    clspv::InferType(call->getCalledFunction()->getArg(operand),
                                     M.getContext(), &type_cache);
                if (arg_ty != result_ele_ty) {
                  WorkList.insert(call);
                }
              }
              break;
            }
            case Instruction::PHI:
              if (checked_phis.count(user))
                break;
              checked_phis.insert(user);
              for (auto &use : user->uses()) {
                to_check.push_back(
                    std::make_pair(use.getUser(), use.getOperandNo()));
              }
              break;
            case Instruction::GetElementPtr: {
              auto *next_gep = cast<GetElementPtrInst>(user);
              if (result_ele_ty &&
                  next_gep->getResultElementType() != result_ele_ty) {
                // TODO: this is an over-approximation, but it's easier to not
                // worry about phis.
                add_all = true;
              }
              for (auto &use : user->uses()) {
                to_check.push_back(
                    std::make_pair(use.getUser(), use.getOperandNo()));
              }
              break;
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
    // Disable generation of lifetime intrinsic.
    Changed |= InlineFunction(*Call, IFI, nullptr, false).isSuccess();
  }

  return Changed;
}
