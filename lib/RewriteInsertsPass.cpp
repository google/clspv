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
#include <utility>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "Passes.h"

using namespace llvm;
using std::string;

#define DEBUG_TYPE "rewriteinserts"

namespace {

const char *kCompositeConstructFunctionPrefix = "clspv.composite_construct.";

class RewriteInsertsPass : public ModulePass {
public:
  static char ID;
  RewriteInsertsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  using InsertionVector = SmallVector<Instruction *, 4>;

  // Replaces chains of insertions that cover the entire value.
  // Such a change always reduces the number of instructions, so
  // we always perform these.  Returns true if the module was modified.
  bool ReplaceCompleteInsertionChains(Module &M);

  // Replaces all InsertValue instructions, even if they aren't part
  // of a complete insetion chain.  Returns true if the module was modified.
  bool ReplacePartialInsertions(Module &M);

  // Load |values| and |chain| with the members of the struct value produced
  // by a chain of InsertValue instructions ending with |iv|, and following
  // the aggregate operand.  Return the start of the chain: the aggregate
  // value which is not an InsertValue instruction, or an InsertValue
  // instruction which inserts a component that is replaced later in the
  // chain.  The |values| vector will match the order of struct members and
  // is initialized to all nullptr members.  The |chain| vector will list
  // the chain of InsertValue instructions, listed in the order we discover
  // them, e.g. begining with |iv|.
  Value *LoadValuesEndingWithInsertion(InsertValueInst *iv,
                                       std::vector<Value *> *values,
                                       InsertionVector *chain) {
    auto *structTy = dyn_cast<StructType>(iv->getType());
    assert(structTy);
    if (!structTy)
      return nullptr;

    // Walk backward from the tail to an instruction we don't want to
    // replace.
    Value *frontier = iv;
    while (auto *insertion = dyn_cast<InsertValueInst>(frontier)) {
      chain->push_back(insertion);
      // Only handle single-index insertions.
      if (insertion->getNumIndices() == 1) {
        // Try to replace this one.

        unsigned index = insertion->getIndices()[0];
        assert(index < structTy->getNumElements());
        if ((*values)[index] != nullptr) {
          // We already have a value for this slot.  Stop now.
          break;
        }
        (*values)[index] = insertion->getInsertedValueOperand();
        frontier = insertion->getAggregateOperand();
      } else {
        break;
      }
    }
    return frontier;
  }

  // Returns the number of elements in the struct or array.
  unsigned GetNumElements(Type *type) {
    // CompositeType doesn't implement getNumElements(), but its inheritors
    // do.
    if (auto *struct_ty = dyn_cast<StructType>(type)) {
      return struct_ty->getNumElements();
    } else if (auto *array_ty = dyn_cast<ArrayType>(type)) {
      return array_ty->getNumElements();
    } else if (auto *vec_ty = dyn_cast<VectorType>(type)) {
      return vec_ty->getNumElements();
    }
    return 0;
  }

