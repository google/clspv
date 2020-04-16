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

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/PushConstant.h"

#include "Constants.h"
#include "Passes.h"
#include "PushConstant.h"

using namespace llvm;

#define DEBUG_TYPE "declarepushconstants"

namespace {
struct DeclarePushConstantsPass : public ModulePass {
  static char ID;
  DeclarePushConstantsPass() : ModulePass(ID) {}

  bool shouldDeclareDimensions(Module &M);
  bool shouldDeclareEnqueuedLocalSize(Module &M);
  bool shouldDeclareGlobalOffset(Module &M);

  bool runOnModule(Module &M) override;
};
} // namespace

char DeclarePushConstantsPass::ID = 0;
INITIALIZE_PASS(DeclarePushConstantsPass, "DeclarePushConstants",
                "Declare push constants", false, false)

namespace clspv {
ModulePass *createDeclarePushConstantsPass() {
  return new DeclarePushConstantsPass();
}
} // namespace clspv

bool DeclarePushConstantsPass::shouldDeclareEnqueuedLocalSize(Module &M) {
  bool isEnabled = ((clspv::Option::Language() ==
                     clspv::Option::SourceLanguage::OpenCL_C_20) ||
                    (clspv::Option::Language() ==
                     clspv::Option::SourceLanguage::OpenCL_CPP));
  bool isUsed = M.getFunction("_Z23get_enqueued_local_sizej") != nullptr;
  return isEnabled && isUsed;
}

bool DeclarePushConstantsPass::shouldDeclareGlobalOffset(Module &M) {
  bool isEnabled = clspv::Option::GlobalOffset();
  bool isUsed = (M.getFunction("_Z17get_global_offsetj") != nullptr) ||
                (M.getFunction("_Z13get_global_idj") != nullptr);
  return isEnabled && isUsed;
}

bool DeclarePushConstantsPass::runOnModule(Module &M) {

  bool changed = false;

  std::vector<clspv::PushConstant> PushConstants;

  auto &C = M.getContext();

  if (shouldDeclareGlobalOffset(M)) {
    PushConstants.emplace_back(clspv::PushConstant::GlobalOffset);
  }

  if (shouldDeclareEnqueuedLocalSize(M)) {
    PushConstants.push_back(clspv::PushConstant::EnqueuedLocalSize);
  }

  if (PushConstants.size() > 0) {
    changed = true;

    std::vector<Type *> Members;

    for (auto &pc : PushConstants) {
      Members.push_back(GetPushConstantType(M, pc));
    }

    auto STy = StructType::create(C, Members);

    auto GV =
        new GlobalVariable(M, STy, false, GlobalValue::ExternalLinkage, nullptr,
                           clspv::PushConstantsVariableName(), nullptr,
                           GlobalValue::ThreadLocalMode::NotThreadLocal,
                           clspv::AddressSpace::PushConstant);

    GV->setInitializer(Constant::getNullValue(STy));

    std::vector<llvm::Metadata *> MDArgs;
    for (auto &pc : PushConstants) {
      auto Cst =
          ConstantInt::get(IntegerType::get(C, 32), static_cast<int>(pc));
      MDArgs.push_back(llvm::ConstantAsMetadata::get(Cst));
    };

    GV->setMetadata(clspv::PushConstantsMetadataName(),
                    llvm::MDNode::get(C, MDArgs));
  }

  return changed;
}
