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

#include "llvm/ADT/DenseSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "FixupStructuredCFGPass.h"

using namespace llvm;

PreservedAnalyses
clspv::FixupStructuredCFGPass::run(Function &F, FunctionAnalysisManager &FAM) {
  // Assumes CFG has been structurized.
  isolateContinue(F, FAM);
  // Run after isolateContinue since this can invalidate loop info.
  breakConditionalHeader(F, FAM);

  PreservedAnalyses PA;
  return PA;
}

void clspv::FixupStructuredCFGPass::breakConditionalHeader(
    Function &F, FunctionAnalysisManager &FAM) {
  auto &LI = FAM.getResult<LoopAnalysis>(F);

  std::vector<BasicBlock *> blocks;
  blocks.reserve(F.size());
  for (auto &BB : F) {
    blocks.push_back(&BB);
  }

  // Loop for loop headers that are terminated by a conditional branch with both
  // edges entering the body of the loop. In such a case, split the header so
  // that the conditional branch occurs in the body of the loop.
  for (auto *BB : blocks) {
    if (!LI.isLoopHeader(BB))
      continue;

    auto *terminator = dyn_cast_or_null<BranchInst>(BB->getTerminator());
    if (!terminator || !terminator->isConditional())
      continue;

    auto *loop = LI.getLoopFor(BB);
    auto *latch = loop->getLoopLatch();
    auto *exit = loop->getUniqueExitBlock();

    auto *succ1 = terminator->getSuccessor(0);
    auto *succ2 = terminator->getSuccessor(1);
    bool succ1_in_body = succ1 != latch && succ1 != exit;
    bool succ2_in_body = succ2 != latch && succ2 != exit;

    if (succ1_in_body && succ2_in_body) {
      BB->splitBasicBlockBefore(terminator);
    }
  }
}

void clspv::FixupStructuredCFGPass::isolateContinue(
    Function &F, FunctionAnalysisManager &FAM) {
  auto &LI = FAM.getResult<LoopAnalysis>(F);

  SmallVector<Loop *, 16> loops;
  for (auto loop : LI) {
    loops.push_back(loop);
  }

  DenseSet<Loop *> visited;
  while (!loops.empty()) {
    auto loop = loops.back();
    // Process subloops first.
    if (!loop->getSubLoops().empty() && !visited.count(loop)) {
      visited.insert(loop);
      for (auto subloop : loop->getSubLoops()) {
        loops.push_back(subloop);
      }
      continue;
    }

    loops.pop_back();
    // Look for cases where the merge block (unique exit) of the inner loop is
    // the same block as the outer loop's continue target (loop latch).
    if (auto parent = loop->getParentLoop()) {
      if (auto exit_block = loop->getUniqueExitBlock()) {
        if (exit_block == parent->getLoopLatch()) {
          // Create a new basic block to act as the merge of the loop.
          auto new_exit =
              BasicBlock::Create(F.getContext(), "", &F, exit_block);
          BranchInst::Create(exit_block, new_exit);
          parent->addBlockEntry(new_exit);

          // Collect the exit's predecessors from within the loop.
          SmallVector<BasicBlock *, 4> loop_preds;
          for (auto iter = pred_begin(exit_block); iter != pred_end(exit_block);
               ++iter) {
            if (loop->getBlocksSet().count(*iter)) {
              loop_preds.push_back(*iter);
            }
          }
          // Split the phi nodes so that all predecessors from within the loop
          // are part of a new phi in the new exit block.
          for (auto iter = exit_block->begin();
               &*iter != exit_block->getFirstNonPHI(); ++iter) {
            PHINode *phi = cast<PHINode>(&*iter);
            SmallVector<Value *, 4> phi_values;
            for (auto pred : loop_preds) {
              auto inc = phi->getIncomingValueForBlock(&*pred);
              if (inc) {
                phi_values.push_back(inc);
              }
            }
            assert(phi_values.size() == loop_preds.size());
            if (phi_values.size() == 1) {
              // Special case: don't bother creating a single input phi.
              // Instead, add the single value as an incoming value for the new
              // exit.
              phi->addIncoming(phi_values[0], new_exit);
            } else if (!phi_values.empty()) {
              auto new_phi = PHINode::Create(phi->getType(), phi_values.size(),
                                             "", new_exit->getTerminator());
              for (size_t i = 0; i < phi_values.size(); ++i) {
                new_phi->addIncoming(phi_values[i], loop_preds[i]);
              }
              phi->addIncoming(new_phi, new_exit);
            }
          }
          // Remove the loop predecessors from the old exit block.
          for (auto pred : loop_preds) {
            exit_block->removePredecessor(&*pred);
            pred->getTerminator()->replaceUsesOfWith(exit_block, new_exit);
          }
        }
      }
    }
  }
}
