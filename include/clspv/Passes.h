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

namespace llvm {
class FunctionPass;
class ModulePass;
class raw_pwrite_stream;
template <typename T> class ArrayRef;
}

namespace clspv {
/// Define the work-item builtins that OpenCL has.
/// @return An LLVM module pass.
///
/// These OpenCL work-item builtins are in this pass mapped to LLVM module-scope
/// global variables, such that:
/// - get_global_id() is mapped to a variable named "__spirv_GlobalInvocationId"
/// - get_local_size() is mapped to a variable named "__spirv_WorkgroupSize"
/// - get_local_id() is mapped to a variable named "__spirv_LocalInvocationId"
/// - get_num_groups() is mapped to a variable named "__spirv_NumWorkgroups"
/// - get_group_id() is mapped to a variable named "__spirv_WorkgroupId"
///
/// These OpenCL work-item builtins are also defined:
/// - get_work_dim() always returns 3
/// - get_global_offset() always returns 0
/// - get_global_size() is implemented by multiplying the result from
///   get_local_size() by the result from get_num_groups()
///
/// If we could add a SPIR-V target to Clang in future, we could define these as
/// SPIR-V builtins in Clang that map to SPIR-V intrinsics in LLVM.
llvm::ModulePass *createDefineOpenCLWorkItemBuiltinsPass();

/// Internalize non-kernel OpenCL functions.
/// @return An LLVM module pass.
///
/// Any function that isn't specified as being a kernel will be marked as
/// internal linkage by this pass, so that DCE can remove unreferenced functions
/// if it wants to during optimizations later.
///
/// If we could change how Clang defines non-kernel OpenCL functions such that
/// the correct LLVM linkage was chosen for a final linkage of the module, we
/// might not need this pass. We'd have to be careful to preserve the symbols
/// if we were creating an OpenCL library though.
llvm::ModulePass *createFunctionInternalizerPass();

/// Inline call instructions which have pointer bitcast as arguments.
/// @return An LLVM module pass.
///
/// If function has pointer type arguments and call instruction passes pointer
/// bitcast as argument, we need to prevent it. In order to do it, we inline
/// call instructions which have pointer bitcast as argument.
llvm::ModulePass *createInlineFuncWithPointerBitCastArgPass();

/// Create a simple OpenCL inliner.
/// @return An LLVM module pass.
///
/// We create a simple inliner pass that'll fold away some of the OpenCL
/// builtins where appropriate.
llvm::ModulePass *createOpenCLInlinerPass();

/// Create a re-order basic blocks pass.
/// @return An LLVM module pass.
///
/// We create a pass that will re-order basic blocks to match the SPIR-V rules
/// for structured control flow.
///
/// We could remove this class if we could change the LLVM structurizer to
/// output basic blocks in the order that is suitable for SPIR-V.
llvm::FunctionPass *createReorderBasicBlocksPass();

/// Create a pass to replace some LLVM intrinsics.
/// @return An LLVM module pass.
///
/// We create an LLVM intrinsic replacement pass to turn some LLVM intrinsics
/// into SPIR-V ones. Specifically memset and memcpy both do pointer bitcasts
/// which we can't support.
llvm::ModulePass *createReplaceLLVMIntrinsicsPass();

/// Create a pass to replace some OpenCL builtins.
/// @return An LLVM module pass.
///
/// We create an OpenCL builtin folder pass that'll remove some builtins where
/// possible.
llvm::ModulePass *createReplaceOpenCLBuiltinPass();

llvm::ModulePass *createSPIRVProducerPass(llvm::raw_pwrite_stream &out,
                                          llvm::ArrayRef<unsigned> samplerMap,
                                          bool outputAsm);

/// Undo LLVM's bitcast instructions with pointer type.
/// @return An LLVM module pass.
///
/// LLVM could genrate bitcast instruction with pointer type but SPIR-V for
/// Vulkan can't handle it, so this pass converts the bitcast instruction with
/// pointer type into other instructions' sequence.
llvm::ModulePass *createReplacePointerBitcastPass();

/// Simplify LLVM's bitcast instructions with pointer type.
/// @return An LLVM module pass.
///
/// This pass will do the following transformations:
/// - Transform GEP -> bitcast into bitcast -> GEP.
/// - Combine bitcasts.
/// - Combine GEPs.
///
/// The purpose is to flatten arbitrarily used bitcasts & GEPs on pointers such
/// that there will be at most one bitcast, with at most one GEP, before each
/// load or store operation. This drastically improves the ability to generate
/// valid SPIR-V for Vulkan (which cannot handle pointer bitcasts at all).
llvm::ModulePass *createSimplifyPointerBitcastPass();

/// Splat scalar type arguments to vector type.
/// @return An LLVM module pass.
///
/// min/max/mix/clamp function have function prototype with scalar type on
/// OpenCL. But vulkan does not support it. In order to fit it, the pass
/// promotes scalar arument to vector argument.
llvm::ModulePass *createSplatArgPass();

/// Undo Clang's use of an i8 to form a bool type.
/// @return An LLVM module pass.
///
/// Clang uses i8 to represent a bool as it is stored, but for SPIR-V we want
/// the bool to remain as an i1. This pass will undo what Clang has done.
///
/// If we could add a SPIR-V target to Clang in future, we could do away with
/// this pass and simply instruct Clang that bool's as stored are i1.
llvm::ModulePass *createUndoBoolPass();

/// Undo Clang's use of a pointer parameter when dealing with a struct passed as
/// function parameter.
/// @return An LLVM module pass.
///
/// Clang will return a function like:
///   struct Foo { int x; };
///   void func(struct Foo a);
///
/// By essentially changing the function signature to:
///   struct Foo { int x; };
///   void func(struct Foo *a with byval attribute);
///
/// Since SPIR-V can happily accept struct parameters from functions, and given
/// we want to keep the produced SPIR-V as close to the source language as
/// possible, we use this pass to undo Clang's work.
///
/// If we could add a SPIR-V target to Clang in future, we could do away with
/// this pass and simply instruct Clang to pass parameters with the struct as
/// normal.
llvm::ModulePass *createUndoByvalPass();

/// Undo LLVM's use of get element pointer constant expressions on global
/// variables.
/// @return An LLVM module pass.
///
/// LLVM will generate get element pointer constant expressions when we have a
/// constant index into a global variable. SPIR-V for Vulkan can't represent
/// this, so this pass will turn them back into regular instructions.
llvm::ModulePass *createUndoGetElementPtrConstantExprPass();

/// Undo Clang's use of a pointer parameter when dealing with a struct returned
/// from a function.
/// @return An LLVM module pass.
///
/// Clang will return a function like:
///   struct Foo { int x; };
///   struct Foo func(int a);
///
/// By essentially changing the function signature to:
///   struct Foo { int x; };
///   void func(struct Foo *return, int a);
///
/// Since SPIR-V can happily accept struct returns from functions, and given
/// that we want to keep the produced SPIR-V as close to the source language as
/// possible, we use this pass to undo Clang's work.
///
/// If we could add a SPIR-V target to Clang in future, we could do away with
/// this pass and simply instruct Clang to return the struct as normal.
llvm::ModulePass *createUndoSRetPass();

/// Undo LLVM optimizing calls to __translate_sampler_initializer.
/// @return An LLVM module pass.
///
/// LLVM will optimize two calls to __translate_sampler_initializer into a
/// single call to the function, with a select as the argument. This is really
/// bad for us when we are trying to statically find out the number of samplers
/// we are using, and mapping them to the sampler map. This pass will undo this
/// optimization.
///
/// If we could add a function attribute to LLVM to stop it ever doing any
/// optimizations on a function that would help here.
llvm::ModulePass *createUndoTranslateSamplerFoldPass();

/// Undo LLVM optimizing switch instruction conditions by truncating them.
/// @return An LLVM module pass.
///
/// LLVM will optimize switch instructions conditions such that it will
/// sometimes produce invalid integer types. LLVM backends can handle this, but
/// since this backend does not conform to the normal process, we undo this
/// optimization here instead.
///
/// If we could add a flag to our LLVM target to indiciate "please do not create
/// malformed types" that would make this pass redundant.
llvm::ModulePass *createUndoTruncatedSwitchConditionPass();
}
