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

#include <climits>
#include <string>

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"

#include "ArgKind.h"
#include "DescriptorCounter.h"

using namespace llvm;

#define DEBUG_TYPE "allocatedescriptors"

namespace {

cl::opt<bool> ShowDescriptors("show-desc", cl::init(false), cl::Hidden,
                              cl::desc("Show descriptors"));

using SamplerMapType = llvm::ArrayRef<std::pair<unsigned, std::string>>;

class AllocateDescriptorsPass final : public ModulePass {
public:
  static char ID;
  AllocateDescriptorsPass()
      : ModulePass(ID), sampler_map_(), descriptor_set_(0), binding_(0) {}
  bool runOnModule(Module &M) override;

  SamplerMapType &sampler_map() { return sampler_map_; }

private:
  // Allocates descriptors for all samplers and kernel arguments that have uses.
  // Replace their uses with calls to a special compiler builtin.  Returns true
  // if we changed the module.
  bool AllocateDescriptors(Module &M);

  // Allocate descriptor for literal samplers.  Returns true if we changed the
  // module.
  bool AllocateLiteralSamplerDescriptors(Module &M);

  // Allocate descriptor for kernel arguments with uses.  Returns true if we
  // changed the module.
  bool AllocateKernelArgDescriptors(Module &M);

  // Allocates the next descriptor set and resets the tracked binding number to
  // 0.
  unsigned StartNewDescriptorSet(Module &M) {
    // Allocate the descriptor set we used.
    unsigned result = descriptor_set_++;
    binding_ = 0;
    const auto set = clspv::TakeDescriptorIndex(&M);
    assert(set == result);
    return result;
  }

  // The sampler map, which is an array ref of pairs, each of which is the
  // sampler constant as an integer, followed by the string expression for
  // the sampler.
  SamplerMapType sampler_map_;

  // Which descriptor set are we using?
  int descriptor_set_;
  // The next binding number to use.
  int binding_;

  // What makes a kernel argument require a new descriptor?
  struct KernelArgDiscriminant {
    KernelArgDiscriminant() : type(nullptr), arg_index(0) {}
    KernelArgDiscriminant(Type *the_type, int the_arg_index)
        : type(the_type), arg_index(the_arg_index) {}
    // Different argument type requires different descriptor since logical
    // addressing requires strongly typed storage buffer variables.
    Type *type;
    // If we have multiple arguments of the same type to the same kernel,
    // then we have to use distinct descriptors because the user could
    // bind different storage buffers for them.  Use argument index
    // as a proxy for distinctness.  This might overcount, but we
    // don't worry about yet.
    int arg_index;
  };
  struct KADDenseMapInfo {
    static KernelArgDiscriminant getEmptyKey() {
      return KernelArgDiscriminant(nullptr, 0);
    }
    static KernelArgDiscriminant getTombstoneKey() {
      return KernelArgDiscriminant(nullptr, -1);
    }
    static unsigned getHashValue(const KernelArgDiscriminant &key) {
      return unsigned(uintptr_t(key.type)) ^ key.arg_index;
    }
    static bool isEqual(const KernelArgDiscriminant &lhs,
                        const KernelArgDiscriminant &rhs) {
      return lhs.type == rhs.type && lhs.arg_index == rhs.arg_index;
    }
  };

  // Map a descriminant to a unique index.  We don't use a UniqueVector
  // because that requires operator< that I don't want to define on
  // llvm::Type*
  using KernelArgDiscriminantMap =
      DenseMap<KernelArgDiscriminant, int, KADDenseMapInfo>;

  // Maps a discriminant to its unique index, starting at 0.
  KernelArgDiscriminantMap discriminant_map_;
};
} // namespace

char AllocateDescriptorsPass::ID = 0;
static RegisterPass<AllocateDescriptorsPass> X("AllocateDescriptorsPass",
                                               "Allocate resource descriptors");

namespace clspv {
ModulePass *createAllocateDescriptorsPass(SamplerMapType sampler_map) {
  auto *result = new AllocateDescriptorsPass();
  result->sampler_map() = sampler_map;
  return result;
}
} // namespace clspv

bool AllocateDescriptorsPass::runOnModule(Module &M) {
  bool Changed = false;

  // Samplers from the sampler map always grab descriptor set 0.
  Changed |= AllocateLiteralSamplerDescriptors(M);
  Changed |= AllocateKernelArgDescriptors(M);

  return Changed;
}

