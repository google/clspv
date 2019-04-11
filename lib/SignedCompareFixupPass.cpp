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

#include <memory>

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "signedcomparefixup"

namespace {

cl::opt<bool> ShowSCF("show-scf", cl::init(false), cl::Hidden,
                      cl::desc("Show signed compare fixup"));

class SignedCompareFixupPass final : public ModulePass {
public:
  static char ID;
  SignedCompareFixupPass() : ModulePass(ID) {}

  // Rewrite the module to avoid signed integer comparisons.
  bool runOnModule(Module &M) override;

private:
  // Returns true if the given predicate is a signed integer comparison.
  bool IsSignedRelational(CmpInst::Predicate pred) {
    switch (pred) {
    case CmpInst::ICMP_SGT:
    case CmpInst::ICMP_SGE:
    case CmpInst::ICMP_SLT:
    case CmpInst::ICMP_SLE:
      return true;
    default:
      break;
    }
    return false;
  }
};
} // namespace

char SignedCompareFixupPass::ID = 0;
INITIALIZE_PASS(SignedCompareFixupPass, "SignedCompareFixupPass",
                "Signed Integer Compare Fixup", false, false)

namespace clspv {
ModulePass *createSignedCompareFixupPass() {
  return new SignedCompareFixupPass();
}
} // namespace clspv

namespace {
bool SignedCompareFixupPass::runOnModule(Module &M) {
  bool Changed = false;
  if (!clspv::Option::HackSignedCompareFixup()) {
    return Changed;
  }

  SmallVector<ICmpInst *, 16> work_list;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &inst : BB) {
        if (auto *icmp = dyn_cast<ICmpInst>(&inst)) {
          if (IsSignedRelational(icmp->getPredicate())) {
            work_list.push_back(icmp);
          }
        }
      }
    }
  }

  if (ShowSCF) {
    for (auto *icmp : work_list) {
      outs() << "SCF:  Replace " << *icmp << "\n";
    }
  }

  IRBuilder<> Builder(M.getContext());
  // First break up any vector cases in to scalar cases.
  SmallVector<ICmpInst *, 16> scalar_work_list;
  for (auto *icmp : work_list) {
    Changed = true;

    auto *x = icmp->getOperand(0);
    auto *y = icmp->getOperand(1);
    auto *x_type = x->getType();

    // Make some useful constants
    auto *zero = ConstantInt::get(x_type, 0);
    auto *one = ConstantInt::get(x_type, 1);
    unsigned bit_width;
    if (auto *scalar = dyn_cast<ConstantInt>(one)) {
      bit_width = scalar->getBitWidth();
    } else if (auto *cdv = dyn_cast<ConstantDataVector>(one)) {
      bit_width = cdv->getElementAsAPInt(0).getBitWidth();
    } else {
      errs() << "Signed Comparison Fixup: Unhandled constant vector type "
             << *(one->getType()) << "\n";
      bit_width = 1;
      llvm_unreachable("Unhandled constant vector type");
    }
    auto *sign_bit = ConstantInt::get(x_type, uint64_t(1) << (bit_width - 1));
    auto *all_one_bits =
        ConstantInt::get(x_type, APInt::getMaxValue(bit_width));

    Builder.SetInsertPoint(icmp);
    Value *replacement;
    switch (icmp->getPredicate()) {
    case CmpInst::ICMP_SGT: {
      // Derivation of the replacement:
      //
      //    x > y
      //
      //    x - y > 0
      //
      //    x - y - 1 >= 0
      //
      //    sign(x - y - 1) == 0
      auto *diff = Builder.CreateSub(x, y);
      auto *diff_minus_one = Builder.CreateSub(diff, one);
      auto *diff_sign = Builder.CreateAnd(diff_minus_one, sign_bit);
      replacement = Builder.CreateICmpEQ(diff_sign, zero);
    } break;
    case CmpInst::ICMP_SGE: {
      // Derivation of the replacement:
      //
      //    x >= y
      //
      //    x - y >= 0
      //
      //    sign(x - y) == 0
      auto *diff = Builder.CreateSub(x, y);
      auto *diff_sign = Builder.CreateAnd(diff, sign_bit);
      replacement = Builder.CreateICmpEQ(diff_sign, zero);
    } break;
    case CmpInst::ICMP_SLT: {
      // Derivation of the replacement:
      //
      //    x < y
      //
      //    0 < y - x
      //
      //    0 <= y - x - 1
      //
      //    sign(y - x - 1) == 0
      auto *diff = Builder.CreateSub(y, x);
      auto *diff_minus_one = Builder.CreateSub(diff, one);
      auto *diff_sign = Builder.CreateAnd(diff_minus_one, sign_bit);
      replacement = Builder.CreateICmpEQ(diff_sign, zero);
    } break;
    case CmpInst::ICMP_SLE: {
      // Derivation of the replacement:
      //
      //    x <= y
      //
      //    0 <= y - x
      //
      //    sign(y - x) == 0
      auto *diff = Builder.CreateSub(y, x);
      auto *diff_sign = Builder.CreateAnd(diff, sign_bit);
      replacement = Builder.CreateICmpEQ(diff_sign, zero);
    } break;
    default:
      llvm_unreachable("Unhandled integer comparison");
      break;
    }
    icmp->replaceAllUsesWith(replacement);
  }

  for (auto *inst : work_list) {
    inst->eraseFromParent();
  }

  if (ShowSCF) {
    outs() << "\n\nSCF:  DONE\n";
  }

  return Changed;
}
} // namespace
