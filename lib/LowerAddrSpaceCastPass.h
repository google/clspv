// Copyright 2023 The Clspv Authors. All rights reserved.
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

#ifndef _CLSPV_LIB_ADDRSPACECAST_PASS_H
#define _CLSPV_LIB_ADDRSPACECAST_PASS_H

#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#include "clspv/AddressSpace.h"

namespace clspv {
struct LowerAddrSpaceCastPass
    : llvm::PassInfoMixin<LowerAddrSpaceCastPass>,
      llvm::InstVisitor<LowerAddrSpaceCastPass, llvm::Value *> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Implementation details for InstVisitor
  using Visitor = llvm::InstVisitor<LowerAddrSpaceCastPass, llvm::Value *>;
  using Visitor::visit;
  friend Visitor;

  llvm::Value *visit(llvm::Value *V);
  llvm::Value *visitAllocaInst(llvm::AllocaInst &I);
  llvm::Value *visitLoadInst(llvm::LoadInst &I);
  llvm::Value *visitStoreInst(llvm::StoreInst &I);
  llvm::Value *visitGetElementPtrInst(llvm::GetElementPtrInst &I);
  llvm::Value *visitAddrSpaceCastInst(llvm::AddrSpaceCastInst &I);
  llvm::Value *visitICmpInst(llvm::ICmpInst &I);
  llvm::Value *visitCallInst(llvm::CallInst &I);
  llvm::Value *visitInstruction(llvm::Instruction &I);

  void runOnFunction(llvm::Function &F);

  void registerReplacement(llvm::Value *U, llvm::Value *V);

  /// Clears the dead instructions and others that might be rendered dead
  /// by their removal.
  void cleanDeadInstructions();

  void cleanModule(llvm::Module &M);

  /// A map between original values and their replacement.
  ///
  /// The content of this mapping is valid only for the function being visited
  /// at a given time. The keys in this mapping should be removed from the
  /// function once all instructions in the current function have been visited
  /// and transformed. Instructions are not removed from the function as they
  /// are visited because this would invalidate iterators.
  llvm::DenseMap<llvm::Value *, llvm::Value *> ValueMap;

  llvm::DenseMap<llvm::Value *, llvm::Type *> TypeCache;

  llvm::DenseMap<llvm::Function *, llvm::Function *> FunctionMap;
};
} // namespace clspv

#endif // _CLSPV_LIB_ADDRSPACECAST_PASS_H
