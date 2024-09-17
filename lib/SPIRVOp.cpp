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

#include "SPIRVOp.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include "Builtins.h"
#include "Constants.h"

namespace clspv {

using namespace llvm;

Instruction *InsertSPIRVOp(Instruction *Insert, spv::Op Opcode,
                           ArrayRef<Attribute::AttrKind> Attributes,
                           Type *RetType, ArrayRef<Value *> Args,
                           const MemoryEffects &MemEffects) {

  // Get the source location for the instruction
  const DILocation *DbgLoc = Insert->getDebugLoc();
  
  // Prepare mangled name
  std::string MangledName = clspv::SPIRVOpIntrinsicFunction();
  MangledName += ".";
  MangledName += std::to_string(Opcode);
  MangledName += ".";
  for (auto Arg : Args) {
    MangledName += Builtins::GetMangledTypeName(Arg->getType());
  }

  auto M = Insert->getModule();
  auto Int32Ty = Type::getInt32Ty(M->getContext());
  Function *func = M->getFunction(MangledName);
  if (!func) {
    // Create a function in the module
    SmallVector<Type *, 8> ArgTypes = {Int32Ty};
    for (auto Arg : Args) {
      ArgTypes.push_back(Arg->getType());
    }
    auto NewFType = FunctionType::get(RetType, ArgTypes, false);
    auto NewFTyC = M->getOrInsertFunction(MangledName, NewFType);
    func = cast<Function>(NewFTyC.getCallee());
    for (auto A : Attributes) {
      func->addFnAttr(A);
    }
    if (MemEffects != MemoryEffects::unknown())
      func->setMemoryEffects(MemEffects);
  }

  // Now call it with the values we were passed
  SmallVector<Value *, 8> ArgValues = {ConstantInt::get(Int32Ty, Opcode)};
  for (auto Arg : Args) {
    ArgValues.push_back(Arg);
  }

  Instruction *NewInst = CallInst::Create(func, ArgValues, "", Insert);

  // Set the location for the new one
  if (DbgLoc) {
    NewInst->setDebugLoc(DbgLoc);
  }

  return NewInst;
}

} // namespace clspv
