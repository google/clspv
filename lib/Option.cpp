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

// This translation unit defines all Clspv command line option variables.

#include <llvm/Support/CommandLine.h>

namespace {

llvm::cl::opt<bool> no_inline_single_call_site(
    "no-inline-single", llvm::cl::init(false),
    llvm::cl::desc("Disable inlining functions with single call sites."));

// Should the compiler try to use direct resource accesses within helper
// functions instead of passing pointers via function arguments?
llvm::cl::opt<bool> no_direct_resource_access(
    "no-dra", llvm::cl::init(false),
    llvm::cl::desc(
        "No Direct Resource Access: Avoid rewriting helper functions "
        "to access resources directly instead of by pointers "
        "in function arguments.  Affects kernel arguments of type "
        "pointer-to-global, pointer-to-constant, image, and sampler."));

llvm::cl::opt<bool> no_share_module_scope_variables(
    "no-smsv", llvm::cl::init(false),
    llvm::cl::desc("No Share Module Scope Variables: Avoid de-duplicating "
                   "module scope variables."));

// By default, reuse the same descriptor set number for all arguments.
// To turn that off, use -distinct-kernel-descriptor-sets
llvm::cl::opt<bool> distinct_kernel_descriptor_sets(
    "distinct-kernel-descriptor-sets", llvm::cl::init(false),
    llvm::cl::desc("Each kernel uses its own descriptor set for its arguments. "
                   "Turns off direct-resource-access optimizations."));

// TODO(dneto): As per Neil Henning suggestion, might not need this if
// you can trace the pointer back far enough to see that it's 32-bit
// aligned.  However, even in the vstore_half case, you'll probably get
// better performance if you can rely on SPV_KHR_16bit_storage since in
// the alternate case you're using a (relaxed) atomic, and therefore
// have to write through to the cache.
llvm::cl::opt<bool> f16bit_storage(
    "f16bit_storage", llvm::cl::init(false),
    llvm::cl::desc("Assume the target supports SPV_KHR_16bit_storage"));

llvm::cl::opt<bool> hack_initializers(
    "hack-initializers", llvm::cl::init(false),
    llvm::cl::desc(
        "At the start of each kernel, explicitly write the initializer "
        "value for a compiler-generated variable containing the workgroup "
        "size. Required by some drivers to make the get_global_size builtin "
        "function work when used with non-constant dimension index."));

llvm::cl::opt<bool> hack_dis(
    "hack-dis", llvm::cl::init(false),
    llvm::cl::desc("Force use of a distinct image or sampler variable for each "
                   "image or sampler kernel argument.  This prevents sharing "
                   "of resource variables."));

llvm::cl::opt<bool> hack_inserts(
    "hack-inserts", llvm::cl::init(false),
    llvm::cl::desc(
        "Avoid all single-index OpCompositInsert instructions "
        "into struct types by using complete composite construction and "
        "extractions"));

llvm::cl::opt<bool> hack_signed_compare_fixup(
    "hack-scf", llvm::cl::init(false),
    llvm::cl::desc("Rewrite signed integer comparisons to use other kinds of "
                   "instructions"));

// Some drivers don't like to see constant composite values constructed
// from scalar Undef values.  Replace numeric scalar and vector Undef with
// corresponding OpConstantNull.  We need to keep Undef for image values,
// for example.  In the LLVM domain, image values are passed as pointer to
// struct.
// See https://github.com/google/clspv/issues/95
llvm::cl::opt<bool> hack_undef(
    "hack-undef", llvm::cl::init(false),
    llvm::cl::desc("Use OpConstantNull instead of OpUndef for floating point, "
                   "integer, or vectors of them"));

llvm::cl::opt<bool>
    pod_ubo("pod-ubo", llvm::cl::init(false),
            llvm::cl::desc("POD kernel arguments are in uniform buffers"));

llvm::cl::opt<bool> module_constants_in_storage_buffer(
    "module-constants-in-storage-buffer", llvm::cl::init(false),
    llvm::cl::desc(
        "Module-scope __constants are collected into a single storage buffer.  "
        "The binding and initialization data are reported in the descriptor "
        "map."));

llvm::cl::opt<bool> show_ids("show-ids", llvm::cl::init(false),
                             llvm::cl::desc("Show SPIR-V IDs for functions"));

} // namespace

namespace clspv {
namespace Option {

bool InlineSingleCallSite() { return !no_inline_single_call_site; }
bool DirectResourceAccess() {
  return !(no_direct_resource_access || distinct_kernel_descriptor_sets);
}
bool ShareModuleScopeVariables() { return !no_share_module_scope_variables; }
bool DistinctKernelDescriptorSets() { return distinct_kernel_descriptor_sets; }
bool F16BitStorage() { return f16bit_storage; }
bool HackDistinctImageSampler() { return hack_dis; }
bool HackInitializers() { return hack_initializers; }
bool HackInserts() { return hack_inserts; }
bool HackSignedCompareFixup() { return hack_signed_compare_fixup; }
bool HackUndef() { return hack_undef; }
bool ModuleConstantsInStorageBuffer() {
  return module_constants_in_storage_buffer;
}
bool PodArgsInUniformBuffer() { return pod_ubo; }
bool ShowIDs() { return show_ids; }

} // namespace Option
} // namespace clspv
