// Copyright 2018 The Clspv Authors. All rights reserved.
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

#include <vector>

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "ScalarizePass.h"

using namespace llvm;

PreservedAnalyses clspv::ScalarizePass::run(Module &M,
                                            ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *phi = dyn_cast<PHINode>(&I)) {
          if (clspv::Option::HackPhis() && phi->getType()->isStructTy()) {
            ScalarizePhi(phi);
          }
        }
      }
    }
  }

  for (auto *phi : to_delete_)
    phi->eraseFromParent();

  return PA;
}

Value *clspv::ScalarizePass::ScalarizePhi(PHINode *phi) {
  // Break down all the struct elements of the phi into individual elements and
  // create new phis for them. Recombine the new phis into a single struct
  // after the phi instructions.
  if (!phi->getType()->isStructTy())
    return phi;

  // Cache the insertion location now. If we break down subtypes, we don't want
  // to insert uses before definitions.
  Instruction *where = phi->getParent()->getFirstNonPHI();
  const auto num_incoming_values = phi->getNumIncomingValues();
  unsigned type_index = 0;
  SmallVector<Value *, 16> replacements;
  for (auto *subtype : phi->getType()->subtypes()) {
    PHINode *replacement =
        PHINode::Create(subtype, num_incoming_values, "", phi);
    for (unsigned i = 0; i != num_incoming_values; ++i) {
      auto *incoming_block = phi->getIncomingBlock(i);
      auto *incoming_value = phi->getIncomingValue(i);

      Value *extracted_value = nullptr;
      if (auto *constant = dyn_cast<Constant>(incoming_value)) {
        extracted_value = constant->getAggregateElement(type_index);
      } else {
        // Extract the value just before the incoming block's branch.
        extracted_value = ExtractValueInst::Create(
            incoming_value, {type_index}, "", incoming_block->getTerminator());
      }
      replacement->addIncoming(extracted_value, incoming_block);
    }
    // Recursively break down subtype structs.
    replacements.push_back(ScalarizePhi(replacement));
    ++type_index;
  }

  // Regenerate the struct just after the phi instructions. Update the
  // insertion location to aid RewriteInsertsPass.
  Value *prev = Constant::getNullValue(phi->getType());
  for (unsigned i = 0; i != replacements.size(); ++i) {
    auto insert =
        InsertValueInst::Create(prev, replacements[i], {i}, "", where);
    prev = insert;
  }

  // Replace the struct phi
  phi->replaceAllUsesWith(prev);
  to_delete_.push_back(phi);

  return prev;
}
