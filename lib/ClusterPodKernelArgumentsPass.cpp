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

#include <algorithm>
#include <cassert>
#include <cstring>

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "ArgKind.h"
#include "ClusterPodKernelArgumentsPass.h"
#include "Constants.h"
#include "PushConstant.h"
#include "Types.h"

using namespace llvm;

namespace {
const uint64_t kIntBytes = 4;
} // namespace

PreservedAnalyses
clspv::ClusterPodKernelArgumentsPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  if (!clspv::Option::ClusterPodKernelArgs())
    return PA;

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

  // If any of the kernels call for type-mangled push constants, we need to
  // know the right type and base offset.
  const uint64_t global_push_constant_size = clspv::GlobalPushConstantsSize(M);
  assert(global_push_constant_size % 16 == 0 &&
         "Global push constants size changed");
  auto mangled_struct_ty = GetTypeMangledPodArgsStruct(M);
  if (mangled_struct_ty) {
    clspv::RedeclareGlobalPushConstants(
        M, mangled_struct_ty, (int)clspv::PushConstant::KernelArgument);
  }

  DenseMap<Value *, Type *> type_cache;
  for (Function *F : WorkList) {
    auto pod_arg_impl = clspv::GetPodArgsImpl(*F);
    auto pod_arg_kind = clspv::GetArgKindForPodArgs(*F);
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
    };

    // In OpenCL, kernel arguments are either pointers or POD. A composite with
    // an element or member that is a pointer is not allowed.  So we'll use POD
    // as a shorthand for non-pointer.

    SmallVector<Type *, 8> PtrArgTys;
    SmallVector<Type *, 8> PodArgTys;
    SmallVector<ArgMapping, 8> RemapInfo;
    DenseMap<Argument *, unsigned> PodIndexMap;
    unsigned arg_index = 0;
    int new_index = 0;
    unsigned pod_index = 0;
    for (Argument &Arg : F->args()) {
      Type *ArgTy = Arg.getType();
      if (isa<PointerType>(ArgTy)) {
        PtrArgTys.push_back(ArgTy);
        auto *inferred_ty = clspv::InferType(&Arg, M.getContext(), &type_cache);
        const auto kind = clspv::GetArgKind(Arg, inferred_ty);
        RemapInfo.push_back(
            {std::string(Arg.getName()), arg_index, new_index++, 0u, 0u, kind});
      } else {
        PodIndexMap[&Arg] = pod_index++;
        PodArgTys.push_back(ArgTy);
      }
      arg_index++;
    }

    // Put the pointer arguments first, and then POD arguments struct last.
    // Use StructType::get so we reuse types where possible.
    auto PodArgsStructTy = StructType::get(Context, PodArgTys);
    SmallVector<Type *, 8> NewFuncParamTys(PtrArgTys);

    if (pod_arg_impl == clspv::PodArgImpl::kUBO &&
        !clspv::Option::Std430UniformBufferLayout()) {
      SmallVector<Type *, 16> PaddedPodArgTys;
      const DataLayout DL(&M);
      const auto StructLayout = DL.getStructLayout(PodArgsStructTy);
      unsigned pod_index = 0;
      for (auto &Arg : F->args()) {
        auto arg_type = Arg.getType();
        if (arg_type->isPointerTy())
          continue;

        // The frontend has validated individual POD arguments. When the
        // unified struct is constructed, pad struct and array elements as
        // necessary to achieve a 16-byte alignment.
        if (arg_type->isStructTy() || arg_type->isArrayTy()) {
          auto offset = StructLayout->getElementOffset(pod_index);
          auto aligned = alignTo(offset, 16);
          if (offset < aligned) {
            auto int_ty = IntegerType::get(Context, 32);
            auto char_ty = IntegerType::get(Context, 8);
            size_t num_ints = (aligned - offset) / 4;
            size_t num_chars = (aligned - offset) - (num_ints * 4);
            assert((num_chars == 0 || clspv::Option::Int8Support()) &&
                   "Char in UBO struct without char support");
            // Fix the index for the offset of the argument.
            // Add char padding first.
            PodIndexMap[&Arg] += num_ints + num_chars;
            for (size_t i = 0; i < num_chars; ++i) {
              PaddedPodArgTys.push_back(char_ty);
            }
            for (size_t i = 0; i < num_ints; ++i) {
              PaddedPodArgTys.push_back(int_ty);
            }
          }
        }
        ++pod_index;
        PaddedPodArgTys.push_back(arg_type);
      }
      PodArgsStructTy = StructType::get(Context, PaddedPodArgTys);
    }

    if (pod_arg_impl != clspv::PodArgImpl::kGlobalPushConstant) {
      NewFuncParamTys.push_back(PodArgsStructTy);
    }

    // We've recorded the remapping for pointer arguments.  Now record the
    // remapping for POD arguments.
    {
      const DataLayout DL(&M);
      const auto StructLayout = DL.getStructLayout(PodArgsStructTy);
      arg_index = 0;
      for (Argument &Arg : F->args()) {
        Type *ArgTy = Arg.getType();
        if (!isa<PointerType>(ArgTy)) {
          unsigned arg_size = DL.getTypeStoreSize(ArgTy);
          unsigned offset = StructLayout->getElementOffset(PodIndexMap[&Arg]);
          int remapped_index = new_index;
          if (pod_arg_impl == clspv::PodArgImpl::kGlobalPushConstant) {
            offset += global_push_constant_size;
            remapped_index = -1;
          }
          RemapInfo.push_back({std::string(Arg.getName()), arg_index,
                               remapped_index, offset, arg_size, pod_arg_kind});
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
    const auto retAttrs = Attributes.getRetAttrs();
    if (retAttrs.hasAttributes()) {
      auto idx = AttributeList::ReturnIndex;
      AttrBuildInfo.push_back(std::make_pair(idx, retAttrs));
    }

    // Then attributes for non-POD parameters
    for (auto &rinfo : RemapInfo) {
      bool argIsPod = rinfo.arg_kind == clspv::ArgKind::Pod ||
                      rinfo.arg_kind == clspv::ArgKind::PodUBO ||
                      rinfo.arg_kind == clspv::ArgKind::PodPushConstant;
      if (!argIsPod && Attributes.hasParamAttrs(rinfo.old_index)) {
        auto idx = rinfo.new_index + AttributeList::FirstArgIndex;
        auto attrs = Attributes.getParamAttrs(rinfo.old_index);
        AttrBuildInfo.push_back(std::make_pair(idx, attrs));
      }
    }

    // And finally function attributes.
    const auto fnAttrs = Attributes.getFnAttrs();
    if (fnAttrs.hasAttributes()) {
      auto idx = AttributeList::FunctionIndex;
      AttrBuildInfo.push_back(std::make_pair(idx, fnAttrs));
    }
    auto newAttributes = AttributeList::get(M.getContext(), AttrBuildInfo);
    NewFunc->setAttributes(newAttributes);

    // Move OpenCL kernel named attributes.
    // TODO(dneto): Attributes starting with kernel_arg_* should be rewritten
    // to reflect change in the argument shape.
    auto pod_md_name = clspv::PodArgsImplMetadataName();
    std::vector<const char *> Metadatas{
        "reqd_work_group_size",   "kernel_arg_addr_space",
        "kernel_arg_access_qual", "kernel_arg_type",
        "kernel_arg_base_type",   "kernel_arg_type_qual",
        pod_md_name.c_str()};
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
        auto *arg_md =
            MDNode::get(Context, {name_md, old_index_md, new_index_md,
                                  offset_md, arg_size_md, argtype_md});
        mappings.push_back(arg_md);
      }

      NewFunc->setMetadata(clspv::KernelArgMapMetadataName(),
                           MDNode::get(Context, mappings));
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
    Value *PodArg = nullptr;
    if (pod_arg_impl != clspv::PodArgImpl::kGlobalPushConstant) {
      Argument *pod_arg = CallerArgs.back();
      pod_arg->setName("podargs");
      PodArg = pod_arg;
    }

    SmallVector<Value *, 8> CalleeArgs;
    unsigned podCount = 0;
    unsigned ptrIndex = 0;
    for (Argument &Arg : F->args()) {
      if (isa<PointerType>(Arg.getType())) {
        CalleeArgs.push_back(CallerArgs[ptrIndex++]);
      } else {
        podCount++;
        unsigned podIndex = PodIndexMap[&Arg];
        if (pod_arg_impl == clspv::PodArgImpl::kGlobalPushConstant) {
          auto reconstructed =
              ConvertToType(M, PodArgsStructTy, podIndex, Builder);
          CalleeArgs.push_back(reconstructed);
        } else {
          CalleeArgs.push_back(Builder.CreateExtractValue(PodArg, {podIndex}));
        }
      }
      CalleeArgs.back()->setName(Arg.getName());
    }
    assert(ptrIndex + podCount == F->arg_size());
    assert(ptrIndex == PtrArgTys.size());
    assert(podCount != 0);
    assert(podCount == PodArgTys.size());

    auto Call = Builder.CreateCall(F, CalleeArgs);
    Call->setCallingConv(F->getCallingConv());
    CallList.push_back(Call);

    Builder.CreateRetVoid();
  }

  // Inline the inner function.  It's cleaner to do this.
  for (CallInst *C : CallList) {
    InlineFunctionInfo info;
    InlineFunction(*C, info).isSuccess();
  }

  return PA;
}

