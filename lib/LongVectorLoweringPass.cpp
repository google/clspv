// Copyright 2020 The Clspv Authors. All rights reserved.
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

#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"

#include "clspv/Passes.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "LongVectorLowering"

namespace {

class LongVectorLoweringPass final : public ModulePass {
public:
  static char ID;

public:
  LongVectorLoweringPass() : ModulePass(ID) {}

  /// Lower the content of the given module @p M.
  bool runOnModule(Module &M) override;
};

char LongVectorLoweringPass::ID = 0;

bool LongVectorLoweringPass::runOnModule(Module &) {
  // TODO implement long-vector lowering.
  bool Modified = false;
  return Modified;
}

} // namespace

INITIALIZE_PASS(LongVectorLoweringPass, "LongVectorLowering",
                "Long Vector Lowering Pass", false, false)

llvm::ModulePass *clspv::createLongVectorLoweringPass() {
  return new LongVectorLoweringPass();
}
