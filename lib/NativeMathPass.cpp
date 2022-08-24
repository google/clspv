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
#include "llvm/Support/ErrorHandling.h"

#include "Builtins.h"
#include "NativeMathPass.h"
#include "ReplaceOpenCLBuiltinPass.h"
#include "clspv/Option.h"

#include <set>

using namespace llvm;

PreservedAnalyses clspv::NativeMathPass::run(Module &M,
                                             ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  auto nativeBuiltins = clspv::Option::UseNativeBuiltins();

  if (clspv::Option::NativeMath()) {
    nativeBuiltins.insert({
        Builtins::kDistance,
        Builtins::kLength,
        Builtins::kFma,
        Builtins::kAcosh,
        Builtins::kAsinh,
        Builtins::kAtan,
        Builtins::kAtan2,
        Builtins::kAtanpi,
        Builtins::kAtan2pi,
        Builtins::kAtanh,
        Builtins::kFmod,
        Builtins::kFract,
        Builtins::kLdexp,
        Builtins::kRsqrt,
        Builtins::kHalfSqrt,
        Builtins::kSqrt,
        Builtins::kTanh,
    });
  }

  if (nativeBuiltins.empty()) {
    return PA;
  }

  for (auto &F : M) {
    auto info = clspv::Builtins::Lookup(F.getName());
    if (nativeBuiltins.count(info.getType())) {
      if (Builtins::getExtInstEnum(info) == Builtins::kGlslExtInstBad &&
          ReplaceOpenCLBuiltinPass::ReplaceableBuiltins.count(info.getType()) ==
              0) {
        llvm::report_fatal_error(llvm::StringRef(
            "--use-native-builtins: couldn't replace builtin '" +
            info.getName() + "' with a native implementation!"));
      }

      F.deleteBody();
    }
  }

  return PA;
}
