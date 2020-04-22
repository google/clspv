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

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "Constants.h"
#include "Passes.h"

#define DEBUG_TYPE "autopodargs"

using namespace llvm;

namespace {
class AutoPodArgsPass : public ModulePass {
public:
  static char ID;
  AutoPodArgsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
private:
  void AnnotateAllKernels(Module &M, clspv::PodArgImpl impl);
  void AddMetadata(Function &F, clspv::PodArgImpl impl);
};
} // namespace

char AutoPodArgsPass::ID = 0;
INITIALIZE_PASS(AutoPodArgsPass, "AutoPodArgs",
                "Mark pod arg implementation as metadata on kernels", false, false)

namespace clspv {
ModulePass *createAutoPodArgsPass() {
  return new AutoPodArgsPass();
}
} // namespace clspv

bool AutoPodArgsPass::runOnModule(Module &M) {
  if (clspv::Option::PodArgsInUniformBuffer()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kUBO);
  } else if (clspv::Option::PodArgsInPushConstants()) {
    AnnotateAllKernels(M, clspv::PodArgImpl::kPushConstant);
  } else {
    AnnotateAllKernels(M, clspv::PodArgImpl::kSSBO);
  }

  return true;
}

void AutoPodArgsPass::AnnotateAllKernels(Module &M, clspv::PodArgImpl impl) {
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;
  
    AddMetadata(F, impl);
  }
}

void AutoPodArgsPass::AddMetadata(Function &F, clspv::PodArgImpl impl) {
  auto md = MDTuple::get(
      F.getContext(),
      ConstantAsMetadata::get(ConstantInt::get(
          IntegerType::get(F.getContext(), 32), static_cast<uint32_t>(impl))));
  F.setMetadata(clspv::PodArgsImplMetadataName(), md);
}
