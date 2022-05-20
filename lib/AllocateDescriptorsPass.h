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

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#include "DescriptorCounter.h"

#ifndef _CLSPV_LIB_ALLOCATE_DESCRIPTORS_PASS_H
#define _CLSPV_LIB_ALLOCATE_DESCRIPTORS_PASS_H

namespace clspv {
struct AllocateDescriptorsPass : llvm::PassInfoMixin<AllocateDescriptorsPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

  using SamplerMapType = llvm::ArrayRef<std::pair<unsigned, std::string>>;

  SamplerMapType &sampler_map() { return sampler_map_; }

private:
  // Allocates descriptors for all samplers and kernel arguments that have uses.
  // Replace their uses with calls to a special compiler builtin.  Returns true
  // if we changed the module.
  bool AllocateDescriptors(llvm::Module &M);

  // Allocate descriptor for literal samplers.  Returns true if we changed the
  // module.
  bool AllocateLiteralSamplerDescriptors(llvm::Module &M);

  // Allocate descriptor for kernel arguments with uses.  Returns true if we
  // changed the module.
  bool AllocateKernelArgDescriptors(llvm::Module &M);

  bool AllocateLocalKernelArgSpecIds(llvm::Module &M);

  // Allocates the next descriptor set and resets the tracked binding number to
  // 0.
  unsigned StartNewDescriptorSet(llvm::Module &M) {
    // Allocate the descriptor set we used.
    binding_ = 0;
    const auto set = clspv::TakeDescriptorIndex(&M);
    assert(set == descriptor_set_);
    descriptor_set_++;
    return set;
  }

  // Returns true if |F| or call function |F| calls contains a global barrier.
  // Specifically, it checks that the memory semantics operand contains
  // UniformMemory memory semantics.
  //
  // The compiler targets OpenCL 1.2, which only provides support for relaxed
  // atomics which means they cannot be used as synchronization primitives.
  // That is why the pass does not consider them for the addition of coherence.
  bool CallTreeContainsGlobalBarrier(llvm::Function *F);

  // Returns a pair indicating if |V| is read and/or written to.
  // Traces the use chain looking for loads and stores and proceeding through
  // function calls until a non-pointer value is encountered.
  //
  // This function assumes loads, stores and function calls are the only
  // instructions that can read or write to memory.
  std::pair<bool, bool> HasReadsAndWrites(llvm::Value *V);

  // Cache for which functions' call trees contain a global barrier.
  llvm::DenseMap<llvm::Function *, bool> barrier_map_;

  // The sampler map, which is an array ref of pairs, each of which is the
  // sampler constant as an integer, followed by the string expression for
  // the sampler.
  SamplerMapType sampler_map_;

  // Which descriptor set are we using?
  int descriptor_set_;
  // The next binding number to use.
  int binding_;

  llvm::DenseMap<llvm::Value *, llvm::Type *> type_cache_;

  // What makes a kernel argument require a new descriptor?
  struct KernelArgDiscriminant {
    KernelArgDiscriminant(llvm::Type *the_type = nullptr, int the_arg_index = 0,
                          int the_separation_token = 0, int is_coherent = 0)
        : type(the_type), arg_index(the_arg_index),
          separation_token(the_separation_token), coherent(is_coherent) {}
    // Different argument type requires different descriptor since logical
    // addressing requires strongly typed storage buffer variables.
    llvm::Type *type;
    // If we have multiple arguments of the same type to the same kernel,
    // then we have to use distinct descriptors because the user could
    // bind different storage buffers for them.  Use argument index
    // as a proxy for distinctness.  This might overcount, but we
    // don't worry about yet.
    int arg_index;
    // An extra bit of data that can be used to separate resource
    // variables that otherwise share the same type and argument index.
    // By default this will be zero, and so it won't force any separation.
    // For buffer arguments, the address space is used as the separation token.
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
} // namespace clspv

#endif // _CLSPV_LIB_ALLOCATE_DESCRIPTORS_PASS_H