  // If this is the tail of a chain of InsertValueInst instructions
  // that covers the entire composite, then return a small vector
  // containing the insertion instructions, in member order.
  // Otherwise returns nullptr.
  InsertionVector *CompleteInsertionChain(InsertValueInst *iv) {
    if (iv->getNumIndices() == 1) {
      auto numElems = GetNumElements(iv->getType());
      if (numElems != 0) {
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

  // If this is the tail of a chain of InsertElementInst instructions
  // that covers the entire vector, then return a small vector
  // containing the insertion instructions, in member order.
  // Otherwise returns nullptr.  Only handle insertions into vectors.
  InsertionVector *CompleteInsertionChain(InsertElementInst *ie) {
    // Don't handle i8 vectors. Only <4 x i8> is supported and it is
    // translated as i32.  Only handle single-index insertions.
    if (auto vec_ty = dyn_cast<VectorType>(ie->getType())) {
      if (vec_ty->getElementType() == Type::getInt8Ty(ie->getContext())) {
        return nullptr;
      }
    }

    // Only handle single-index insertions.
    if (ie->getNumOperands() == 3) {
      auto numElems = GetNumElements(ie->getType());
      if (numElems != 0) {
        if (auto *const_value = dyn_cast<ConstantInt>(ie->getOperand(2))) {
          uint64_t index = const_value->getZExtValue();
          if (index + 1u != numElems) {
            // Not the last in the chain.
            return nullptr;
          }
          InsertionVector candidates(numElems, nullptr);
          Value *value = ie;
          uint64_t i = index;
          while (auto *insert = dyn_cast<InsertElementInst>(value)) {
            if (insert->getNumOperands() != 3)
              break;
            if (auto *index_const =
                    dyn_cast<ConstantInt>(insert->getOperand(2))) {
              if (i != index_const->getZExtValue())
                break;

              candidates[i] = insert;
              if (i == 0) {
                // We're done!
                return new InsertionVector(candidates);
              }

              value = insert->getOperand(0);
              --i;
            } else {
              break;
            }
          }
        } else {
          return nullptr;
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

  // Get or create the composite construct function definition.
  Function *GetConstructFunction(Module &M, Type *constructed_type) {
    // Get or create the composite construct function definition.
    const string &fn_name = WrapFunctionNameForType(constructed_type);
    Function *fn = M.getFunction(fn_name);
    if (!fn) {
      // Make the function.
      SmallVector<Type *, 16> elements;
      unsigned num_elements = GetNumElements(constructed_type);
      if (auto struct_ty = dyn_cast<StructType>(constructed_type)) {
        for (unsigned i = 0; i != num_elements; ++i)
          elements.push_back(struct_ty->getTypeAtIndex(i));
      } else if (isa<ArrayType>(constructed_type)) {
        elements.resize(num_elements, constructed_type->getArrayElementType());
      } else if (isa<VectorType>(constructed_type)) {
        elements.resize(num_elements,
                        cast<VectorType>(constructed_type)->getElementType());
      }
      FunctionType *fnTy = FunctionType::get(constructed_type, elements, false);
      auto fn_constant = M.getOrInsertFunction(fn_name, fnTy);
      fn = cast<Function>(fn_constant.getCallee());
      fn->addFnAttr(Attribute::ReadOnly);
    }
    return fn;
  }

  // Maps a loaded type to the name of the wrap function for that type.
  DenseMap<Type *, string> function_for_type_;
};
} // namespace

char RewriteInsertsPass::ID = 0;
INITIALIZE_PASS(RewriteInsertsPass, "RewriteInserts",
                "Rewrite chains of insertvalue to as composite-construction",
                false, false)

namespace clspv {
llvm::ModulePass *createRewriteInsertsPass() {
  return new RewriteInsertsPass();
}
} // namespace clspv

bool RewriteInsertsPass::runOnModule(Module &M) {
  bool Changed = ReplaceCompleteInsertionChains(M);

  if (clspv::Option::HackInserts()) {
    Changed |= ReplacePartialInsertions(M);
  }

  return Changed;
}

bool RewriteInsertsPass::ReplaceCompleteInsertionChains(Module &M) {
  bool Changed = false;

  SmallVector<InsertionVector *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (InsertValueInst *iv = dyn_cast<InsertValueInst>(&I)) {
          if (InsertionVector *insertions = CompleteInsertionChain(iv)) {
            WorkList.push_back(insertions);
          }
        } else if (InsertElementInst *ie = dyn_cast<InsertElementInst>(&I)) {
          if (InsertionVector *insertions = CompleteInsertionChain(ie)) {
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
    SmallVector<Value *, 4> values;
    for (Instruction *inst : *insertions) {
      if (auto *insert_value = dyn_cast<InsertValueInst>(inst)) {
        values.push_back(insert_value->getInsertedValueOperand());
      } else if (auto *insert_element = dyn_cast<InsertElementInst>(inst)) {
        values.push_back(insert_element->getOperand(1));
      } else {
        llvm_unreachable("Unhandled insertion instruction");
      }
    }

    auto *resultTy = insertions->back()->getType();
    Function *fn = GetConstructFunction(M, resultTy);

    // Replace the chain.
    auto call = CallInst::Create(fn, values);
    call->insertAfter(insertions->back());
    insertions->back()->replaceAllUsesWith(call);

    // Remove the insertions if we can.  Go from the tail back to
    // the head, since the tail uses the previous insertion, etc.
    for (auto iter = insertions->rbegin(), end = insertions->rend();
         iter != end; ++iter) {
      Instruction *insertion = *iter;
      if (!insertion->hasNUsesOrMore(1)) {
        insertion->eraseFromParent();
      }
    }

    delete insertions;
  }

  return Changed;
}

bool RewriteInsertsPass::ReplacePartialInsertions(Module &M) {
  bool Changed = false;

  // First find candidates.  Collect all InsertValue instructions
  // into struct type, but track their interdependencies.  To minimize
  // the number of new instructions, generate a construction for each
  // tail of an insertion chain.

  UniqueVector<InsertValueInst *> insertions;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (InsertValueInst *iv = dyn_cast<InsertValueInst>(&I)) {
          if (iv->getType()->isStructTy()) {
            insertions.insert(iv);
          }
        }
      }
    }
  }

  // Now count how many times each InsertValue is used by another InsertValue.
  // The |num_uses| vector is indexed by the unique id that |insertions|
  // assigns to it.
  std::vector<unsigned> num_uses(insertions.size() + 1);
  // Count from the user's perspective.
  for (InsertValueInst *insertion : insertions) {
    if (auto *agg =
            dyn_cast<InsertValueInst>(insertion->getAggregateOperand())) {
      ++(num_uses[insertions.idFor(agg)]);
    }
  }

  // Proceed in rounds.  Each round rewrites any chains ending with an
  // insertion that is not used by another insertion.

  // Get the first list of insertion tails.
  InsertionVector WorkList;
  for (InsertValueInst *insertion : insertions) {
    if (num_uses[insertions.idFor(insertion)] == 0) {
      WorkList.push_back(insertion);
    }
  }

  // This records insertions in the order they should be removed.
  // In this list, an insertion preceds any insertions it uses.
  // (This is post-dominance order.)
  InsertionVector ordered_candidates_for_removal;

  // Proceed in rounds.
  while (WorkList.size()) {
    Changed = true;

    // Record the list of tails for the next round.
    InsertionVector NextRoundWorkList;

    for (Instruction *inst : WorkList) {
      InsertValueInst *insertion = cast<InsertValueInst>(inst);
      // Rewrite |insertion|.

      StructType *resultTy = cast<StructType>(insertion->getType());

      const unsigned num_members = resultTy->getNumElements();
      std::vector<Value *> members(num_members, nullptr);
      InsertionVector chain;
      // Gather the member values.  Walk backward from the insertion.
      Value *base = LoadValuesEndingWithInsertion(insertion, &members, &chain);

      // Populate remaining entries in |values| by extracting elements
      // from |base|.  Only make a new extractvalue instruction if we can't
      // make a constant or undef.  New instructions are inserted before
      // the insertion we plan to remove.
      for (unsigned i = 0; i < num_members; ++i) {
        if (!members[i]) {
          Type *memberTy = resultTy->getTypeAtIndex(i);
          if (isa<UndefValue>(base)) {
            members[i] = UndefValue::get(memberTy);
          } else if (const auto *caz = dyn_cast<ConstantAggregateZero>(base)) {
            members[i] = caz->getElementValue(i);
          } else if (const auto *ca = dyn_cast<ConstantAggregate>(base)) {
            members[i] = ca->getOperand(i);
          } else {
            members[i] = ExtractValueInst::Create(base, {i}, "", insertion);
          }
        }
      }

      // Create the call.  It's dominated by any extractions we've just
      // created.
      Function *construct_fn = GetConstructFunction(M, resultTy);
      auto *call = CallInst::Create(construct_fn, members, "", insertion);

      // Disconnect this insertion.  We'll remove it later.
      insertion->replaceAllUsesWith(call);

      // Trace backward through the chain, removing uses and deleting where
      // we can.  Stop at the first element that has a remaining use.
      for (auto *chainElem : chain) {
        if (chainElem->hasNUsesOrMore(1)) {
          unsigned &use_count =
              num_uses[insertions.idFor(cast<InsertValueInst>(chainElem))];
          assert(use_count > 0);
          --use_count;
          if (use_count == 0) {
            NextRoundWorkList.push_back(chainElem);
          }
          break;
        } else {
          chainElem->eraseFromParent();
        }
      }
    }
    WorkList = std::move(NextRoundWorkList);
  }

  return Changed;
}
