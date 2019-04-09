// Copyright 2018 The Clspv Authors. All rights reserved.
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

#include "DescriptorCounter.h"

#include <cassert>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

// We keep the current counter in a named metadata node in the module.
// It looks likk this:
//
// !"clspv.descriptor.index" = !{!3}
// !3 = !{i32 0}
static const char *kMetadataName = "clspv.descriptor.index";

} // namespace

namespace clspv {

int GetCurrentDescriptorIndex(llvm::Module *M) {
  auto *md = M->getOrInsertNamedMetadata(kMetadataName);
  if (md->getNumOperands() == 0) {
    auto &ctx = M->getContext();
    IRBuilder<> Builder(ctx);
    ConstantInt *ci = Builder.getInt32(0);
    auto *val = ConstantAsMetadata::get(ci);
    md->addOperand(MDNode::get(ctx, val));
    return 0;
  }
  assert(md->getNumOperands() == 1);
  MDNode *operand = md->getOperand(0);
  assert(operand);
  assert(operand->getNumOperands() == 1);
  ConstantInt *ci = mdconst::dyn_extract<ConstantInt>(operand->getOperand(0));
  assert(ci);
  const int value = ci->getSExtValue();
  return value;
}

int TakeDescriptorIndex(llvm::Module *M) {
  const int old_value = GetCurrentDescriptorIndex(M);
  auto *md = M->getNamedMetadata(kMetadataName);
  assert(md);
  assert(md->getNumOperands() == 1);

  auto &ctx = M->getContext();
  IRBuilder<> Builder(ctx);
  md->setOperand(0, MDNode::get(ctx, ConstantAsMetadata::get(
                                         Builder.getInt32(old_value + 1))));
  return old_value;
}

} // namespace clspv