bool AllocateDescriptorsPass::AllocateLiteralSamplerDescriptors(Module &M) {
  if (ShowDescriptors) {
    outs() << "Allocate literal sampler descriptors\n";
  }
  bool Changed = false;
  auto init_fn = M.getFunction("__translate_sampler_initializer");
  if (init_fn && sampler_map_.size() == 0) {
    errs() << "error: kernel uses a literal sampler but option -samplermap "
              "has not been specified\n";
    llvm_unreachable("Sampler literal in source without sampler map!");
  }
  if (sampler_map_.size()) {
    const unsigned descriptor_set = StartNewDescriptorSet(M);
    Changed = true;
    if (ShowDescriptors) {
      outs() << "  Found " << sampler_map_.size()
             << " samplers in the sampler map\n";
    }
    // Replace all things that look like
    //  call %opencl.sampler_t addrspace(2)*
    //     @__translate_sampler_initializer(i32 sampler-literal-constant-value)
    //     #2
    //
    // with:
    //
    //   call %opencl.sampler_t addrspace(2)*
    //       @clspv.sampler.var.literal(i32 descriptor set, i32 binding, i32
    //       index-into-sampler-map)
    //
    // We need to preserve the index into the sampler map so that later we can
    // generate the sampler lines in the descriptor map. That needs both the
    // literal value and the string expression for the literal.

    // Generate the function type for %clspv.sampler.var.literal
    IRBuilder<> Builder(M.getContext());
    auto *sampler_struct_ty = M.getTypeByName("opencl.sampler_t");
    if (!sampler_struct_ty) {
      sampler_struct_ty =
          StructType::create(M.getContext(), "opencl.sampler_t");
    }
    auto *sampler_ty =
        sampler_struct_ty->getPointerTo(clspv::AddressSpace::Constant);
    Type *i32 = Builder.getInt32Ty();
    FunctionType *fn_ty = FunctionType::get(sampler_ty, {i32, i32, i32}, false);

    auto *var_fn = M.getOrInsertFunction("clspv.sampler.var.literal", fn_ty);

    // Map sampler literal to binding number.
    DenseMap<unsigned, unsigned> binding_for_value;
    DenseMap<unsigned, unsigned> index_for_value;
    unsigned index = 0;
    for (auto sampler_info : sampler_map_) {
      const unsigned value = sampler_info.first;
      const std::string &expr = sampler_info.second;
      if (0 == binding_for_value.count(value)) {
        // Make a new entry.
        binding_for_value[value] = binding_++;
        index_for_value[value] = index;
        if (ShowDescriptors) {
          outs() << "  Map " << value << " to (" << descriptor_set << ","
                 << binding_for_value[value] << ") << " << expr << "\n";
        }
      }
      index++;
    }

    // Now replace calls to __translate_sampler_initializer
    if (init_fn) {
      for (auto user : init_fn->users()) {
        if (auto *call = dyn_cast<CallInst>(user)) {
          auto const_val = dyn_cast<ConstantInt>(call->getArgOperand(0));

          if (!const_val) {
            call->getArgOperand(0)->print(errs());
            llvm_unreachable(
                "Argument of sampler initializer was non-constant!");
          }

          const auto value = static_cast<unsigned>(const_val->getZExtValue());

          auto where = binding_for_value.find(value);
          if (where == binding_for_value.end()) {
            errs() << "Sampler literal " << value
                   << " was not in the sampler map\n";
            llvm_unreachable("Sampler literal was not found in sampler map!");
          }
          const unsigned binding = binding_for_value[value];
          const unsigned index = index_for_value[value];

          SmallVector<Value *, 3> args = {Builder.getInt32(descriptor_set),
                                          Builder.getInt32(binding),
                                          Builder.getInt32(index)};
          if (ShowDescriptors) {
            outs() << "  translate literal sampler " << *const_val << " to ("
                   << descriptor_set << "," << binding << ")\n";
          }
          auto *new_call =
              CallInst::Create(var_fn, args, "", dyn_cast<Instruction>(call));
          call->replaceAllUsesWith(new_call);
          call->eraseFromParent();
        }
      }
      init_fn->eraseFromParent();
    }
  } else {
    if (ShowDescriptors) {
      outs() << "  No sampler\n";
    }
  }
  return Changed;
}

