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

#include "ArgKind.h"
#include "Constants.h"
#include "DescriptorCounter.h"
#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "allocatedescriptors"

namespace {

// Constant that represents bitfield for UniformMemory Memory Semantics from
// SPIR-V. Used to test barrier semantics.
const uint32_t kMemorySemanticsUniformMemory = 0x40;

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

  bool AllocateLocalKernelArgSpecIds(Module &M);

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

  // Returns true if |F| or call function |F| calls contains a global barrier.
  // Specifically, it checks that the memory semantics operand contains
  // UniformMemory memory semantics.
  //
  // The compiler targets OpenCL 1.2, which only provides support for relaxed
  // atomics which means they cannot be used as synchronization primitives.
  // That is why the pass does not consider them for the addition of coherence.
  bool CallTreeContainsGlobalBarrier(Function *F);

  // Returns a pair indicating if |V| is read and/or written to.
  // Traces the use chain looking for loads and stores and proceeding through
  // function calls until a non-pointer value is encountered.
  //
  // This function assumes loads, stores and function calls are the only
  // instructions that can read or write to memory.
  std::pair<bool, bool> HasReadsAndWrites(Value *V);

  // Cache for which functions' call trees contain a global barrier.
  DenseMap<Function *, bool> barrier_map_;

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
    KernelArgDiscriminant(Type *the_type = nullptr, int the_arg_index = 0,
                          int the_separation_token = 0, int is_coherent = 0)
        : type(the_type), arg_index(the_arg_index),
          separation_token(the_separation_token), coherent(is_coherent) {}
    // Different argument type requires different descriptor since logical
    // addressing requires strongly typed storage buffer variables.
    Type *type;
    // If we have multiple arguments of the same type to the same kernel,
    // then we have to use distinct descriptors because the user could
    // bind different storage buffers for them.  Use argument index
    // as a proxy for distinctness.  This might overcount, but we
    // don't worry about yet.
    int arg_index;
    // An extra bit of data that can be used to separate resource
    // variables that otherwise share the same type and argument index.
    // By default this will be zero, and so it won't force any separation.
    int separation_token;
    // An extra bit that marks whether the variable is coherent. This means
    // coherent and non-coherent variables will not share a binding.
    int coherent;
  };
  struct KADDenseMapInfo {
    static KernelArgDiscriminant getEmptyKey() {
      return KernelArgDiscriminant(nullptr, 0, 0);
    }
    static KernelArgDiscriminant getTombstoneKey() {
      return KernelArgDiscriminant(nullptr, -1, 0);
    }
    static unsigned getHashValue(const KernelArgDiscriminant &key) {
      return unsigned(uintptr_t(key.type)) ^ key.arg_index ^
             key.separation_token ^ key.coherent;
    }
    static bool isEqual(const KernelArgDiscriminant &lhs,
                        const KernelArgDiscriminant &rhs) {
      return lhs.type == rhs.type && lhs.arg_index == rhs.arg_index &&
             lhs.separation_token == rhs.separation_token &&
             lhs.coherent == rhs.coherent;
    }
  };
};
} // namespace

