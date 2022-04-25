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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/AddressSpace.h"

#include "InlineFuncWithPointerToFunctionArgPass.h"

using namespace llvm;

#define DEBUG_TYPE "inlinefuncwithpointerfunctionarg"

namespace {

// Returns true if |type| is a pointer to Function storage class.
bool IsPointerToFunctionStorage(Type *type) {
  if (auto *pointerTy = dyn_cast<PointerType>(type)) {
    return pointerTy->getAddressSpace() == clspv::AddressSpace::Private;
  }
  return false;
}

// Returns true if |type| is a function whose return type or any of its
// arguments are pointer-to-Function storage class.
bool IsProblematicFunctionType(Type *type) {
  if (auto *funcTy = dyn_cast<FunctionType>(type)) {
    if (IsPointerToFunctionStorage(funcTy->getReturnType())) {
      return true;
    }
    for (auto *paramTy : funcTy->params()) {
      if (IsPointerToFunctionStorage(paramTy)) {
        return true;
      }
    }
  }
  return false;
}
} // namespace

PreservedAnalyses
clspv::InlineFuncWithPointerToFunctionArgPass::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  // Loop through our inline pass until they stop changing thing.
  bool changed = true;
  while (changed) {
    changed &= InlineFunctions(M);
  }

  return PA;
}

bool clspv::InlineFuncWithPointerToFunctionArgPass::InlineFunctions(Module &M) {
  bool Changed = false;

  UniqueVector<CallInst *> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto call = dyn_cast<CallInst>(&I)) {
          if (IsProblematicFunctionType(call->getFunctionType())) {
            WorkList.insert(call);
          }
        }
      }
    }
  }

  for (CallInst *Call : WorkList) {
    InlineFunctionInfo IFI;
    // Disable generation of lifetime intrinsic.
    Changed |= InlineFunction(*Call, IFI, nullptr, false).isSuccess();
  }

  // Remove dead functions.
  bool removed;
  do {
    removed = false;
    for (auto &F : M) {
      if (F.getCallingConv() == CallingConv::SPIR_KERNEL)
        continue;
      if (F.use_begin() == F.use_end()) {
        F.eraseFromParent();
        removed = true;
        Changed = true;
        break;
      }
    }
  } while (removed);

  return Changed;
}