StructType *
clspv::ClusterPodKernelArgumentsPass::GetTypeMangledPodArgsStruct(Module &M) {
  // If we are using global type-mangled push constants for any kernel we need
  // to figure out what the shared representation will be. Calculate the max
  // number of integers needed to satisfy all kernels.
  uint64_t max_pod_args_size = 0;
  const auto &DL = M.getDataLayout();
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    auto pod_arg_impl = clspv::GetPodArgsImpl(F);
    if (pod_arg_impl != clspv::PodArgImpl::kGlobalPushConstant)
      continue;

    SmallVector<Type *, 8> PodArgTys;
    for (auto &Arg : F.args()) {
      if (!Arg.getType()->isPointerTy()) {
        PodArgTys.push_back(Arg.getType());
      }
    }

    // TODO: The type-mangling code will need updated if we want to support
    // packed structs.
    auto struct_ty = StructType::get(M.getContext(), PodArgTys);
    uint64_t size = alignTo(DL.getTypeStoreSize(struct_ty), kIntBytes);
    if (size > max_pod_args_size)
      max_pod_args_size = size;
  }

  if (max_pod_args_size > 0) {
    auto int_ty = IntegerType::get(M.getContext(), 32);
    std::vector<Type *> global_pod_arg_tys(max_pod_args_size / kIntBytes,
                                           int_ty);
    return StructType::create(M.getContext(), global_pod_arg_tys);
  }

  return nullptr;
}
