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
#include "Passes.h"
#include "clspv/Option.h"

using namespace llvm;

namespace {
class NativeMathPass : public ModulePass {
public:
  static char ID;
  NativeMathPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char NativeMathPass::ID = 0;
INITIALIZE_PASS(NativeMathPass, "NativeMath",
                "Replace some builtin library functions for faster, lower "
                "precision alternatives",
                false, false)

namespace clspv {
ModulePass *createNativeMathPass() { return new NativeMathPass(); }
} // namespace clspv

bool NativeMathPass::runOnModule(Module &M) {
  if (!clspv::Option::NativeMath())
    return false;

  bool changed = false;
  for (auto &F : M) {
    auto info = clspv::Builtins::Lookup(F.getName());
    switch (info.getType()) {
    case clspv::Builtins::kDistance:
    case clspv::Builtins::kLength:
    case clspv::Builtins::kFma:
    case clspv::Builtins::kAcosh:
    case clspv::Builtins::kAsinh:
    case clspv::Builtins::kAtan:
    case clspv::Builtins::kAtan2:
    case clspv::Builtins::kAtanpi:
    case clspv::Builtins::kAtan2pi:
    case clspv::Builtins::kAtanh:
    case clspv::Builtins::kFmod:
    case clspv::Builtins::kFract:
    case clspv::Builtins::kLdexp:
    case clspv::Builtins::kRsqrt:
    case clspv::Builtins::kHalfSqrt:
    case clspv::Builtins::kSqrt:
    case clspv::Builtins::kTanh:
      // Strip the definition of the function leaving only the declaration.
      changed = true;
      F.deleteBody();
      break;
    default:
      break;
    }
  }

  return changed;
}
