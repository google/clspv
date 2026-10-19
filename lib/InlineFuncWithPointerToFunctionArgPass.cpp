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

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
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

bool ParamRequiresInlining(Argument *arg) {
  SmallVector<Value *, 8> worklist{arg};
  SmallPtrSet<Value *, 8> visited{arg};
  while (!worklist.empty()) {
    Value *v = worklist.pop_back_val();
    for (Use &use : v->uses()) {
      User *user = use.getUser();
      if (auto *gep = dyn_cast<GetElementPtrInst>(user)) {
        if (gep->getSourceElementType()->isPointerTy()) {
          continue;
        }
        auto *cst = dyn_cast<ConstantInt>(gep->getOperand(1));
        if (!cst || !cst->isZero()) {
          // Non-zero first index generates OpPtrAccessChain, which is not
          // supported for Function storage class.
          return true;
        }
        if (visited.insert(gep).second) {
          worklist.push_back(gep);
        }
      } else if (auto *st = dyn_cast<StoreInst>(user)) {
        if (st->getValueOperand() == v) {
          return true;
        }
      } else if (isa<LoadInst>(user)) {
        continue;
      } else if (isa<CallInst>(user)) {
        if (v != arg) {
          // Passing a GEP of a Private pointer to a function call is not a
          // memory object declaration in SPIR-V.
          return true;
        }
        continue;
      } else {
        // PHINode, SelectInst, BitCastInst, etc.
        return true;
      }
    }
  }
  return false;
}

bool CallRequiresInlining(CallInst *call) {
  auto *func = call->getCalledFunction();
  if (!func || func->isDeclaration()) {
    return false;
  }
  auto *funcTy = call->getFunctionType();
  if (IsPointerToFunctionStorage(funcTy->getReturnType())) {
    return true;
  }
  for (unsigned i = 0; i < funcTy->getNumParams(); ++i) {
    if (IsPointerToFunctionStorage(funcTy->getParamType(i))) {
      Value *argOp = call->getArgOperand(i);
      if (!isa<AllocaInst>(argOp) && !isa<Argument>(argOp)) {
        return true;
      }
      if (ParamRequiresInlining(func->getArg(i))) {
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
          if (CallRequiresInlining(call)) {
            WorkList.insert(call);
          }
        }
      }
    }
  }

  for (CallInst *Call : WorkList) {
    InlineFunctionInfo IFI;
    // Disable generation of lifetime intrinsic.
    Changed |= InlineFunction(*Call, IFI, false, nullptr, false).isSuccess();
  }

  // Remove dead functions.
  bool removed;
  do {
    removed = false;
    for (auto &F : M) {
      if (F.isDeclaration() || F.getCallingConv() == CallingConv::SPIR_KERNEL)
        continue;
      if (F.use_begin() == F.use_end()) {
        F.eraseFromParent();
        removed = true;
        break;
      }
    }
  } while (removed);

  return Changed;
}