bool AllocateDescriptorsPass::AllocateKernelArgDescriptors(Module &M) {
  bool Changed = false;
  if (ShowDescriptors) {
    outs() << "Allocate kernel arg descriptors\n";
  }
  discriminant_map_.clear();

  const bool always_distinct_sets =
      clspv::Option::DistinctKernelDescriptorSets();

  // First classify all kernel arguments by arg discriminant which
  // is the pair (type, arg index).  Each discriminant remembers which
  // functions it's used by.  Each function remembers the pairs associated
  // with each argument.

  // Maps an arg discriminant index to the list of functions using that
  // discriminant.
  using FunctionsUsedByDiscriminantMap =
      SmallVector<SmallVector<Function *, 3>, 3>;
  FunctionsUsedByDiscriminantMap functions_used_by_discriminant;

  struct DiscriminantInfo {
    int index;
    KernelArgDiscriminant discriminant;
  };
  // Maps a function to an ordered list of discriminants and their.  The -1
  // value is a sentinel indicating the argument does not use a descriptor.
  DenseMap<Function *, SmallVector<DiscriminantInfo, 3>>
      discriminants_used_by_function;

  // Remember the list of kernels with bodies, for convenience.
  SmallVector<Function *, 3> kernels_with_bodies;

  for (Function &F : M) {
    // Only scan arguments of kernel functions that have bodies.
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    kernels_with_bodies.push_back(&F);
    auto &discriminants_list = discriminants_used_by_function[&F];

    int arg_index = 0;
    for (Argument &Arg : F.args()) {
      Type *argTy = Arg.getType();

      KernelArgDiscriminant key{argTy, arg_index};

      // First assume no descriptor is required.
      discriminants_list.push_back(DiscriminantInfo{-1, key});

      // Pointer-to-local arguments don't become resource variables.
      const auto arg_kind = clspv::GetArgKindForType(argTy);
      if (arg_kind == clspv::ArgKind::Local) {
        if (ShowDescriptors) {
          errs() << "DBA: skip pointer-to-local\n\n";
        }
      } else {
        int index;
        auto where = discriminant_map_.find(key);
        if (where == discriminant_map_.end()) {
          index = int(discriminant_map_.size());
          // Save the new unique index for this discriminant.
          discriminant_map_[key] = index;
          functions_used_by_discriminant.push_back(
              SmallVector<Function *, 3>{&F});
        } else {
          index = where->second;
          functions_used_by_discriminant[index].push_back(&F);
        }
        discriminants_list.back().index = index;
        if (ShowDescriptors) {
          outs() << F.getName() << " " << Arg.getName() << " -> index " << index
                 << "\n";
        }
      }

      arg_index++;
    }
  }

  // Now map kernel arguments to descriptor sets and bindings.
  // There are two buckets of descriptor sets:
  // - The all_kernels_descriptor_set is for resources that are used
  //   by all kernels in the module.
  // - Otherwise, each kernel gets is own descriptor set for its
  //   arguments that don't map to the same discriminant in *all*
  //   kernels. (It might map to a few, but not all.)
  // The kUnallocated descriptor set value means "not yet allocated".
  enum { kUnallocated = UINT_MAX };
  unsigned all_kernels_descriptor_set = kUnallocated;
  // Map the arg index to the binding to use in the all-descriptors descriptor
  // set.
  DenseMap<int, unsigned> all_kernels_binding_for_arg_index;

  // Maps a function to the list of set and binding to use, per argument.
  // For an argument that does no use a descriptor, its set and binding are
  // both the kUnallocated value.
  DenseMap<Function *, SmallVector<std::pair<unsigned, unsigned>, 3>>
      set_and_binding_pairs_for_function;

  // Determine set and binding for each kernel argument requiring a descriptor.
  if (always_distinct_sets) {
    for (Function *f_ptr : kernels_with_bodies) {
      auto &set_and_binding_list = set_and_binding_pairs_for_function[f_ptr];
      auto &discriminants_list = discriminants_used_by_function[f_ptr];
      const auto set = clspv::TakeDescriptorIndex(&M);
      unsigned binding = 0;
      int arg_index = 0;
      for (Argument &Arg : f_ptr->args()) {
        set_and_binding_list.emplace_back(kUnallocated, kUnallocated);
        if (discriminants_list[arg_index].index >= 0) {
          set_and_binding_list.back().first = set;
          set_and_binding_list.back().second = binding++;
        }
        arg_index++;
      }
    }
  } else {
    // Share as much as possible.
    for (Function *f_ptr : kernels_with_bodies) {
      unsigned this_kernel_descriptor_set = kUnallocated;
      unsigned this_kernel_next_binding = 0;

      auto &discriminants_list = discriminants_used_by_function[f_ptr];

      int arg_index = 0;

      auto &set_and_binding_list = set_and_binding_pairs_for_function[f_ptr];
      for (auto &info : discriminants_used_by_function[f_ptr]) {
        set_and_binding_list.emplace_back(kUnallocated, kUnallocated);
        if (discriminants_list[arg_index].index >= 0) {
          // This argument will map to a resource.
          unsigned set = kUnallocated;
          unsigned binding = kUnallocated;
          if (functions_used_by_discriminant[info.index].size() ==
              kernels_with_bodies.size()) {
            // This kernel argument discriminant is consistent across all
            // kernels. Reuse the descriptor.
            if (all_kernels_descriptor_set == kUnallocated) {
              all_kernels_descriptor_set = clspv::TakeDescriptorIndex(&M);
            }
            set = all_kernels_descriptor_set;
            auto where = all_kernels_binding_for_arg_index.find(arg_index);
            if (where == all_kernels_binding_for_arg_index.end()) {
              binding = all_kernels_binding_for_arg_index.size();
              all_kernels_binding_for_arg_index[arg_index] = binding;
            } else {
              binding = where->second;
            }
          } else {
            // Use a descriptor in the descriptor set dedicated to this
            // kernel.
            if (this_kernel_descriptor_set == kUnallocated) {
              this_kernel_descriptor_set = clspv::TakeDescriptorIndex(&M);
            }
            set = this_kernel_descriptor_set;
            binding = this_kernel_next_binding++;
          }
          set_and_binding_list.back().first = set;
          set_and_binding_list.back().second = binding;
        }
        arg_index++;
      }
    }
  }

  // Rewrite the uses of the arguments.
  IRBuilder<> Builder(M.getContext());
  for (Function *f_ptr : kernels_with_bodies) {
    auto &set_and_binding_list = set_and_binding_pairs_for_function[f_ptr];
    auto &discriminants = discriminants_used_by_function[f_ptr];
    const auto num_args = unsigned(set_and_binding_list.size());
    if (!always_distinct_sets && (num_args != unsigned(discriminants.size()))) {
      errs() << "num_args " << num_args << " != num discriminants "
             << discriminants.size() << "\n";
      llvm_unreachable("Bad accounting in descriptor allocation");
    }
    const auto num_fun_args = unsigned(f_ptr->arg_end() - f_ptr->arg_begin());
    if (num_fun_args != num_args) {
      errs() << f_ptr->getName() << " has " << num_fun_args
             << " params but we have set_and_binding list of length "
             << num_args << "\n";
      errs() << *f_ptr << "\n";
      errs() << *(f_ptr->getType()) << "\n";
      for (auto &arg : f_ptr->args()) {
        errs() << "   " << arg << "\n";
      }
      llvm_unreachable("Bad accounting in descriptor allocation. Mismatch with "
                       "function param list");
    }

    // Prepare to insert arg remapping instructions at the start of the
    // function.
    Builder.SetInsertPoint(f_ptr->getEntryBlock().getFirstNonPHI());

    int arg_index = 0;
    for (Argument &Arg : f_ptr->args()) {
      if (discriminants[arg_index].index >= 0) {
        // This argument needs to be rewritten.

        const auto set = set_and_binding_list[arg_index].first;
        const auto binding = set_and_binding_list[arg_index].second;
#if 0
        // TODO(dneto) Should we ignore unused arguments?  It's probably not an
        // issue in practice.  Adding this condition would change a bunch of our
        // tests.
        if (!Arg.hasNUsesOrMore(1)) {
          continue;
        }
#endif

        Type *argTy = discriminants[arg_index].discriminant.type;
        assert(arg_index == discriminants[arg_index].discriminant.arg_index);

        if (ShowDescriptors) {
          outs() << "DBA: Function " << f_ptr->getName() << " arg " << arg_index
                 << " type " << *argTy << "\n";
        }

        const auto arg_kind = clspv::GetArgKindForType(argTy);

        Type *resource_type = nullptr;
        unsigned addr_space = kUnallocated;

        // TODO(dneto): Describe opaque case.
        // For pointer-to-global and POD arguments, we will remap this
        // kernel argument to a SPIR-V module-scope OpVariable, as follows:
        //
        // Create a %clspv.resource.var.<kind>.N function that returns
        // the same kind of pointer that the OpVariable evaluates to.
        // The first two arguments are the descriptor set and binding
        // to use.
        //
        // For each call to a %clspv.resource.var.<kind>.N with a unique
        // descriptor set and binding, the SPIRVProducer pass will:
        // 1) Create a unique OpVariable
        // 2) Map uses of the call to the function with the base pointer
        // to use.
        //   For a storage buffer it's the the elements in the runtime
        // array in the module-scope storage buffer variable.
        // So it's something that maps to:
        //     OpAccessChain %ptr_to_elem %the-var %uint_0 %uint_0
        //   For POD data, its something like this:
        //     OpAccessChain %ptr_to_elem %the-var %uint_0
        // 3) Generate no SPIR-V code for the call itself.

        switch (arg_kind) {
        case clspv::ArgKind::Buffer: {
          // If original argument is:
          //   Elem addrspace(1)*
          // Then make a zero-length array to mimic a StorageBuffer struct
          // whose first element is a RuntimeArray:
          //
          //   { [0 x Elem] }
          //
          // Use unnamed struct types so we generate less SPIR-V code.

          // Create the type only once.
          auto *arr_type = ArrayType::get(argTy->getPointerElementType(), 0);
          resource_type = StructType::get(arr_type);
          // Preserve the address space in case the pointer is passed into a
          // helper function: we don't want to change the type of the helper
          // function parameter.
          addr_space = argTy->getPointerAddressSpace();
          break;
        }
        case clspv::ArgKind::Pod: {
          // If original argument is:
          //   Elem %arg
          // Then make a StorageBuffer struct whose element is pod-type:
          //
          //   { Elem }
          //
          // Use unnamed struct types so we generate less SPIR-V code.
          resource_type = StructType::get(argTy);
          addr_space = clspv::AddressSpace::Global;
          break;
        }
        case clspv::ArgKind::Sampler:
        case clspv::ArgKind::ReadOnlyImage:
        case clspv::ArgKind::WriteOnlyImage:
          // We won't be translating the value here.  Keep the type the same.
          // since calls using these values need to keep the same type.
          resource_type = argTy->getPointerElementType();
          addr_space = argTy->getPointerAddressSpace();
          break;
        default:
          errs() << "Unhandled type " << *argTy << "\n";
          llvm_unreachable("Allocation of descriptors: Unhandled type");
        }

        assert(resource_type);

        auto fn_name = std::string("clspv.resource.var.") +
                       std::to_string(discriminants[arg_index].index);
        Function *var_fn = M.getFunction(fn_name);

        if (!var_fn) {
          // Make the function
          PointerType *ptrTy = PointerType::get(resource_type, addr_space);
          // The parameters are:
          //  descriptor set
          //  binding
          //  arg kind
          //  arg index
          Type *i32 = Builder.getInt32Ty();
          FunctionType *fnTy =
              FunctionType::get(ptrTy, {i32, i32, i32, i32}, false);
          var_fn = cast<Function>(M.getOrInsertFunction(fn_name, fnTy));
        }

        // Replace uses of this argument with something dependent on a GEP
        // into the the result of a call to the special builtin.
        auto *set_arg = Builder.getInt32(set);
        auto *binding_arg = Builder.getInt32(binding);
        auto *arg_kind_arg = Builder.getInt32(unsigned(arg_kind));
        auto *arg_index_arg = Builder.getInt32(arg_index);
        auto *call = Builder.CreateCall(
            var_fn, {set_arg, binding_arg, arg_kind_arg, arg_index_arg});

        Value *replacement = nullptr;
        Value *zero = Builder.getInt32(0);
        switch (arg_kind) {
        case clspv::ArgKind::Buffer:
          // Return a GEP to the first element
          // in the runtime array we'll make.
          replacement = Builder.CreateGEP(call, {zero, zero, zero});
          break;
        case clspv::ArgKind::Pod: {
          // Replace with a load of the start of the (virtual) variable.
          auto *gep = Builder.CreateGEP(call, {zero, zero});
          replacement = Builder.CreateLoad(gep);
        } break;
        case clspv::ArgKind::ReadOnlyImage:
        case clspv::ArgKind::WriteOnlyImage:
        case clspv::ArgKind::Sampler: {
          // The call returns a pointer to an opaque type.  Eventually the
          // SPIR-V will need to load the variable, so the natural thing would
          // be to emit an LLVM load here.  But LLVM does not allow a load of
          // an opaque type because it's unsized.  So keep the bare call here,
          // and do the translation to a load in the SPIRVProducer pass.
          replacement = call;
        } break;
        case clspv::ArgKind::Local:
          llvm_unreachable("local is unhandled");
        }

        if (ShowDescriptors) {
          outs() << "DBA: Map " << *argTy << " " << arg_index << " -> "
                 << discriminants[arg_index].index << "(" << set << ","
                 << binding << ")"
                 << "\n";
          outs() << "DBA:   resource type        " << *resource_type << "\n";
          outs() << "DBA:   var fn               " << *var_fn << "\n";
          outs() << "DBA:     var call           " << *call << "\n";
          outs() << "DBA:     var replacement    " << *replacement << "\n";
          outs() << "DBA:     var replacement ty " << *(replacement->getType())
                 << "\n";
          outs() << "\n\n";
        }

        Arg.replaceAllUsesWith(replacement);
      }
      arg_index++;
    }
  }
  return Changed;
}
