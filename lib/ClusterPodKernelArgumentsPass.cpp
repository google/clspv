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
#include "Constants.h"
#include "Passes.h"
#include "PushConstant.h"

using namespace llvm;

#define DEBUG_TYPE "clusterpodkernelargs"

namespace {
const uint64_t kIntBytes = 4;

struct ClusterPodKernelArgumentsPass : public ModulePass {
  static char ID;
  ClusterPodKernelArgumentsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  // Returns the type-mangled struct for global pod args. Only generates
  // unpacked structs currently. The type conversion code does not handle
  // packed structs propoerly. AutoPodArgsPass would also need updates to
  // support packed structs.
  StructType *GetTypeMangledPodArgsStruct(Module &M);

  // (Re-)Declares the global push constant variable with |mangled_struct_ty|
  // as the last member.
  void RedeclareGlobalPushConstants(Module &M, StructType *mangled_struct_ty);

  // Converts the corresponding elements of the global push constants for pod
  // args in member |index| of |pod_struct|.
  Value *ConvertToType(Module &M, StructType *pod_struct, unsigned index,
                       IRBuilder<> &builder);

  // Builds |dst_type| from |elements|, where |elements| is a vector i32 loads.
  Value *BuildFromElements(Module &M, IRBuilder<> &builder, Type *dst_type,
                           uint64_t base_offset, uint64_t base_index,
                           const std::vector<Value *> &elements);
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

  // If any of the kernels call for type-mangled push constants, we need to
  // know the right type and base offset.
  const uint64_t global_push_constant_size = clspv::GlobalPushConstantsSize(M);
  assert(global_push_constant_size % 16 == 0 &&
         "Global push constants size changed");
  auto mangled_struct_ty = GetTypeMangledPodArgsStruct(M);
  if (mangled_struct_ty) {
    RedeclareGlobalPushConstants(M, mangled_struct_ty);
  }

