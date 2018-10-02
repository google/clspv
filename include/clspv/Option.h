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

namespace clspv {
namespace Option {

// Returns true if code generation can use SPV_KHR_16bit_storage.
bool F16BitStorage();

// Returns true if each kernel must use its own descriptor set for all
// arguments.
bool DistinctKernelDescriptorSets();

// Returns true if the compiler should try to use direct resource accesses
// within helper functions instead of passing pointers via function arguments.
bool DirectResourceAccess();

bool ShareModuleScopeVariables();

// Returns true if we should avoid sharing resource variables for images
// and samplers.  Use this to avoid one difference between the old and new
// descriptor allocation algorithms.
// TODO(dneto): Remove this eventually?
bool HackDistinctImageSampler();

// Returns true if we should apply a workaround to make get_global_size(i)
// with non-constant i work on certain drivers.  The workaround is for the
// value of the workgroup size is written to a special compiler-generated
// variable right at the start of each kernel, rather than relying on the
// variable intializer to take effect.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackInitializers();

// Returns true if code generation should avoid single-index OpCompositeInsert
// instructions into struct types.  Use complete OpCompositeConstruct instead.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackInserts();

// Returns true if we should rewrite signed integer compares into other
// equivalent code that does not use signed integer comparisons.
// Works around a driver bug.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackSignedCompareFixup();

// Returns true if numeric scalar and vector Undef values should be replaced
// with OpConstantNull.  Works around a driver bug.
// TODO(dneto): Remove this eventually when drivers are fixed.
bool HackUndef();

// Returns true if code generation should avoid creating OpPhi of structs.
bool HackPhis();

// Returns true if module-scope constants are to be collected into a single
// storage buffer.  The binding for that buffer, and its intialization data
// are given in the descriptor map file.
bool ModuleConstantsInStorageBuffer();

// Returns true if POD kernel arguments should be passed in via uniform buffers.
bool PodArgsInUniformBuffer();

// Returns true if SPIR-V IDs for functions should be emitted to stderr during
// code generation.
bool ShowIDs();

// Returns true if functions with single call sites should be inlined.
bool InlineSingleCallSite();

// Returns true if entry points should be fully inlined.
bool InlineEntryPoints();

// Returns true if pointer-to-constant kernel args should be generated as UBOs.
bool ConstantArgsInUniformBuffer();

} // namespace Option
} // namespace clspv
