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

// Cluster POD kernel arguments.
//
// Collect plain-old-data kernel arguments and place them into a single
// struct argument, at the end.  Other arguments are pointers, and retain
// their relative order.
//
// We will create a kernel function as the new entry point, and change
// the original kernel function into a regular SPIR function.  Key
// kernel metadata is moved from the old function to the wrapper.
// We also attach a "kernel_arg_map" metadata node to the function to
// encode the mapping from old kernel argument to new kernel argument.

#include <cassert>
#include <cstring>

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "ArgKind.h"
#include "Passes.h"

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
INITIALIZE_PASS(ClusterPodKernelArgumentsPass, "ClusterPodKernelArgumentsPass",
                "Cluster POD Kernel Arguments Pass", false, false)

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

  SmallVector<CallInst *, 8> CallList;

  // Note: The transformation done in this pass preserves the pointer-to-local
  // arg to spec-id mapping.
  clspv::ArgIdMapType arg_spec_id_map = clspv::AllocateArgSpecIds(M);

  for (Function *F : WorkList) {
    Changed = true;

    // An ArgMapping describes how a kernel argument is remapped.
    struct ArgMapping {
      std::string name;
      // 0-based argument index in the old kernel function.
      unsigned old_index;
      // 0-based argument index in the new kernel function.
      int new_index;
      // Offset of the argument value within the new kernel argument.
      // This is always zero for non-POD arguments.  For a POD argument,
      // this is the byte offset within the POD arguments struct.
      unsigned offset;
      // Size of the argument
      unsigned arg_size;
      // Argument type.
      clspv::ArgKind arg_kind;
      // If non-negative, this argument is a pointer-to-local, and the value
      // here is the specialization constant id for the array size.
      int spec_id;
    };

    // In OpenCL, kernel arguments are either pointers or POD. A composite with
    // an element or member that is a pointer is not allowed.  So we'll use POD
    // as a shorthand for non-pointer.

    SmallVector<Type *, 8> PtrArgTys;
    SmallVector<Type *, 8> PodArgTys;
    SmallVector<ArgMapping, 8> RemapInfo;
    unsigned arg_index = 0;
    int new_index = 0;
    for (Argument &Arg : F->args()) {
      Type *ArgTy = Arg.getType();
      if (isa<PointerType>(ArgTy)) {
        PtrArgTys.push_back(ArgTy);
        const auto kind = clspv::GetArgKindForType(ArgTy);
        int spec_id = -1;
        if (kind == clspv::ArgKind::Local) {
          spec_id = arg_spec_id_map[&Arg];
          assert(spec_id > 0);
        }
        RemapInfo.push_back({std::string(Arg.getName()), arg_index, new_index++,
                             0u, 0u, kind, spec_id});
      } else {
        PodArgTys.push_back(ArgTy);
      }
      arg_index++;
    }

    // Put the pointer arguments first, and then POD arguments struct last.
    // Use StructType::get so we reuse types where possible.
    auto PodArgsStructTy = StructType::get(Context, PodArgTys);
    SmallVector<Type *, 8> NewFuncParamTys(PtrArgTys);
    NewFuncParamTys.push_back(PodArgsStructTy);

    // We've recorded the remapping for pointer arguments.  Now record the
    // remapping for POD arguments.
    {
      const DataLayout DL(&M);
      const auto StructLayout = DL.getStructLayout(PodArgsStructTy);
      arg_index = 0;
      int pod_index = 0;
      for (Argument &Arg : F->args()) {
        Type *ArgTy = Arg.getType();
        if (!isa<PointerType>(ArgTy)) {
          unsigned arg_size = DL.getTypeStoreSize(ArgTy);
          RemapInfo.push_back(
              {std::string(Arg.getName()), arg_index, new_index,
               unsigned(StructLayout->getElementOffset(pod_index++)), arg_size,
               clspv::GetArgKindForType(ArgTy), -1});
        }
        arg_index++;
      }
    }

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

    // Transfer attributes that don't apply to the POD arguments
    // to the new functions.
    auto Attributes = F->getAttributes();
    SmallVector<std::pair<unsigned, AttributeSet>, 8> AttrBuildInfo;

    // Return attributes have to come first
    if (Attributes.hasAttributes(AttributeList::ReturnIndex)) {
      auto idx = AttributeList::ReturnIndex;
      auto attrs = Attributes.getRetAttributes();
      AttrBuildInfo.push_back(std::make_pair(idx, attrs));
    }

    // Then attributes for non-POD parameters
    for (auto &rinfo : RemapInfo) {
      bool argIsPod = rinfo.arg_kind == clspv::ArgKind::Pod ||
                      rinfo.arg_kind == clspv::ArgKind::PodUBO;
      if (!argIsPod && Attributes.hasParamAttrs(rinfo.old_index)) {
        auto idx = rinfo.new_index + AttributeList::FirstArgIndex;
        auto attrs = Attributes.getParamAttributes(rinfo.old_index);
        AttrBuildInfo.push_back(std::make_pair(idx, attrs));
      }
    }

    // And finally function attributes.
    if (Attributes.hasAttributes(AttributeList::FunctionIndex)) {
      auto idx = AttributeList::FunctionIndex;
      auto attrs = Attributes.getFnAttributes();
      AttrBuildInfo.push_back(std::make_pair(idx, attrs));
    }
    auto newAttributes = AttributeList::get(M.getContext(), AttrBuildInfo);
    NewFunc->setAttributes(newAttributes);

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

    IRBuilder<> Builder(BasicBlock::Create(Context, "entry", NewFunc));

    // Set kernel argument mapping metadata.
    {
      // Attach a metadata node named "kernel_arg_map" to the new kernel
      // function.  It is a tuple of nodes, each of which is a tuple for
      // each argument, with members:
      //  - Argument name
      //  - Ordinal index in the original kernel function
      //  - Ordinal index in the new kernel function
      //  - Byte offset within the argument.  This is always 0 for pointer
      //    arguments.  For POD arguments this is the offest within the POD
      //    argument struct.
      //  - Argument type
      LLVMContext &Context = M.getContext();
      SmallVector<Metadata *, 8> mappings;
      for (auto &arg_mapping : RemapInfo) {
        auto *name_md = MDString::get(Context, arg_mapping.name);
        auto *old_index_md =
            ConstantAsMetadata::get(Builder.getInt32(arg_mapping.old_index));
        auto *new_index_md =
            ConstantAsMetadata::get(Builder.getInt32(arg_mapping.new_index));
        auto *offset_md =
            ConstantAsMetadata::get(Builder.getInt32(arg_mapping.offset));
        auto *arg_size_md =
            ConstantAsMetadata::get(Builder.getInt32(arg_mapping.arg_size));
        auto argKindName = GetArgKindName(arg_mapping.arg_kind);
        auto *argtype_md = MDString::get(Context, argKindName);
        auto *spec_id_md =
            ConstantAsMetadata::get(Builder.getInt32(arg_mapping.spec_id));
        auto *arg_md = MDNode::get(
            Context, {name_md, old_index_md, new_index_md, offset_md,
                      arg_size_md, argtype_md, spec_id_md});
        mappings.push_back(arg_md);
      }

      NewFunc->setMetadata("kernel_arg_map", MDNode::get(Context, mappings));
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
    assert(ptrIndex == PtrArgTys.size());
    assert(podIndex != 0);
    assert(podIndex == PodArgTys.size());

    auto Call = Builder.CreateCall(F, CalleeArgs);
    Call->setCallingConv(F->getCallingConv());
    CallList.push_back(Call);

    Builder.CreateRetVoid();
  }

  // Inline the inner function.  It's cleaner to do this.
  for (CallInst *C : CallList) {
    InlineFunctionInfo info;
    Changed |= InlineFunction(C, info);
  }

  return Changed;
}
