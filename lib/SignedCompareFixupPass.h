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

#include "Builtins.h"

#ifndef _CLSPV_LIB_SIGNED_COMPARE_FIXUP_PASS_H
#define _CLSPV_LIB_SIGNED_COMPARE_FIXUP_PASS_H

namespace clspv {
struct SignedCompareFixupPass : llvm::PassInfoMixin<SignedCompareFixupPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Returns true if the given predicate is a signed integer comparison.
  bool IsSignedRelational(llvm::CmpInst::Predicate pred) {
    switch (pred) {
    case llvm::CmpInst::ICMP_SGT:
    case llvm::CmpInst::ICMP_SGE:
    case llvm::CmpInst::ICMP_SLT:
    case llvm::CmpInst::ICMP_SLE:
      return true;
    default:
      break;
    }
    return false;
  }

  // Replaces |call| which is a smin, smax or sclamp call with an equivalent
  // instruction stream. Also adds the comparisons introduced to |work_list|.
  void ReplaceBuiltin(llvm::CallInst *call, Builtins::BuiltinType type,
                      llvm::SmallVectorImpl<llvm::ICmpInst *> *work_list);
};
} // namespace clspv

#endif // _CLSPV_LIB_SIGNED_COMPARE_FIXUP_PASS_H
