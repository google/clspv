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

#include <utility>

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "Builtins.h"
#include "SignedCompareFixupPass.h"

using namespace clspv;
using namespace llvm;

#define DEBUG_TYPE "signedcomparefixup"

namespace {

cl::opt<bool> ShowSCF("show-scf", cl::init(false), cl::Hidden,
                      cl::desc("Show signed compare fixup"));

} // namespace

PreservedAnalyses SignedCompareFixupPass::run(Module &M,
                                              ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (!clspv::Option::HackSignedCompareFixup()) {
    return PA;
  }

  SmallVector<Instruction *, 16> to_remove;
  SmallVector<ICmpInst *, 16> work_list;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &inst : BB) {
        if (auto *icmp = dyn_cast<ICmpInst>(&inst)) {
          if (IsSignedRelational(icmp->getPredicate())) {
            work_list.push_back(icmp);
          }
        } else if (auto call = dyn_cast<CallInst>(&inst)) {
          // Same bug exists for smin, smax and sclamp. Break those calls down
          // and then replace the resulting comparisons too.
          auto &info = Builtins::Lookup(call->getCalledFunction());
          switch (info.getType()) {
          case Builtins::kMax:
          case Builtins::kMin:
          case Builtins::kClamp: {
            auto param_info = info.getParameter(0);
            // Note that this also covers vector operands.
            if (param_info.is_signed &&
                param_info.type_id == llvm::Type::IntegerTyID) {
              if (ShowSCF) {
                outs() << "SCF: Replace " << *call << "\n";
              }
              ReplaceBuiltin(call, info.getType(), &work_list);
              to_remove.push_back(call);
            }
            break;
          }
          default:
            break;
          }

          switch (call->getIntrinsicID()) {
          case Intrinsic::smax:
          case Intrinsic::smin:
            if (ShowSCF) {
              outs() << "SCF: Replace " << *call << "\n";
            }
            ReplaceBuiltin(call,
                           call->getIntrinsicID() == Intrinsic::smax
                               ? Builtins::kMax
                               : Builtins::kMin,
                           &work_list);
            to_remove.push_back(call);
            break;
          default:
            break;
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
  for (auto *icmp : work_list) {
    auto *x = icmp->getOperand(0);
    auto *y = icmp->getOperand(1);
    auto *x_type = x->getType();

    // Flipping the sign bit of both operands maps the signed order onto the
    // unsigned order. Unlike a subtraction-based replacement, this cannot
    // overflow.
    const unsigned bit_width = x_type->getScalarSizeInBits();
    auto *sign_bit = ConstantInt::get(x_type, APInt::getSignMask(bit_width));

    Builder.SetInsertPoint(icmp);
    auto *x_unsigned = Builder.CreateXor(x, sign_bit);
    auto *y_unsigned = Builder.CreateXor(y, sign_bit);

    Value *replacement;
    switch (icmp->getPredicate()) {
    case CmpInst::ICMP_SGT:
      replacement = Builder.CreateICmpUGT(x_unsigned, y_unsigned);
      break;
    case CmpInst::ICMP_SGE:
      replacement = Builder.CreateICmpUGE(x_unsigned, y_unsigned);
      break;
    case CmpInst::ICMP_SLT:
      replacement = Builder.CreateICmpULT(x_unsigned, y_unsigned);
      break;
    case CmpInst::ICMP_SLE:
      replacement = Builder.CreateICmpULE(x_unsigned, y_unsigned);
      break;
    default:
      llvm_unreachable("Unhandled integer comparison");
    }
    icmp->replaceAllUsesWith(replacement);
  }

  for (auto *inst : to_remove) {
    inst->eraseFromParent();
  }
  for (auto *inst : work_list) {
    inst->eraseFromParent();
  }

  if (ShowSCF) {
    outs() << "\n\nSCF:  DONE\n";
  }

  return PA;
}

void SignedCompareFixupPass::ReplaceBuiltin(
    CallInst *call, Builtins::BuiltinType type,
    SmallVectorImpl<ICmpInst *> *work_list) {
  // The returns from CreateICmpSLT are tested because they may have been
  // folded to a constant.
  IRBuilder<> builder(call->getContext());
  builder.SetInsertPoint(call);
  Value *out = nullptr;
  if (type == Builtins::kClamp) {
    // clamp(x,b,c) is min(max(x, b), c). Results are undefined if b > c, so
    // both comparisons can be made against x.
    auto x = call->getOperand(0);
    auto min = call->getOperand(1);
    auto max = call->getOperand(2);
    auto cmp1 = builder.CreateICmpSLT(x, min);
    auto sel = builder.CreateSelect(cmp1, min, x);
    auto cmp2 = builder.CreateICmpSLT(max, x);
    out = builder.CreateSelect(cmp2, max, sel);
    if (auto icmp = dyn_cast<ICmpInst>(cmp1))
      work_list->push_back(icmp);
    if (auto icmp = dyn_cast<ICmpInst>(cmp2))
      work_list->push_back(icmp);
  } else {
    bool is_min = type == Builtins::kMin;
    auto lhs = call->getOperand(0);
    auto rhs = call->getOperand(1);
    if (is_min)
      std::swap(lhs, rhs);
    auto cmp = builder.CreateICmpSLT(lhs, rhs);
    out = builder.CreateSelect(cmp, call->getOperand(1), call->getOperand(0));
    if (auto icmp = dyn_cast<ICmpInst>(cmp))
      work_list->push_back(icmp);
  }
  call->replaceAllUsesWith(out);
}
