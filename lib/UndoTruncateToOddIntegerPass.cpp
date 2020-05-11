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

#define DEBUG_TYPE "UndoTruncateToOddInteger"

namespace {
struct UndoTruncateToOddIntegerPass : public ModulePass {
  static char ID;
  UndoTruncateToOddIntegerPass() : ModulePass(ID) {}

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
    auto bit_width = 0;
    if (v->getType()->isIntegerTy())
      bit_width = v->getType()->getIntegerBitWidth();
    if (bit_width > 32) {
      errs() << "Unhandled bit width for " << *v << "\n";
      llvm_unreachable("Unhandled bit width");
    }

    auto where = extended_value_.find(v);
    if (where != extended_value_.end()) {
      return where->second;
    }

    // This base case makes for easier recursion.
    switch (bit_width) {
    case 8:
    case 16:
    case 32:
    case 64:
      if (!isa<ZExtInst>(v))
        return v;
    default:
      break;
    }

    if (auto *ci = dyn_cast<ConstantInt>(v)) {
      return ConstantInt::get(i32_, uint32_t(ci->getZExtValue()));
    }
    Value *result = nullptr;
    if (auto *trunc = dyn_cast<TruncInst>(v)) {
      auto *operand = ZeroExtend(trunc->getOperand(0));

      // Now, and the extended version to keep the range of the output
      // restricted to the original bit width.
      result = BinaryOperator::Create(
          Instruction::And, operand,
          ConstantInt::get(
              i32_, (uint32_t)APInt::getAllOnesValue(bit_width).getZExtValue()),
          "", trunc);
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
        result =
            BinaryOperator::Create(binop->getOpcode(), op1, op2, "", binop);
        if (binop->getOpcode() == Instruction::Add ||
            binop->getOpcode() == Instruction::Sub ||
            binop->getOpcode() == Instruction::Mul) {
          // Add an extra masking for add and sub in case of integer wrapping.
          result = BinaryOperator::Create(
              Instruction::And, result,
              ConstantInt::get(
                  i32_,
                  (uint32_t)APInt::getAllOnesValue(bit_width).getZExtValue()),
              "", binop);
        }
      } else {
        errs() << "Unhandled instruction feeding switch " << *v << "\n";
        llvm_unreachable("Unhandled instruction feeding switch!");
      }
    } else if (auto SI = dyn_cast<SwitchInst>(v)) {
      auto extended_cond = ZeroExtend(SI->getCondition());
      if (extended_cond && extended_cond != SI->getCondition()) {
        SI->setCondition(extended_cond);
        for (auto Cases : SI->cases()) {
          // The original value of the case.
          auto V = Cases.getCaseValue()->getZExtValue();

          // A new value for the case with the correct type.
          auto CI = dyn_cast<ConstantInt>(ConstantInt::get(i32_, V));

          // And we replace the old value.
          Cases.setValue(CI);
        }
      }
    } else if (auto inst = dyn_cast<Instruction>(v)) {
      for (unsigned i = 0; i < inst->getNumOperands(); ++i) {
        auto extended_op = ZeroExtend(inst->getOperand(i));
        if (extended_op && extended_op != inst->getOperand(i))
          inst->setOperand(i, extended_op);
      }
    } else {
      errs() << "Unhandled instruction " << *v << "\n";
      llvm_unreachable("Unhandled instruction!");
    }

    // If the instruction was replaced, mark it as a zombie.
    if (auto *inst = dyn_cast<Instruction>(v)) {
      if (result && result != inst)
        zombies_.insert(inst);
    }

    if (result)
      extended_value_[v] = result;
    return result;
  }

  // The 32-bit int type.
  Type *i32_;
  // The list of things that might be dead.
  UniqueVector<Instruction *> zombies_;
};
} // namespace

char UndoTruncateToOddIntegerPass::ID = 0;
INITIALIZE_PASS(UndoTruncateToOddIntegerPass, "UndoTruncateToOddInteger",
                "Undo Truncated Switch Condition Pass", false, false)

namespace clspv {
ModulePass *createUndoTruncateToOddIntegerPass() {
  return new UndoTruncateToOddIntegerPass();
}
} // namespace clspv

bool UndoTruncateToOddIntegerPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<Instruction *, 8> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto trunc = dyn_cast<TruncInst>(&I)) {
          if (trunc->getType()->isVectorTy())
            continue;
          switch (trunc->getType()->getIntegerBitWidth()) {
          default:
            WorkList.push_back(trunc);
            break;
          case 1: // i1 is a bool.
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

  while (!WorkList.empty()) {
    auto inst = WorkList.back();
    WorkList.pop_back();

    auto extended = ZeroExtend(inst);
    if (extended && extended != inst) {
      Changed = true;

      for (auto user : inst->users()) {
        if (auto user_inst = dyn_cast<Instruction>(user)) {
          WorkList.push_back(user_inst);
        }
      }
    }
  }

  // Remove the zombies if we can.  We expect to. We've ordered zombies in
  // reverse.
  for (int i = zombies_.size(); i >= 1; --i) {
    auto zombie = zombies_[i];
    if (!zombie->hasNUsesOrMore(1))
      zombie->eraseFromParent();
  }

  return Changed;
}
