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

#include <llvm/IR/Dominators.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;

#define DEBUG_TYPE "reorderbbs"

namespace {
struct ReorderBasicBlocksPass : public FunctionPass {
  static char ID;
  ReorderBasicBlocksPass() : FunctionPass(ID) {}

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<DominatorTreeWrapperPass>();
  }

  bool runOnFunction(Function &F) override;
};
}

char ReorderBasicBlocksPass::ID = 0;
static RegisterPass<ReorderBasicBlocksPass> X("ReorderBasicBlocks",
                                              "Reorder Basic Blocks Pass");

namespace clspv {
FunctionPass *createReorderBasicBlocksPass() {
  return new ReorderBasicBlocksPass();
}
}

bool ReorderBasicBlocksPass::runOnFunction(Function &F) {
  bool Changed = false;

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

  return Changed;
}
