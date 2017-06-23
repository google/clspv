// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <cassert>

#include <llvm/IR/Constants.h>
#include <llvm/IR/DerivedTypes.h>
#include <llvm/IR/Function.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>
#include <llvm/Support/raw_ostream.h>

//#include <llvm/Transforms/Utils/Cloning.h>

using namespace llvm;

#define DEBUG_TYPE "clusterpodkernelargs"

namespace {
struct ClusterPodKernelArgumentsPass : public ModulePass {
  static char ID;
  ClusterPodKernelArgumentsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char ClusterPodKernelArgumentsPass::ID = 0;
static RegisterPass<ClusterPodKernelArgumentsPass>
    X("ClusterPodKernelArgumentsPass",
      "Cluster POD Kernel Arguments Pass");

namespace clspv {
llvm::ModulePass *createClusterPodKernelArgumentsPass() {
  return new ClusterPodKernelArgumentsPass();
}
} // namespace clspv

bool ClusterPodKernelArgumentsPass::runOnModule(Module &M) {
  bool Changed = false;
  LLVMContext &Context = M.getContext();

  SmallVector<Function *, 8> WorkList;

  for (Function &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    for (Argument &Arg : F.args()) {
      if (!isa<PointerType>(Arg.getType())) {
        WorkList.push_back(&F);
        break;
      }
    }
  }

  //WorkList.clear();

  for (Function* F : WorkList) {
    Changed = true;

    // In OpenCL, kernel arguments are either pointers or POD. A composite with
    // an element or memeber that is a pointer is not allowed.  So we'll use POD
    // as a shorthand for non-pointer.

    SmallVector<Type *, 8> PtrArgTys;
    SmallVector<Type *, 8> PodArgTys;
    for (Argument &Arg : F->args()) {
      Type *ArgTy = Arg.getType();
      if (isa<PointerType>(ArgTy)) {
        PtrArgTys.push_back(ArgTy);
      } else {
        PodArgTys.push_back(ArgTy);
      }
    }


    // Put the pointer arguments first, and then POD arguments struct last.
    auto PodArgsStructTy =
        StructType::create(PodArgTys, F->getName().str() + ".podargs");
    SmallVector<Type *, 8> NewFuncParamTys(PtrArgTys);
    NewFuncParamTys.push_back(PodArgsStructTy);

    FunctionType *NewFuncTy =
        FunctionType::get(F->getReturnType(), NewFuncParamTys, false);

    // Create the new function and set key properties.
    auto NewFunc = Function::Create(NewFuncTy, F->getLinkage());
    // The new function adopts the real name so that linkage to the outside
    // world remains the same.
    NewFunc->setName(F->getName());
    F->setName(NewFunc->getName().str() + ".inner");

    NewFunc->setCallingConv(F->getCallingConv());
    F->setCallingConv(CallingConv::SPIR_FUNC);

    NewFunc->setAttributes(F->getAttributes());
    // Move OpenCL kernel named attributes.
    // TODO(dneto): Attributes starting with kernel_arg_* should be rewritten
    // to reflect change in the argument shape.
    std::vector<const char *> Metadatas{
        "reqd_work_group_size",   "kernel_arg_addr_space",
        "kernel_arg_access_qual", "kernel_arg_type",
        "kernel_arg_base_type",   "kernel_arg_type_qual"};
    for (auto name : Metadatas) {
      NewFunc->setMetadata(name, F->getMetadata(name));
      F->setMetadata(name, nullptr);
    }

    // Insert the function after the original, to preserve ordering
    // in the module as much as possible.
    auto &FunctionList = M.getFunctionList();
    for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
         Iter != IterEnd; ++Iter) {
      if (&*Iter == F) {
        FunctionList.insertAfter(Iter, NewFunc);
        break;
      }
    }

    // The body of the wrapper is essentially a call to the original function,
    // but we have to unwrap the non-pointer arguments from the struct.
    IRBuilder<> Builder(BasicBlock::Create(Context, "entry", NewFunc));

    // Map the wrapper's arguments to the callee's arguments.
    SmallVector<Argument *, 8> CallerArgs;
    for (Argument &Arg : NewFunc->args()) {
      CallerArgs.push_back(&Arg);
    }
    Argument *PodArg = CallerArgs.back();
    PodArg->setName("podargs");

    SmallVector<Value *, 8> CalleeArgs;
    unsigned podIndex = 0;
    unsigned ptrIndex = 0;
    for (const Argument &Arg : F->args()) {
      if (isa<PointerType>(Arg.getType())) {
        CalleeArgs.push_back(CallerArgs[ptrIndex++]);
      } else {
        CalleeArgs.push_back(Builder.CreateExtractValue(PodArg, {podIndex++}));
      }
      CalleeArgs.back()->setName(Arg.getName());
    }
    assert(ptrIndex + podIndex == F->arg_size());
    assert(ptrIndex = PtrArgTys.size());
    assert(podIndex = PodArgTys.size());

    auto Call = Builder.CreateCall(F, CalleeArgs);
    Call->setCallingConv(F->getCallingConv());

    Builder.CreateRetVoid();
  }

  return Changed;
}
