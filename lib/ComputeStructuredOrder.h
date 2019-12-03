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

#include <deque>

#include "llvm/ADT/DenseSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Dominators.h"

namespace clspv {

// Produce structured sorting from |block| into |order|.
//
// This order has the following properties:
// * dominators come before all blocks they dominate
// * a merge block follows all blocks that are in control constructs of the
// associated header
// * blocks in a loop construct precede the blocks in the associated continue
// construct
// * no interleaving; blocks in one construct A are mixed with blocks in
// another construct B only if one is nested inside the other (without loss
// of generality, A's header dominates all blocks in B, and all B's blocks
// appear contiguously within A's blocks)
void ComputeStructuredOrder(llvm::BasicBlock *block, llvm::DominatorTree *DT,
                            const llvm::LoopInfo &LI,
                            std::deque<llvm::BasicBlock *> *order,
                            llvm::DenseSet<llvm::BasicBlock *> *visited);
} // namespace clspv
