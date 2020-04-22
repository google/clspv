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

#include "ComputeStructuredOrder.h"

using namespace clspv;
using namespace llvm;

void clspv::ComputeStructuredOrder(BasicBlock *block, DominatorTree *DT,
                                   const LoopInfo &LI,
                                   std::deque<BasicBlock *> *order,
                                   DenseSet<BasicBlock *> *visited) {
  if (!visited->insert(block).second)
    return;

  // Identify the merge and continue blocks for special treatment.
  const auto *terminator = block->getTerminator();
  BasicBlock *continue_block = nullptr;
  BasicBlock *merge_block = nullptr;
  if (LI.isLoopHeader(block)) {
    Loop *loop = LI.getLoopFor(block);
    merge_block = loop->getExitBlock();

    if (loop->isLoopLatch(block)) {
      // The header is also the latch (i.e. a single block loop).
      continue_block = block;
    } else {
      // The continue block satisfies the following conditions:
      // 1. Is dominated by the header (true by construction at this point).
      // 2. Dominates the latch block.
      // We can assume the loop has multiple blocks since the single block loop
      // is handled above. By construction the header always dominates the
      // latch block, so we exclude that case specifically.
      auto *header = loop->getHeader();
      auto *latch = loop->getLoopLatch();
      for (auto *bb : loop->blocks()) {
        if (bb == header)
          continue;

        // Several block might dominate the latch, we can pick any.
        if (DT->dominates(bb, latch))
          continue_block = bb;
      }
    }
    // At least the latch dominates itself so we will always find a continue
    // block.
    assert(continue_block && merge_block && "Bad loop");
  } else if (terminator->getNumSuccessors() > 1) {
    // This is potentially a selection case, but it could also be a conditional
    // branch with one arm back to the loop header, which would make this block
    // the latch block.
    bool has_back_edge = false;

    for (unsigned i = 0; i < terminator->getNumSuccessors(); ++i) {
      if (LI.isLoopHeader(terminator->getSuccessor(i)))
        has_back_edge = true;
    }

    if (!has_back_edge) {
      // The cfg structurizer generates a cfg where the true branch goes into
      // the then/else region and the false branch skips the region. Therefore,
      // we use the false branch here as the merge.
      merge_block = terminator->getSuccessor(1);
    }
  }

  // Traverse merge and continue first.
  if (merge_block) {
    ComputeStructuredOrder(merge_block, DT, LI, order, visited);
    if (continue_block)
      ComputeStructuredOrder(continue_block, DT, LI, order, visited);
  }
  for (unsigned i = 0; i < terminator->getNumSuccessors(); ++i) {
    auto *successor = terminator->getSuccessor(i);
    if (successor != merge_block && successor != continue_block)
      ComputeStructuredOrder(successor, DT, LI, order, visited);
  }

  order->push_front(block);
}
