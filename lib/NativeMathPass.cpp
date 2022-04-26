// Copyright 2021 The Clspv Authors. All rights reserved.
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
#include "llvm/Pass.h"

#include "Builtins.h"
#include "NativeMathPass.h"
#include "clspv/Option.h"

using namespace llvm;

PreservedAnalyses clspv::NativeMathPass::run(Module &M,
                                             ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (!clspv::Option::NativeMath())
    return PA;

  for (auto &F : M) {
    auto info = clspv::Builtins::Lookup(F.getName());
    switch (info.getType()) {
    case Builtins::kDistance:
    case Builtins::kLength:
    case Builtins::kFma:
    case Builtins::kAcosh:
    case Builtins::kAsinh:
    case Builtins::kAtan:
    case Builtins::kAtan2:
    case Builtins::kAtanpi:
    case Builtins::kAtan2pi:
    case Builtins::kAtanh:
    case Builtins::kFmod:
    case Builtins::kFract:
    case Builtins::kLdexp:
    case Builtins::kRsqrt:
    case Builtins::kHalfSqrt:
    case Builtins::kSqrt:
    case Builtins::kTanh:
      // Strip the definition of the function leaving only the declaration.
      F.deleteBody();
      break;
    default:
      break;
    }
  }

  return PA;
}
