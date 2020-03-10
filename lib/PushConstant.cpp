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

#include "PushConstant.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/ErrorHandling.h"

#include "Constants.h"

using namespace llvm;

namespace clspv {

const char *GetPushConstantName(PushConstant pc) {
  switch (pc) {
  case PushConstant::Dimensions:
    return "dimensions";
  case PushConstant::GlobalOffset:
    return "global_offset";
  case PushConstant::EnqueuedLocalSize:
    return "enqueued_local_size";
  }
  llvm_unreachable("Unknown PushConstant in GetPushConstantName");
  return "";
}

Type *GetPushConstantType(Module &M, PushConstant pc) {
  auto &C = M.getContext();
  switch (pc) {
  case PushConstant::Dimensions:
    return IntegerType::get(C, 32);
  case PushConstant::GlobalOffset:
    return VectorType::get(IntegerType::get(C, 32), 3);
  case PushConstant::EnqueuedLocalSize:
    return VectorType::get(IntegerType::get(C, 32), 3);
  }
  llvm_unreachable("Unknown PushConstant in GetPushConstantType");
  return nullptr;
}

Value *GetPushConstantPointer(BasicBlock *BB, PushConstant pc) {
  auto M = BB->getParent()->getParent();

  // Get variable
  auto GV = M->getGlobalVariable(clspv::PushConstantsVariableName());
  assert(GV && "Push constants requested but none are declared.");

  // Find requested pc in metadata
  auto MD = GV->getMetadata(clspv::PushConstantsMetadataName());
  bool found = false;
  uint32_t idx = 0;
  for (auto &PCMD : MD->operands()) {
    auto mpc = static_cast<PushConstant>(
        mdconst::extract<ConstantInt>(PCMD)->getZExtValue());
    if (mpc == pc) {
      found = true;
      break;
    }
    idx++;
  }

  // Assert that it exists
  assert(found && "Push constant wasn't declared.");

  // Construct pointer
  IRBuilder<> Builder(BB);
  Value *Indices[] = {Builder.getInt32(0), Builder.getInt32(idx)};
  return Builder.CreateInBoundsGEP(GV, Indices);
}

} // namespace clspv