  for (Function *F : WorkList) {
    Changed = true;

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
        const auto kind = clspv::GetArgKind(Arg);
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
    if (Attributes.hasAttributes(AttributeList::ReturnIndex)) {
      auto idx = AttributeList::ReturnIndex;
      auto attrs = Attributes.getRetAttributes();
      AttrBuildInfo.push_back(std::make_pair(idx, attrs));
    }

    // Then attributes for non-POD parameters
    for (auto &rinfo : RemapInfo) {
      bool argIsPod = rinfo.arg_kind == clspv::ArgKind::Pod ||
                      rinfo.arg_kind == clspv::ArgKind::PodUBO ||
                      rinfo.arg_kind == clspv::ArgKind::PodPushConstant;
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
    Changed |= InlineFunction(*C, info).isSuccess();
  }

  return Changed;
}

StructType *
ClusterPodKernelArgumentsPass::GetTypeMangledPodArgsStruct(Module &M) {
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

void ClusterPodKernelArgumentsPass::RedeclareGlobalPushConstants(
    Module &M, StructType *mangled_struct_ty) {
  auto old_GV = M.getGlobalVariable(clspv::PushConstantsVariableName());

  std::vector<Type *> push_constant_tys;
  if (old_GV) {
    auto block_ty =
        cast<StructType>(old_GV->getType()->getPointerElementType());
    for (auto ele : block_ty->elements())
      push_constant_tys.push_back(ele);
  }
  push_constant_tys.push_back(mangled_struct_ty);

  auto push_constant_ty = StructType::create(M.getContext(), push_constant_tys);
  auto new_GV = new GlobalVariable(
      M, push_constant_ty, false, GlobalValue::ExternalLinkage, nullptr, "",
      nullptr, GlobalValue::ThreadLocalMode::NotThreadLocal,
      clspv::AddressSpace::PushConstant);
  new_GV->setInitializer(Constant::getNullValue(push_constant_ty));
  std::vector<Metadata *> md_args;
  if (old_GV) {
    // Replace the old push constant variable metadata and uses.
    new_GV->takeName(old_GV);
    auto md = old_GV->getMetadata(clspv::PushConstantsMetadataName());
    for (auto &op : md->operands()) {
      md_args.push_back(op.get());
    }
    std::vector<User *> users;
    for (auto user : old_GV->users())
      users.push_back(user);
    for (auto user : users) {
      if (auto gep = dyn_cast<GetElementPtrInst>(user)) {
        // Most uses are likely constant geps, but handle instructions first
        // since we can only really access gep operators for the constant side.
        SmallVector<Value *, 4> indices;
        for (auto iter = gep->idx_begin(); iter != gep->idx_end(); ++iter) {
          indices.push_back(*iter);
        }
        auto new_gep = GetElementPtrInst::Create(push_constant_ty, new_GV,
                                                 indices, "", gep);
        new_gep->setIsInBounds(gep->isInBounds());
        gep->replaceAllUsesWith(new_gep);
        new_gep->eraseFromParent();
      } else if (auto gep_operator = dyn_cast<GEPOperator>(user)) {
        SmallVector<Constant *, 4> indices;
        for (auto iter = gep_operator->idx_begin();
             iter != gep_operator->idx_end(); ++iter) {
          indices.push_back(cast<Constant>(*iter));
        }
        auto new_gep = ConstantExpr::getGetElementPtr(
            push_constant_ty, new_GV, indices, gep_operator->isInBounds());
        user->replaceAllUsesWith(new_gep);
      } else {
        assert(false && "unexpected global use");
      }
    }
    old_GV->removeDeadConstantUsers();
    old_GV->eraseFromParent();
  } else {
    new_GV->setName(clspv::PushConstantsVariableName());
  }
  // New metadata operand for the kernel arguments.
  auto cst =
      ConstantInt::get(IntegerType::get(M.getContext(), 32),
                       static_cast<int>(clspv::PushConstant::KernelArgument));
  md_args.push_back(ConstantAsMetadata::get(cst));
  new_GV->setMetadata(clspv::PushConstantsMetadataName(),
                      MDNode::get(M.getContext(), md_args));
}

Value *ClusterPodKernelArgumentsPass::ConvertToType(Module &M,
                                                    StructType *pod_struct,
                                                    unsigned index,
                                                    IRBuilder<> &builder) {
  auto int32_ty = IntegerType::get(M.getContext(), 32);
  const auto &DL = M.getDataLayout();
  const auto struct_layout = DL.getStructLayout(pod_struct);
  auto ele_ty = pod_struct->getElementType(index);
  const auto ele_size = DL.getTypeStoreSize(ele_ty).getKnownMinSize();
  auto ele_offset = struct_layout->getElementOffset(index);
  const auto ele_start_index = ele_offset / kIntBytes; // round down
  const auto ele_end_index =
      (ele_offset + ele_size + kIntBytes - 1) / kIntBytes; // round up

  // Load the right number of ints. We'll load at least one, but may load
  // ele_size / 4 + 1 integers depending on the offset.
  std::vector<Value *> int_elements;
  uint32_t i = ele_start_index;
  do {
    auto gep = clspv::GetPushConstantPointer(
        builder.GetInsertBlock(), clspv::PushConstant::KernelArgument,
        {builder.getInt32(i)});
    auto ld = builder.CreateLoad(int32_ty, gep);
    int_elements.push_back(ld);
    i++;
  } while (i < ele_end_index);

  return BuildFromElements(M, builder, ele_ty, ele_offset % kIntBytes, 0,
                           int_elements);
}

Value *ClusterPodKernelArgumentsPass::BuildFromElements(
    Module &M, IRBuilder<> &builder, Type *dst_type, uint64_t base_offset,
    uint64_t base_index, const std::vector<Value *> &elements) {
  auto int32_ty = IntegerType::get(M.getContext(), 32);
  const auto &DL = M.getDataLayout();
  const auto dst_size = DL.getTypeStoreSize(dst_type).getKnownMinSize();
  auto dst_array_ty = dyn_cast<ArrayType>(dst_type);
  auto dst_vec_ty = dyn_cast<VectorType>(dst_type);

  Value *dst = nullptr;
  if (auto dst_struct_ty = dyn_cast<StructType>(dst_type)) {
    // Create an insertvalue chain for each converted element.
    auto struct_layout = DL.getStructLayout(dst_struct_ty);
    for (uint32_t i = 0; i < dst_struct_ty->getNumElements(); ++i) {
      auto ele_ty = dst_struct_ty->getTypeAtIndex(i);
      const auto ele_offset = struct_layout->getElementOffset(i);
      const auto index = base_index + (ele_offset / kIntBytes);
      const auto offset = (base_offset + ele_offset) % kIntBytes;

      auto tmp = BuildFromElements(M, builder, ele_ty, offset, index, elements);
      dst = builder.CreateInsertValue(dst ? dst : UndefValue::get(dst_type),
                                      tmp, {i});
    }
  } else if (dst_array_ty || dst_vec_ty) {
    if (dst_vec_ty && dst_vec_ty->getPrimitiveSizeInBits() ==
                          int32_ty->getPrimitiveSizeInBits()) {
      // Easy case is just a bitcast.
      dst = builder.CreateBitCast(elements[base_index], dst_type);
    } else if (dst_vec_ty &&
               dst_vec_ty->getElementType()->getPrimitiveSizeInBits() <
                   int32_ty->getPrimitiveSizeInBits()) {
      // Bitcast integers to a vector of the primitive type and then shuffle
      // elements into the final vector.
      //
      // We need at most two integers to handle any case here.
      auto ele_ty = dst_vec_ty->getElementType();
      uint32_t num_elements = dst_vec_ty->getElementCount().Min;
      assert(num_elements <= 4 && "Unhandled large vectors");
      uint32_t ratio = (int32_ty->getPrimitiveSizeInBits() /
                        ele_ty->getPrimitiveSizeInBits())
                           .getKnownMinSize();
      auto scaled_vec_ty = VectorType::get(ele_ty, ratio);
      Value *casts[2] = {UndefValue::get(scaled_vec_ty),
                         UndefValue::get(scaled_vec_ty)};
      uint32_t num_ints = (num_elements + ratio - 1) / ratio; // round up
      num_ints = std::max(num_ints, 1u);
      for (uint32_t i = 0; i < num_ints; ++i) {
        casts[i] =
            builder.CreateBitCast(elements[base_index + i], scaled_vec_ty);
      }
      SmallVector<int, 4> indices(num_elements);
      uint32_t i = 0;
      std::generate_n(indices.data(), num_elements, [&i]() { return i++; });
      dst = builder.CreateShuffleVector(casts[0], casts[1], indices);
    } else {
      // General case, break into elements and construct the composite type.
      auto ele_ty = dst_vec_ty ? dst_vec_ty->getElementType()
                               : dst_array_ty->getElementType();
      assert((DL.getTypeStoreSize(ele_ty).getKnownMinSize() < kIntBytes ||
              base_offset == 0) &&
             "Unexpected packed data format");
      uint64_t ele_size = DL.getTypeStoreSize(ele_ty);
      uint32_t num_elements = dst_vec_ty ? dst_vec_ty->getElementCount().Min
                                         : dst_array_ty->getNumElements();

      // Arrays of shorts/halfs could be offset from the start of an int.
      uint64_t bytes_consumed = 0;
      for (uint32_t i = 0; i < num_elements; ++i) {
        uint64_t ele_offset = (base_offset + bytes_consumed) % kIntBytes;
        uint64_t ele_index =
            base_index + (base_offset + bytes_consumed) / kIntBytes;
        // Convert the element.
        auto tmp = BuildFromElements(M, builder, ele_ty, ele_offset, ele_index,
                                     elements);
        if (dst_vec_ty) {
          dst = builder.CreateInsertElement(
              dst ? dst : UndefValue::get(dst_type), tmp, i);
        } else {
          dst = builder.CreateInsertValue(dst ? dst : UndefValue::get(dst_type),
                                          tmp, {i});
        }

        // Track consumed bytes.
        bytes_consumed += ele_size;
      }
    }
  } else {
    // Base case is scalar conversion.
    if (dst_size < kIntBytes) {
      dst = elements[base_index];
      if (dst_type->isIntegerTy() && base_offset == 0) {
        // Can generate a single truncate instruction in this case.
        dst = builder.CreateTrunc(
            dst, IntegerType::get(M.getContext(), dst_size * 8));
      } else {
        // Bitcast to a vector of |dst_type| and extract the right element. This
        // avoids introducing i16 when converting to half.
        uint32_t ratio = (int32_ty->getPrimitiveSizeInBits() /
                          dst_type->getPrimitiveSizeInBits())
                             .getKnownMinSize();
        auto vec_ty = VectorType::get(dst_type, ratio);
        dst = builder.CreateBitCast(dst, vec_ty);
        dst = builder.CreateExtractElement(dst, base_offset / dst_size);
      }
    } else if (dst_size == kIntBytes) {
      assert(base_offset == 0 && "Unexpected packed data format");
      // Create a bit cast if necessary.
      dst = elements[base_index];
      if (dst_type != int32_ty)
        dst = builder.CreateBitCast(dst, dst_type);
    } else {
      assert(base_offset == 0 && "Unexpected packed data format");
      assert(dst_size == kIntBytes * 2 && "Expected 64-bit scalar");
      // Round up to number of integers.
      auto dst_int = IntegerType::get(M.getContext(), dst_size * 8);
      auto zext0 = builder.CreateZExt(elements[base_index], dst_int);
      auto zext1 = builder.CreateZExt(elements[base_index + 1], dst_int);
      auto shl = builder.CreateShl(zext1, 32);
      dst = builder.CreateOr({zext0, shl});
      if (dst_type != dst->getType())
        dst = builder.CreateBitCast(dst, dst_type);
    }
  }

  return dst;
}
