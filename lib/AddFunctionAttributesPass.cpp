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

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "Constants.h"
#include "Passes.h"

#define DEBUG_TYPE "addfunctionattributes"

using namespace llvm;

namespace {
class AddFunctionAttributesPass : public ModulePass {
public:
  static char ID;
  AddFunctionAttributesPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char AddFunctionAttributesPass::ID = 0;
INITIALIZE_PASS(AddFunctionAttributesPass, "AddFunctionAttributes",
                "Add function attributes to builtin functions", false, false)

namespace clspv {
ModulePass *createAddFunctionAttributesPass() {
  return new AddFunctionAttributesPass();
}
} // namespace clspv

bool AddFunctionAttributesPass::runOnModule(Module &M) {
  bool changed = false;

  // Add ReadNone and Speculatable to literal sampler functions to avoid loop
  // optimizations producing phis with them.
  if (auto F = M.getFunction(clspv::TranslateSamplerInitializerFunction())) {
    F->addFnAttr(Attribute::AttrKind::ReadNone);
    F->addFnAttr(Attribute::AttrKind::Speculatable);
    changed = true;
  }

  return changed;
}
