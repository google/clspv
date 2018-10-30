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

#include <deque>

#include "llvm/ADT/DenseSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

using namespace llvm;

#define DEBUG_TYPE "reorderbbs"

namespace {
struct ReorderBasicBlocksPass : public FunctionPass {
  static char ID;
  ReorderBasicBlocksPass() : FunctionPass(ID) {}

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
  }

  bool runOnFunction(Function &F) override;

private:
  // Produce structured sorting from |block| into |order|.
  void StructuredOrder(BasicBlock *block, const LoopInfo &LI,
                       std::deque<BasicBlock *> *order,
                       DenseSet<BasicBlock *> *visited);
};
} // namespace

char ReorderBasicBlocksPass::ID = 0;
static RegisterPass<ReorderBasicBlocksPass> X("ReorderBasicBlocks",
                                              "Reorder Basic Blocks Pass");

namespace clspv {
FunctionPass *createReorderBasicBlocksPass() {
  return new ReorderBasicBlocksPass();
}
} // namespace clspv

void ReorderBasicBlocksPass::StructuredOrder(BasicBlock *block,
                                             const LoopInfo &LI,
                                             std::deque<BasicBlock *> *order,
                                             DenseSet<BasicBlock *> *visited) {
  if (!visited->insert(block).second)
    return;

  // Identify the merge and continue blocks for special treatment.
  const auto *terminator = dyn_cast<TerminatorInst>(block->getTerminator());
  BasicBlock *continue_block = nullptr;
  BasicBlock *merge_block = nullptr;
  if (LI.isLoopHeader(block)) {
    Loop *loop = LI.getLoopFor(block);
    merge_block = loop->getExitBlock();

    if (loop->isLoopLatch(block)) {
      continue_block = block;
    } else {
      DominatorTree &DT = getAnalysis<DominatorTreeWrapperPass>().getDomTree();
      auto *header = loop->getHeader();
      auto *latch = loop->getLoopLatch();
      for (auto *bb : loop->blocks()) {
        if (bb == header)
          continue;

        if (DT.dominates(bb, latch))
          continue_block = bb;
      }
    }
    assert(continue_block && merge_block && "Bad loop");
  } else if (terminator->getNumSuccessors() > 1) {
    bool has_back_edge = false;

    for (unsigned i = 0; i < terminator->getNumSuccessors(); ++i) {
      if (LI.isLoopHeader(terminator->getSuccessor(i)))
        has_back_edge = true;
    }

    if (!has_back_edge) {
      merge_block = terminator->getSuccessor(1);
    }
  }

  // Traverse merge and continue first.
  if (merge_block) {
    StructuredOrder(merge_block, LI, order, visited);
    if (continue_block)
      StructuredOrder(continue_block, LI, order, visited);
  }
  for (unsigned i = 0; i < terminator->getNumSuccessors(); ++i) {
    auto *successor = terminator->getSuccessor(i);
    if (successor != merge_block && successor != continue_block)
      StructuredOrder(successor, LI, order, visited);
  }

  order->push_front(block);
}

bool ReorderBasicBlocksPass::runOnFunction(Function &F) {
  bool Changed = false;

  if (clspv::Option::HackBlockOrder()) {
    // Order basic blocks according to structured order. Structured subgraphs
    // will be ordered contiguously within the binary.
    //
    // Assumes CFG has been structurized.
    const LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>(F).getLoopInfo();
    std::deque<BasicBlock *> order;
    DenseSet<BasicBlock *> visited;
    StructuredOrder(&*F.begin(), LI, &order, &visited);

    for (unsigned i = 1; i != order.size(); ++i) {
      order[i]->moveAfter(order[i - 1]);
    }
  } else {
    // spirv-val wants the order of basic blocks to follow dominance relation.
    // Reorder basic blocks according to dominance relation.
    DominatorTree &DT = getAnalysis<DominatorTreeWrapperPass>().getDomTree();

    // Traverse dominator tree using depth first order. Reorder basic blocks
    // according to dominance relation.
    for (auto II = df_begin(DT.getRootNode()), IE = df_end(DT.getRootNode());
         II != IE; ++II) {
      BasicBlock *BB = (*II)->getBlock();
      BB->moveAfter(&F.back());
    }
  }

  return Changed;
}
