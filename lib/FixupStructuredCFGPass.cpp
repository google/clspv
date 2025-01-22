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
#include "llvm/IR/Constants.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "FixupStructuredCFGPass.h"

using namespace llvm;

PreservedAnalyses
clspv::FixupStructuredCFGPass::run(Function &F, FunctionAnalysisManager &FAM) {
  // Assumes CFG has been structurized.
  isolateContinue(F, FAM);
  isolateConvergentLatch(F, FAM);
  breakConditionalHeader(F, FAM);

  removeUndefPHI(F);

  PreservedAnalyses PA;
  return PA;
}

void clspv::FixupStructuredCFGPass::removeUndefPHI(Function &F) {
  SmallVector<PHINode *> ToBeDeleted;
  DenseMap<PHINode *, SmallVector<PHINode *>> dict;
  for (auto &BB : F) {
    for (auto &I : BB) {
      if (auto phi = dyn_cast<PHINode>(&I)) {
        if (!phi->getType()->isPointerTy()) {
          continue;
        }
        bool phiIsUndef = true;
        for (unsigned i = 0; i < phi->getNumIncomingValues(); i++) {
          auto Val = phi->getIncomingValue(i);
          if (auto phi2 = dyn_cast<PHINode>(Val)) {
            for (unsigned j = 0; j < phi2->getNumIncomingValues(); j++) {
              auto Val2 = phi2->getIncomingValue(i);
              if (auto phi3 = dyn_cast<PHINode>(Val2)) {
                if (phi3 != phi) {
                  phiIsUndef = false;
                }
              } else if (!isa<UndefValue>(Val2)) {
                phiIsUndef = false;
              }
            }
          } else if (!isa<UndefValue>(Val)) {
            phiIsUndef = false;
          }
        }
        if (!phiIsUndef) {
          continue;
        }
        phi->replaceAllUsesWith(UndefValue::get(phi->getType()));
        ToBeDeleted.push_back(phi);
      }
    }
  }
  for (auto phi : ToBeDeleted) {
    phi->eraseFromParent();
  }
}

void clspv::FixupStructuredCFGPass::isolateConvergentLatch(
    Function &F, FunctionAnalysisManager &FAM) {
  auto &LI = FAM.getResult<LoopAnalysis>(F);

  std::vector<BasicBlock *> blocks;
  blocks.reserve(F.size());
  for (auto &BB : F) {
    blocks.push_back(&BB);
  }

  for (auto *BB : blocks) {
    if (!LI.isLoopHeader(BB))
      continue;

    auto *loop = LI.getLoopFor(BB);
    auto *latch = loop->getLoopLatch();
    // Skip single block loops.
    if (!latch || latch == BB) {
      continue;
    }

    // Latch needs two predecessors.
    if (!latch->hasNPredecessors(2)) {
      continue;
    }

    // Header is a conditional branch.
    auto header_terminator = dyn_cast_or_null<BranchInst>(BB->getTerminator());
    if (!header_terminator || !header_terminator->isConditional()) {
      continue;
    }

    // One edge jumps to the continue target.
    if (header_terminator->getSuccessor(0) != latch &&
        header_terminator->getSuccessor(1) != latch) {
      continue;
    }

    // The continue contains a convergent call.
    bool has_convergent_call = false;
    for (auto &inst : *latch) {
      if (auto *call = dyn_cast<CallInst>(&inst)) {
        if (call->hasFnAttr(Attribute::Convergent)) {
          has_convergent_call = true;
          break;
        }
      }
    }
    if (!has_convergent_call) {
      continue;
    }

    auto *latch_terminator =
        dyn_cast_or_null<BranchInst>(latch->getTerminator());
    if (!latch_terminator)
      continue;

    // Break the latch such that it is a single-entry single-exit block.
    // This will force later transforms in this fixup to break the loop header
    // which puts the whole loop body as a selection.
    if (latch_terminator->isConditional()) {
      // Safety valve: if this is not an exiting block then the loop is not
      // structured as expected.
      if (!loop->isLoopExiting(latch)) {
        continue;
      }

      // Conditional branch case: one edge back to header and one out of the
      // loop. Transformed into one edge out of the loop and one edge to the new
      // continue and thence to the header.
      auto new_latch =
          BasicBlock::Create(F.getContext(), "", &F, latch->getNextNode());
      BranchInst::Create(BB, new_latch);
      loop->addBlockEntry(new_latch);

      const auto idx = latch_terminator->getSuccessor(0) == BB ? 0 : 1;
      latch_terminator->setSuccessor(idx, new_latch);

      // Update phis to use the new basic block.
      for (auto iter = BB->begin(); &*iter != BB->getFirstNonPHI(); ++iter) {
        PHINode *phi = cast<PHINode>(&*iter);
        phi->replaceIncomingBlockWith(latch, new_latch);
      }
    } else {
      // Simple case: just split the block.
      auto new_block = latch->splitBasicBlockBefore(latch_terminator);
      loop->addBlockEntry(new_block);
    }
  }
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
      auto new_block = BB->splitBasicBlockBefore(terminator);
      loop->addBlockEntry(new_block);
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
              auto new_phi =
                  PHINode::Create(phi->getType(), phi_values.size(), "",
                                  new_exit->getTerminator()->getIterator());
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