char AllocateDescriptorsPass::ID = 0;
INITIALIZE_PASS(AllocateDescriptorsPass, "AllocateDescriptorsPass",
                "Allocate resource descriptors", false, false)

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
  Changed |= AllocateLocalKernelArgSpecIds(M);

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

    // Generate the function type for clspv::LiteralSamplerFunction()
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

    auto var_fn = M.getOrInsertFunction(clspv::LiteralSamplerFunction(), fn_ty);

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
      // Copy users, to avoid modifying the list in place.
      SmallVector<User *, 8> users(init_fn->users());
      for (auto user : users) {
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
      if (!init_fn->user_empty()) {
        errs() << "Function: " << init_fn->getName().str()
               << " still has users after rewrite\n";
        for (auto U : init_fn->users()) {
          errs() << " User: " << *U << "\n";
        }
        llvm_unreachable("Unexpected uses remain");
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

  // First classify all kernel arguments by arg discriminant which
  // is the pair (type, arg index).
  //
  // FIRST RULE: There will be at least one resource variable for each
  // different discriminant.

  // Map a descriminant to a unique index.  We don't use a UniqueVector
  // because that requires operator< that I don't want to define on
  // llvm::Type*
  using KernelArgDiscriminantMap =
      DenseMap<KernelArgDiscriminant, int, KADDenseMapInfo>;

  // Maps a discriminant to its unique index, starting at 0.
  KernelArgDiscriminantMap discriminant_map;

  // SECOND RULE: We can use several strategies for descriptor binding
  // to these variables.
  //
  // It may not be obvious, but:
  // - A single resource variable can only be decorated once with
  //   DescriptorSet and Binding.  Otherwise it's impossible to interpret
  //   how to use the variable.
  // - Different resource variables can have the same binding.  (For example,
  //   do that to save on descriptors, or to save on the number of resource
  //   variables.)
  //   - SPIR-V (trivially) allows reuse of (set,binding) pairs.
  //   - Vulkan permits this as well, but requires that for a given entry
  //     point all such variables statically referenced by the entry point's
  //     call tree must have a type compatible with the descriptor actually
  //     bound to the pipeline.
  // - When setting up a pipeline, Vulkan does not care about the resource
  //   variables that are *not* statically referenced by the used entry points'
  //   call trees.
  // For more, see Vulkan 14.5.3 DescriptorSet and Binding Assignment
  const bool always_distinct_sets =
      clspv::Option::DistinctKernelDescriptorSets();
  // The default is that all kernels use the same descriptor set.
  const bool always_single_kernel_descriptor = true;
  // By default look for as much sharing as possible.  But sometimes we need to
  // ensure each kernel argument that is an image or sampler gets a different
  // resourcee variable.
  const bool always_distinct_image_sampler =
      clspv::Option::HackDistinctImageSampler();

  // Bookkeeping:
  //  - Each discriminant remembers which functions use it.
  //  - Each function remembers the pairs associated with each argument.

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
  // TODO(dneto): This probably shouldn't be a DenseMap because its value type
  // is pretty big.
  DenseMap<Function *, SmallVector<DiscriminantInfo, 3>>
      discriminants_used_by_function;

  // Remember the list of kernels with bodies, for convenience.
  // This is in module-order.
  SmallVector<Function *, 3> kernels_with_bodies;

  int num_image_sampler_arguments = 0;
  for (Function &F : M) {
    // Only scan arguments of kernel functions that have bodies.
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }
    kernels_with_bodies.push_back(&F);
    auto &discriminants_list = discriminants_used_by_function[&F];
    bool uses_barriers = CallTreeContainsGlobalBarrier(&F);

    int arg_index = 0;
    for (Argument &Arg : F.args()) {
      Type *argTy = Arg.getType();
      const auto arg_kind = clspv::GetArgKindForType(argTy);

      int separation_token = 0;
      switch (arg_kind) {
      case clspv::ArgKind::ReadOnlyImage:
      case clspv::ArgKind::WriteOnlyImage:
      case clspv::ArgKind::Sampler:
        if (always_distinct_image_sampler) {
          separation_token = num_image_sampler_arguments;
        }
        num_image_sampler_arguments++;
        break;
      default:
        break;
      }

      int coherent = 0;
      if (uses_barriers && arg_kind == clspv::ArgKind::Buffer) {
        // Coherency is only required if the argument is an SSBO that is both
        // read and written to. Images do not require coherency because they are
        // either read only or write only.
        bool reads = false;
        bool writes = false;
        std::tie(reads, writes) = HasReadsAndWrites(&Arg);
        coherent = (reads && writes) ? 1 : 0;
      }

      KernelArgDiscriminant key(argTy, arg_index, separation_token, coherent);

      // First assume no descriptor is required.
      discriminants_list.push_back(DiscriminantInfo{-1, key});

      // Pointer-to-local arguments don't become resource variables.
      if (arg_kind == clspv::ArgKind::Local) {
        if (ShowDescriptors) {
          errs() << "DBA: skip pointer-to-local\n\n";
        }
      } else {
        int index;
        auto where = discriminant_map.find(key);
        if (where == discriminant_map.end()) {
          index = int(discriminant_map.size());
          // Save the new unique idex for this discriminant.
          discriminant_map[key] = index;
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
  // For an argument that does not use a descriptor, its set and binding are
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
    // Share resource variables.
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
          if (always_single_kernel_descriptor ||
              functions_used_by_discriminant[info.index].size() ==
                  kernels_with_bodies.size()) {
            // Reuse the descriptor because one of the following is true:
            // - This kernel argument discriminant is consistent across all
            //   kernels.
            // - Convention is to use a single descriptor for all kernels.
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
    auto &discriminants_list = discriminants_used_by_function[f_ptr];
    const auto num_args = unsigned(set_and_binding_list.size());
    if (!always_distinct_sets &&
        (num_args != unsigned(discriminants_list.size()))) {
      errs() << "num_args " << num_args << " != num discriminants "
             << discriminants_list.size() << "\n";
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
      if (discriminants_list[arg_index].index >= 0) {
        Changed = true;
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

        Type *argTy = discriminants_list[arg_index].discriminant.type;
        assert(arg_index ==
               discriminants_list[arg_index].discriminant.arg_index);

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
        case clspv::ArgKind::BufferUBO: {
          // If original argument is:
          //   Elem addrspace(2)*
          // Then make a n-element sized array to mimic an Uniform struct whose
          // first element is an array:
          //
          //   { [n x Elem] }
          //
          // Use unnamed struct types so we generate less SPIR-V code.

          // Max UBO size can be specified on the command line. Size the array
          // to pretend we are using that space.
          uint64_t struct_size = M.getDataLayout().getTypeAllocSize(
              argTy->getPointerElementType());
          uint64_t num_elements =
              clspv::Option::MaxUniformBufferSize() / struct_size;

          // Create the type only once.
          auto *arr_type =
              ArrayType::get(argTy->getPointerElementType(), num_elements);
          resource_type = StructType::get(arr_type);
          // Preserve the address space in case the pointer is passed into a
          // helper function: we don't want to change the type of the helper
          // function parameter.
          addr_space = argTy->getPointerAddressSpace();
          break;
        }
        case clspv::ArgKind::Pod:
        case clspv::ArgKind::PodUBO: {
          // If original argument is:
          //   Elem %arg
          // Then make a StorageBuffer struct whose element is pod-type:
          //
          //   { Elem }
          //
          // Use unnamed struct types so we generate less SPIR-V code.
          resource_type = StructType::get(argTy);
          addr_space = clspv::Option::PodArgsInUniformBuffer()
                           ? clspv::AddressSpace::Uniform
                           : clspv::AddressSpace::Global;
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

        auto fn_name = std::string(clspv::ResourceAccessorFunction()) +
                       std::to_string(discriminants_list[arg_index].index);
        Function *var_fn = M.getFunction(fn_name);

        if (!var_fn) {
          // Make the function
          PointerType *ptrTy = PointerType::get(resource_type, addr_space);
          // The parameters are:
          //  descriptor set
          //  binding
          //  arg kind
          //  arg index
          //  discriminant index
          //  coherent
          Type *i32 = Builder.getInt32Ty();
          FunctionType *fnTy =
              FunctionType::get(ptrTy, {i32, i32, i32, i32, i32, i32}, false);
          var_fn =
              cast<Function>(M.getOrInsertFunction(fn_name, fnTy).getCallee());
        }

        // Replace uses of this argument with something dependent on a GEP
        // into the the result of a call to the special builtin.
        auto *set_arg = Builder.getInt32(set);
        auto *binding_arg = Builder.getInt32(binding);
        auto *arg_kind_arg = Builder.getInt32(unsigned(arg_kind));
        auto *arg_index_arg = Builder.getInt32(arg_index);
        auto *discriminant_index_arg =
            Builder.getInt32(discriminants_list[arg_index].index);
        auto *coherent_arg = Builder.getInt32(
            discriminants_list[arg_index].discriminant.coherent);
        auto *call = Builder.CreateCall(
            var_fn, {set_arg, binding_arg, arg_kind_arg, arg_index_arg,
                     discriminant_index_arg, coherent_arg});

        Value *replacement = nullptr;
        Value *zero = Builder.getInt32(0);
        switch (arg_kind) {
        case clspv::ArgKind::Buffer:
        case clspv::ArgKind::BufferUBO:
          // Return a GEP to the first element
          // in the runtime array we'll make.
          replacement = Builder.CreateGEP(call, {zero, zero, zero});
          break;
        case clspv::ArgKind::Pod:
        case clspv::ArgKind::PodUBO: {
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
          outs() << "DBA: Map " << *argTy << " " << arg_index << "\n"
                 << "DBA:   index " << discriminants_list[arg_index].index
                 << " -> (" << set << "," << binding << ")"
                 << "\n";
          outs() << "DBA:   resource type        " << *resource_type << "\n";
          outs() << "DBA:   var fn               " << var_fn->getName() << "\n";
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

bool AllocateDescriptorsPass::AllocateLocalKernelArgSpecIds(Module &M) {
  bool Changed = false;
  if (ShowDescriptors) {
    outs() << "Allocate local kernel arg spec ids\n";
  }

  int next_id = clspv::FirstLocalSpecId();
  // Maps argument type to assigned SpecIds.
  DenseMap<Type *, SmallVector<int, 4>> spec_id_types;
  // Tracks SpecIds assigned in the current function.
  DenseSet<int> function_spec_ids;
  // Tracks newly allocated spec ids.
  std::vector<std::pair<Type *, int>> function_allocations;

  // Allocates a SpecId for |type|.
  auto GetSpecId = [&next_id, &spec_id_types, &function_spec_ids,
                    &function_allocations](Type *type) {
    const bool always_distinct_sets =
        clspv::Option::DistinctKernelDescriptorSets();

    // Attempt to reuse a SpecId. If the SpecId is associated with the same type
    // in another kernel and not yet assigned to this kernel it can be reused.
    auto where = spec_id_types.find(type);
    if (where != spec_id_types.end()) {
      for (auto id : where->second) {
        if (!function_spec_ids.count(id)) {
          return id;
        }
      }
    }

    // Need to allocate a new SpecId.
    function_allocations.push_back(std::make_pair(type, next_id));
    function_spec_ids.insert(next_id);
    return next_id++;
  };

  IRBuilder<> Builder(M.getContext());
  for (Function &F : M) {
    // Only scan arguments of kernel functions that have bodies.
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }

    // Prepare to insert arg remapping instructions at the start of the
    // function.
    Builder.SetInsertPoint(F.getEntryBlock().getFirstNonPHI());

    function_allocations.clear();
    function_spec_ids.clear();
    int arg_index = 0;
    for (Argument &Arg : F.args()) {
      Type *argTy = Arg.getType();
      const auto arg_kind = clspv::GetArgKindForType(argTy);
      if (arg_kind == clspv::ArgKind::Local) {
        // Assign a SpecId to this argument.
        int spec_id = GetSpecId(Arg.getType());

        if (ShowDescriptors) {
          outs() << "DBA: " << F.getName() << " arg " << arg_index << " " << Arg
                 << " allocated SpecId " << spec_id << "\n";
        }

        // The type returned by the accessor function is [ Elem x 0 ]
        // addrspace(3)*. The zero-sized array is used to match the correct
        // indexing required by gep's, but the zero size will eventually be
        // codegen'd as an OpSpecConstant.
        auto fn_name = std::string(clspv::WorkgroupAccessorFunction()) +
                       std::to_string(spec_id);
        Function *var_fn = M.getFunction(fn_name);
        auto *zero = Builder.getInt32(0);
        auto *array_ty = ArrayType::get(argTy->getPointerElementType(), 0);
        auto *ptr_ty =
            PointerType::get(array_ty, argTy->getPointerAddressSpace());
        if (!var_fn) {
          // Generate the function.
          Type *i32 = Builder.getInt32Ty();
          FunctionType *fn_ty = FunctionType::get(ptr_ty, i32, false);
          var_fn =
              cast<Function>(M.getOrInsertFunction(fn_name, fn_ty).getCallee());
        }

        // Generate an accessor call.
        auto *spec_id_arg = Builder.getInt32(spec_id);
        auto *call = Builder.CreateCall(var_fn, {spec_id_arg});

        // Add the correct gep. Since the workgroup variable is [ <type> x 0 ]
        // addrspace(3)*, generate two zero indices for the gep.
        auto *replacement = Builder.CreateGEP(call, {zero, zero});
        Arg.replaceAllUsesWith(replacement);

        // We record the assignment of the spec id for this particular argument
        // in module-level metadata. This allows us to reconstruct the
        // connection during SPIR-V generation. We cannot use the argument as an
        // operand to the function because DirectResourceAccess will generate
        // these calls in different function scopes potentially.
        auto *arg_const = Builder.getInt32(arg_index);
        NamedMDNode *nmd =
            M.getOrInsertNamedMetadata(clspv::LocalSpecIdMetadataName());
        Metadata *ops[3];
        ops[0] = ValueAsMetadata::get(&F);
        ops[1] = ConstantAsMetadata::get(arg_const);
        ops[2] = ConstantAsMetadata::get(spec_id_arg);
        MDTuple *tuple = MDTuple::get(M.getContext(), ops);
        nmd->addOperand(tuple);
        Changed = true;
      }

      ++arg_index;
    }

    // Move newly allocated SpecIds for this function into the overall mapping.
    for (auto &pair : function_allocations) {
      spec_id_types[pair.first].push_back(pair.second);
    }
  }

  return Changed;
}

bool AllocateDescriptorsPass::CallTreeContainsGlobalBarrier(Function *F) {
  auto iter = barrier_map_.find(F);
  if (iter != barrier_map_.end()) {
    return iter->second;
  }

  bool uses_barrier = false;
  for (auto &BB : *F) {
    for (auto &I : BB) {
      if (auto *call = dyn_cast<CallInst>(&I)) {
        // For barrier and mem_fence semantics, only Uniform (covering Uniform
        // and StorageBuffer storage classes) semantics are checked because
        // Workgroup variables are inherently coherent (and do not require the
        // decoration).
        if (call->getCalledFunction()->getName().equals(
                "__spirv_control_barrier")) {
          // barrier()
          if (auto *semantics = dyn_cast<ConstantInt>(call->getOperand(2))) {
            uses_barrier =
                semantics->getZExtValue() & kMemorySemanticsUniformMemory;
          }
        } else if (call->getCalledFunction()->getName().equals(
                       "__spirv_memory_barrier")) {
          // mem_fence()
          if (auto *semantics = dyn_cast<ConstantInt>(call->getOperand(1))) {
            uses_barrier =
                semantics->getZExtValue() & kMemorySemanticsUniformMemory;
          }
        } else if (!call->getCalledFunction()->isDeclaration()) {
          // Continue searching in the subfunction.
          uses_barrier =
              CallTreeContainsGlobalBarrier(call->getCalledFunction());
        }

        if (uses_barrier)
          break;
      }

      if (uses_barrier)
        break;
    }

    if (uses_barrier)
      break;
  }

  barrier_map_.insert(std::make_pair(F, uses_barrier));
  return uses_barrier;
}

std::pair<bool, bool> AllocateDescriptorsPass::HasReadsAndWrites(Value *V) {
  // Atomics and OpenCL builtins modf and frexp are all represented as function
  // calls.
  //
  // A user is interesting if reads or writes memory or could eventually read
  // or write memory.
  auto IsInterestingUser = [](const User *user) {
    if (isa<StoreInst>(user) || isa<LoadInst>(user) || isa<CallInst>(user) ||
        user->getType()->isPointerTy())
      return true;
    return false;
  };

  bool read = false;
  bool write = false;
  DenseSet<Value *> visited;
  std::vector<std::pair<Value *, unsigned>> stack;
  for (auto &Use : V->uses()) {
    if (IsInterestingUser(Use.getUser()))
      stack.push_back(std::make_pair(Use.getUser(), Use.getOperandNo()));
  }

  while (!stack.empty() && !(read && write)) {
    Value *value = stack.back().first;
    unsigned operand_no = stack.back().second;
    stack.pop_back();
    if (!visited.insert(value).second)
      continue;

    if (isa<LoadInst>(value)) {
      read = true;
    } else if (isa<StoreInst>(value)) {
      write = true;
    } else {
      auto *call = dyn_cast<CallInst>(value);
      if (call && !call->getCalledFunction()->isDeclaration()) {
        // Trace through the function call and grab the right argument.
        auto arg_iter = call->getCalledFunction()->arg_begin();
        for (size_t i = 0; i != operand_no; ++i, ++arg_iter) {
        }

        for (auto &Use : arg_iter->uses()) {
          auto *User = Use.getUser();
          if (IsInterestingUser(User))
            stack.push_back(std::make_pair(Use.getUser(), Use.getOperandNo()));
        }
      } else if (call) {
        // Check the attributes on the function.
        if (!call->getCalledFunction()->doesNotAccessMemory()) {
          if (!call->getCalledFunction()->doesNotReadMemory())
            read = true;
          if (!call->getCalledFunction()->onlyReadsMemory())
            write = true;
        }
      } else {
        // Trace uses that remain a pointer or a function calls.
        for (auto &U : value->uses()) {
          auto *User = U.getUser();
          if (IsInterestingUser(User))
            stack.push_back(std::make_pair(U.getUser(), U.getOperandNo()));
        }
      }
    }
  }

  return std::make_pair(read, write);
}
