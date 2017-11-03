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

#include <string>

#include <llvm/ADT/DenseMap.h>
#include <llvm/ADT/SmallVector.h>
#include <llvm/IR/Attributes.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>

using namespace llvm;
using std::string;

#define DEBUG_TYPE "collapsecompositeinserts"


namespace {

const char* kCompositeConstructFunctionPrefix = "clspv.composite_construct.";

class RewriteInsertsPass : public ModulePass {
 public:
  static char ID;
  RewriteInsertsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

 private:
   using InsertionVector = SmallVector<InsertValueInst *, 4>;

   // If this is the tail of a chain of InsertValueInst instructions
   // that covers the entire composite, then return a small vector
   // containing the insertion instructions, in member order.
   // Otherwise returns nullptr.  Only handle insertions into structs,
   // not into arrays.
   InsertionVector *CompleteInsertionChain(InsertValueInst *iv) {
     if (iv->getNumIndices() == 1) {
       if (auto *structTy = dyn_cast<StructType>(iv->getType())) {
         auto numElems = structTy->getNumElements();
         // Only handle single-index insertions.
         unsigned index = iv->getIndices()[0];
         if (index + 1u != numElems) {
           // Not the last in the chain.
           return nullptr;
         }
         InsertionVector candidates(numElems, nullptr);
         for (unsigned i = index;
              iv->getNumIndices() == 1 && i == iv->getIndices()[0]; --i) {
           // iv inserts the i'th member
           candidates[i] = iv;

           if (i == 0) {
             // We're done!
             return new InsertionVector(candidates);
           }

           if (InsertValueInst *agg =
                   dyn_cast<InsertValueInst>(iv->getAggregateOperand())) {
             iv = agg;
           } else {
             // The chain is broken.
             break;
           }
         }
       }
     }
     return nullptr;
   }

   // Return the name for the wrap function for the given type.
   string &WrapFunctionNameForType(Type *type) {
     auto where = function_for_type_.find(type);
     if (where == function_for_type_.end()) {
       // Insert it.
       auto &result = function_for_type_[type] =
           string(kCompositeConstructFunctionPrefix) +
           std::to_string(function_for_type_.size());
       return result;
     } else {
       return where->second;
     }
   }

   // Maps a loaded type to the name of the wrap function for that type.
   DenseMap<Type *, string> function_for_type_;
};
} // namespace

char RewriteInsertsPass::ID = 0;
static RegisterPass<RewriteInsertsPass>
    X("RewriteInserts",
      "Rewrite chains of insertvalue to as composite-construction");

namespace clspv {
llvm::ModulePass *createRewriteInsertsPass() {
  return new RewriteInsertsPass();
}
} // namespace clspv

bool RewriteInsertsPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<InsertionVector *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (InsertValueInst *iv = dyn_cast<InsertValueInst>(&I)) {
          if (InsertionVector *insertions = CompleteInsertionChain(iv)) {
            WorkList.push_back(insertions);
          }
        }
      }
    }
  }

  if (WorkList.size() == 0) {
    return Changed;
  }

  for (InsertionVector *insertions : WorkList) {
    Changed = true;

    // Gather the member values and types.
    SmallVector<Value*, 4> values;
    SmallVector<Type*, 4> types;
    for (InsertValueInst* insert : *insertions) {
      Value* value = insert->getInsertedValueOperand();
      values.push_back(value);
      types.push_back(value->getType());
    }

    Type* resultTy = insertions->back()->getType();

    // Get or create the composite construct function definition.
    const string& fn_name = WrapFunctionNameForType(resultTy);
    Function* fn = M.getFunction(fn_name);
    if (!fn) {
      // Make the function.
      FunctionType* fnTy = FunctionType::get(resultTy, types, false);
      auto fn_constant = M.getOrInsertFunction(fn_name, fnTy);
      fn = cast<Function>(fn_constant);
      fn->addFnAttr(Attribute::ReadOnly);
      fn->addFnAttr(Attribute::ReadNone);
    }

    // Replace the chain.
    auto call = CallInst::Create(fn, values);
    call->insertAfter(insertions->back());
    insertions->back()->replaceAllUsesWith(call);

    // Remove the insertions if we can.  Go from the tail back to
    // the head, since the tail uses the previous insertion, etc.
    for (auto iter = insertions->rbegin(), end = insertions->rend();
         iter != end; ++iter) {
      InsertValueInst *insertion = *iter;
      if (!insertion->hasNUsesOrMore(1)) {
        insertion->eraseFromParent();
      }
    }

    delete insertions;
  }

  return Changed;
}
