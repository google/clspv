// Copyright 2019 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "clspv/Passes.h"

using namespace llvm;

namespace {

class DemangleKernelNames final : public ModulePass {
public:
  static char ID;
  DemangleKernelNames() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;
};

char DemangleKernelNames::ID = 0;
static RegisterPass<DemangleKernelNames>
    X("DemangleKernelNames", "Demangle the name of kernel functions");
} // namespace

namespace clspv {
ModulePass *createDemangleKernelNamesPass() {
  return new DemangleKernelNames();
}
} // namespace clspv

namespace {

bool DemangleKernelNames::runOnModule(Module &M) {
  bool Changed = false;
  for (auto &F : M) {
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      auto MangledName = F.getName();
      if (!MangledName.consume_front("_Z")) {
        continue;
      }
      size_t nameLen;
      if (MangledName.consumeInteger(10, nameLen)) {
        continue;
      }
      auto DemangledName = MangledName.take_front(nameLen);
      F.setName(DemangledName);
      Changed = true;
    }
  }
  return Changed;
}

} // namespace
