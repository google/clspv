// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "PhysicalPointerArgsPass.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "Constants.h"
#include "Types.h"

using namespace llvm;

PreservedAnalyses clspv::PhysicalPointerArgsPass::run(Module &M,
                                                      ModuleAnalysisManager &) {

  PreservedAnalyses PA;
  DenseMap<Value *, Type *> TypeCache;

  for (auto &F : M) {
    if (F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    // Check if the kernel has any pointer arguments that require transformation
    // If so, we want to create a wrapper function that takes an i64 instead of
    // each pointer
    SmallVector<Type *, 8> NewParamTypes;
    auto *PtrIntTy = IntegerType::getInt64Ty(M.getContext());
    bool UpdateNeeded = false;

    for (auto &Arg : F.args()) {
      if (auto *PtrTy = dyn_cast<PointerType>(Arg.getType())) {
        auto *ArgTy = clspv::InferType(&Arg, M.getContext(), &TypeCache);

        bool IsBuiltinStructTy = false;
        if (auto *ArgStructTy = dyn_cast<StructType>(ArgTy)) {
          IsBuiltinStructTy = clspv::IsImageType(ArgStructTy) ||
                              clspv::IsSamplerType(ArgStructTy);
        }

        if ((PtrTy->getAddressSpace() == clspv::AddressSpace::Global ||
             PtrTy->getAddressSpace() == clspv::AddressSpace::Constant) &&
            !IsBuiltinStructTy) {
          NewParamTypes.push_back(PtrIntTy);
          UpdateNeeded = true;
          continue;
        }
      }
      NewParamTypes.push_back(Arg.getType());
    }

    if (!UpdateNeeded)
      continue;

    auto *NewFuncTy =
        FunctionType::get(F.getReturnType(), NewParamTypes, false);

    auto NewFunc = Function::Create(NewFuncTy, F.getLinkage());
    // The new function adopts the real name so that linkage to the outside
    // world remains the same.
    NewFunc->setName(F.getName());
    F.setName(NewFunc->getName().str() + ".inner");

    NewFunc->setCallingConv(F.getCallingConv());
    NewFunc->copyAttributesFrom(&F);
    F.setCallingConv(CallingConv::SPIR_FUNC);
    NewFunc->copyMetadata(&F, 0);

    // Create the function definition. It calls the wrapped function, bitcasting
    // any global pointers from the i64 arguments in the wrapper
    IRBuilder<> Builder(BasicBlock::Create(M.getContext(), "entry", NewFunc));
    SmallVector<Value *, 8> WrappedArgs;
    for (unsigned ArgNum = 0; ArgNum < F.arg_size(); ArgNum++) {
      auto *OriginalArgTy = F.getArg(ArgNum)->getType();
      auto *NewArg = NewFunc->getArg(ArgNum);
      if (OriginalArgTy != NewArg->getType()) {
        auto *IntAsPtr = Builder.CreateIntToPtr(NewArg, OriginalArgTy);
        WrappedArgs.push_back(IntAsPtr);

        // We can't attach metadata to arguments directly, so add to this
        // use instead. Subsequent passes can determine whether the POD
        // contains a pointer by checking the users of the argument.
        if (auto *InstAsPtrInstr = dyn_cast<Instruction>(IntAsPtr)) {
          auto *EmptyMD = MDNode::get(F.getContext(), {});
          InstAsPtrInstr->setMetadata(clspv::PointerPodArgMetadataName(),
                                      EmptyMD);
          continue;
        }
        llvm_unreachable("IntToPtr is not an instruction!");
      }

      WrappedArgs.push_back(NewArg);
    }
    auto *CallInst = Builder.CreateCall(&F, WrappedArgs);
    CallInst->setCallingConv(F.getCallingConv());
    Builder.CreateRetVoid();

    // Insert the function after the original, to preserve ordering
    // in the module as much as possible.
    auto &FunctionList = M.getFunctionList();
    for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
         Iter != IterEnd; ++Iter) {
      if (&*Iter == &F) {
        FunctionList.insertAfter(Iter, NewFunc);
        break;
      }
    }

    // Inline the function into the wrapper
    InlineFunctionInfo info;
    InlineFunction(*CallInst, info);
  }

  return PA;
}
