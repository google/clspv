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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "UndoTruncatedSwitchCondition"

namespace {
struct UndoTruncatedSwitchConditionPass : public ModulePass {
  static char ID;
  UndoTruncatedSwitchConditionPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  // Maps a value to its zero-extended value.  This is the memoization table for
  // ZeroExtend.
  DenseMap<Value *, Value *> extended_value_;

  // Returns a 32-bit zero-extended version of the given argument.
  // Candidates for erasure are added to |zombies_|, before their feeding
  // values are created.
  // TODO(dneto): Handle 64 bit case as well, but separately.
  Value *ZeroExtend(Value *v) {
    const auto bit_width = v->getType()->getIntegerBitWidth();
    if (bit_width > 32) {
      errs() << "Unhandled bit width for " << *v << "\n";
      llvm_unreachable("Unhandled bit width");
    }
    // This base case makes for easier recursion.
    if (bit_width == 32) {
      return v;
    }

    auto where = extended_value_.find(v);
    if (where != extended_value_.end()) {
      return where->second;
    }

    if (auto *ci = dyn_cast<ConstantInt>(v)) {
      return ConstantInt::get(i32_, uint32_t(ci->getZExtValue()));
    }
    Value *result = nullptr;
    if (auto *inst = dyn_cast<Instruction>(v)) {
      zombies_.insert(inst);
    }
    if (auto *trunc = dyn_cast<TruncInst>(v)) {
      auto *operand = trunc->getOperand(0);
      result = ZeroExtend(operand);
    } else if (auto *zext = dyn_cast<ZExtInst>(v)) {
      result = new ZExtInst(zext->getOperand(0), i32_, "", zext);
    } else if (auto *phi = dyn_cast<PHINode>(v)) {
      const auto num_branches = phi->getNumIncomingValues();
      PHINode *new_phi = PHINode::Create(i32_, num_branches, "", phi);
      for (unsigned i = 0; i < num_branches; i++) {
        new_phi->addIncoming(ZeroExtend(phi->getIncomingValue(i)),
                             phi->getIncomingBlock(i));
      }
      result = new_phi;
    } else if (auto *sel = dyn_cast<SelectInst>(v)) {
      auto *ext_true = ZeroExtend(sel->getTrueValue());
      auto *ext_false = ZeroExtend(sel->getFalseValue());
      result =
          SelectInst::Create(sel->getCondition(), ext_true, ext_false, "", sel);
    } else if (auto *binop = dyn_cast<BinaryOperator>(v)) {
      // White-list binary operators that are ok to transform.
      if (binop->getOpcode() == Instruction::Add ||
          binop->getOpcode() == Instruction::Sub ||
          binop->getOpcode() == Instruction::Mul ||
          binop->getOpcode() == Instruction::And ||
          binop->getOpcode() == Instruction::Or ||
          binop->getOpcode() == Instruction::Xor) {
        auto *op1 = ZeroExtend(binop->getOperand(0));
        auto *op2 = ZeroExtend(binop->getOperand(1));
        auto new_binop =
            BinaryOperator::Create(binop->getOpcode(), op1, op2, "", binop);
        // Now, and the extended version to keep the range of the output
        // restricted to the original bit width.
        result = BinaryOperator::Create(
            Instruction::And, new_binop,
            ConstantInt::get(
                i32_,
                (uint32_t)APInt::getAllOnesValue(bit_width).getZExtValue()),
            "", binop);
      } else {
        errs() << "Unhandled instruction feeding switch " << *v << "\n";
        llvm_unreachable("Unhandled instruction feeding switch!");
      }
    } else {
      errs() << "Unhandled instruction feeding switch " << *v << "\n";
      llvm_unreachable("Unhandled instruction feeding switch!");
    }

    extended_value_[v] = result;
    return result;
  }

  // The 32-bit int type.
  Type *i32_;
  // The list of things that might be dead.
  UniqueVector<Instruction *> zombies_;
};
} // namespace

char UndoTruncatedSwitchConditionPass::ID = 0;
INITIALIZE_PASS(UndoTruncatedSwitchConditionPass,
                "UndoTruncatedSwitchCondition",
                "Undo Truncated Switch Condition Pass", false, false)

namespace clspv {
ModulePass *createUndoTruncatedSwitchConditionPass() {
  return new UndoTruncatedSwitchConditionPass();
}
} // namespace clspv

bool UndoTruncatedSwitchConditionPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<SwitchInst *, 8> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a switch instruction.
        if (auto SI = dyn_cast<SwitchInst>(&I)) {
          // Whose condition is a strangely sized integer type.
          switch (SI->getCondition()->getType()->getIntegerBitWidth()) {
          default:
            WorkList.push_back(SI);
            break;
          case 8:
          case 16:
          case 32:
          case 64:
            break;
          }
        }
      }
    }
  }

  zombies_.reset();
  i32_ = Type::getInt32Ty(M.getContext());

  for (auto SI : WorkList) {
    auto Cond = SI->getCondition();

    auto *widened = ZeroExtend(Cond);
    SI->setCondition(widened);
    Changed = true;

    for (auto Cases : SI->cases()) {
      // The original value of the case.
      auto V = Cases.getCaseValue()->getZExtValue();

      // A new value for the case with the correct type.
      auto CI = dyn_cast<ConstantInt>(ConstantInt::get(i32_, V));

      // And we replace the old value.
      Cases.setValue(CI);
    }
  }

  // Remove the zombies if we can.  We expect to.  They are ordered from
  // combinations down to their supporting values.
  for (auto *zombie : zombies_) {
    if (!zombie->hasNUsesOrMore(1)) {
      zombie->eraseFromParent();
    }
  }

  return Changed;
}
