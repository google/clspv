// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_REWRITE_INSERTS_PASS_H
#define _CLSPV_LIB_REWRITE_INSERTS_PASS_H

namespace clspv {
struct RewriteInsertsPass : llvm::PassInfoMixin<RewriteInsertsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  using InsertionVector = llvm::SmallVector<llvm::Instruction *, 4>;

  // Replaces chains of insertions that cover the entire value.
  // Such a change always reduces the number of instructions, so
  // we always perform these.  Returns true if the module was modified.
  bool ReplaceCompleteInsertionChains(llvm::Module &M);

  // Replaces all InsertValue instructions, even if they aren't part
  // of a complete insetion chain.  Returns true if the module was modified.
  bool ReplacePartialInsertions(llvm::Module &M);

  // Load |values| and |chain| with the members of the struct value produced
  // by a chain of InsertValue instructions ending with |iv|, and following
  // the aggregate operand.  Return the start of the chain: the aggregate
  // value which is not an InsertValue instruction, or an InsertValue
  // instruction which inserts a component that is replaced later in the
  // chain.  The |values| vector will match the order of struct members and
  // is initialized to all nullptr members.  The |chain| vector will list
  // the chain of InsertValue instructions, listed in the order we discover
  // them, e.g. begining with |iv|.
  llvm::Value *LoadValuesEndingWithInsertion(llvm::InsertValueInst *iv,
                                             std::vector<llvm::Value *> *values,
                                             InsertionVector *chain);

  // Returns the number of elements in the struct or array.
  unsigned GetNumElements(llvm::Type *type);

  // If this is the tail of a chain of InsertValueInst instructions
  // that covers the entire composite, then return a small vector
  // containing the insertion instructions, in member order.
  // Otherwise returns nullptr.
  InsertionVector *CompleteInsertionChain(llvm::InsertValueInst *iv);

  // If this is the tail of a chain of InsertElementInst instructions
  // that covers the entire vector, then return a small vector
  // containing the insertion instructions, in member order.
  // Otherwise returns nullptr.  Only handle insertions into vectors.
  InsertionVector *CompleteInsertionChain(llvm::InsertElementInst *ie);

  // Return the name for the wrap function for the given type.
  std::string &WrapFunctionNameForType(llvm::Type *type);

  // Get or create the composite construct function definition.
  llvm::Function *GetConstructFunction(llvm::Module &M,
                                       llvm::Type *constructed_type);

  // Maps a loaded type to the name of the wrap function for that type.
  llvm::DenseMap<llvm::Type *, std::string> function_for_type_;
};
} // namespace clspv

#endif // _CLSPV_LIB_REWRITE_INSERTS_PASS_H
