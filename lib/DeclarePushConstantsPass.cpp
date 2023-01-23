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
#include "DeclarePushConstantsPass.h"
#include "PushConstant.h"

using namespace llvm;

PreservedAnalyses
clspv::DeclarePushConstantsPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  std::vector<clspv::PushConstant> PushConstants;

  auto &C = M.getContext();

  if (clspv::ShouldDeclareGlobalOffsetPushConstant(M)) {
    PushConstants.emplace_back(clspv::PushConstant::GlobalOffset);
  }

  if (clspv::ShouldDeclareEnqueuedLocalSizePushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::EnqueuedLocalSize);
  }

  if (clspv::ShouldDeclareGlobalSizePushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::GlobalSize);
  }

  if (clspv::ShouldDeclareRegionOffsetPushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::RegionOffset);
  }

  if (clspv::ShouldDeclareNumWorkgroupsPushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::NumWorkgroups);
  }

  if (clspv::ShouldDeclareRegionGroupOffsetPushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::RegionGroupOffset);
  }

  if (clspv::ShouldDeclareModuleConstantsPointerPushConstant(M)) {
    PushConstants.push_back(clspv::PushConstant::ModuleConstantsPointer);
  }

  if (PushConstants.size() > 0) {

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

  return PA;
}
