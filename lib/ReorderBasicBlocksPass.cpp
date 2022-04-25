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

#include "ComputeStructuredOrder.h"
#include "ReorderBasicBlocksPass.h"

using namespace llvm;

#define DEBUG_TYPE "reorderbbs"

PreservedAnalyses
clspv::ReorderBasicBlocksPass::run(Function &F, FunctionAnalysisManager &FAM) {
  auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
  if (clspv::Option::HackBlockOrder()) {
    // Order basic blocks according to structured order. Structured subgraphs
    // will be ordered contiguously within the binary.
    //
    // Assumes CFG has been structurized.
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    std::deque<BasicBlock *> order;
    DenseSet<BasicBlock *> visited;
    clspv::ComputeStructuredOrder(&*F.begin(), &DT, LI, &order, &visited);

    for (unsigned i = 1; i != order.size(); ++i) {
      order[i]->moveAfter(order[i - 1]);
    }
  } else {
    // spirv-val wants the order of basic blocks to follow dominance relation.
    // Reorder basic blocks according to dominance relation.

    // Traverse dominator tree using depth first order. Reorder basic blocks
    // according to dominance relation.
    for (auto II = df_begin(DT.getRootNode()), IE = df_end(DT.getRootNode());
         II != IE; ++II) {
      BasicBlock *BB = (*II)->getBlock();
      BB->moveAfter(&F.back());
    }
  }

  PreservedAnalyses PA;
  return PA;
}
