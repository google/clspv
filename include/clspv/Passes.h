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

#include <string>
#include <utility>
#include <vector>

namespace llvm {
// This is against Google C++ style guide.
class FunctionPass;
class ModulePass;
class raw_pwrite_stream;
class raw_ostream;
template <typename T> class ArrayRef;
template <typename T> class SmallVectorImpl;

// This initializes all the clspv passes.  When creating a new pass, you should:
//
// 1- Declare the pass using INITIALIZE_PASS.
// 2- Declare the function initialize<pass_name>Pass() in lib/Passes.h.
// 3- Add a call to the initialize<pass_name>Pass() to initializeClspvPasses().
// 4- Your pass must include the file lib/Passes.h.
class PassRegistry;
void initializeClspvPasses(PassRegistry &);
} // namespace llvm

namespace clspv {

/// Process long vectors into an equivalent representation that can be mapped to
/// Vulkan SPIR-V.
llvm::ModulePass *createLongVectorLoweringPass();

/// Declare a structure with all enabled push constants and attach metadata to
/// the module for use by the utilities that abstract push constant usage.
/// @return An LLVM module pass.
llvm::ModulePass *createDeclarePushConstantsPass();

/// Define the work-item builtins that OpenCL has.
/// @return An LLVM module pass.
///
/// These OpenCL work-item builtins are in this pass mapped to LLVM module-scope
/// global variables, such that:
/// - get_global_id() is mapped to a variable named
/// "__spirv_GlobalInvocationId".
///   When support for the global offset is enabled, the global offset is added
///   to "__spirv_GlobalInvocationId".
/// - get_local_size() is mapped to a variable named "__spirv_WorkgroupSize"
/// - get_local_id() is mapped to a variable named "__spirv_LocalInvocationId"
/// - get_num_groups() is mapped to a variable named "__spirv_NumWorkgroups"
/// - get_group_id() is mapped to a variable named "__spirv_WorkgroupId"
///
/// These OpenCL work-item builtins are also defined:
/// - get_work_dim() returns either always 3 or a value passed as a spec
///   constant
/// - get_global_offset() returns either always 0 or a value passed as a push
///   constant
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

/// Inline call instructions to functions having pointer-to-private args.
/// @return An LLVM module pass.
///
/// Try to avoid OpPtrAccessChain to Function storage class by inlining
/// function calls that lead to getelementptr on private storage, but which
/// the compiler will not normally optimize away.
llvm::ModulePass *createInlineFuncWithPointerToFunctionArgPass();

/// Inline call instructions to functions having a single call site.
/// @return An LLVM module pass.
///
/// Inline functions that have a single call site.
llvm::ModulePass *createInlineFuncWithSingleCallSitePass();

/// Zero-initialize allocas.
/// @return An LLVM module pass.
///
/// Store a zero value to any alloca.  This helps us avoid ConstantExpr
/// in the output.  The SPIR-V producer does not know how to emit code
/// for ConstantExpr.  This is a bit of a hack.
llvm::ModulePass *createZeroInitializeAllocasPass();

/// Rewrite constant expressions as instructions.
/// @return An LLVM module pass.
llvm::ModulePass *createRewriteConstantExpressionsPass();

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

/// Create a pass to emit SPIR-V for the module.
/// @return An LLVM module pass.
llvm::ModulePass *createSPIRVProducerPass(
    llvm::raw_pwrite_stream *out,
    llvm::SmallVectorImpl<std::pair<unsigned, std::string>> *samplerMap,
    bool outputCInitList);
llvm::ModulePass *createSPIRVProducerPass();

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

/// Undo LLVM optimizing a mask to a small integer size.
/// @return An LLVM module pass.
///
/// LLVM will optimize masks to smaller integers that get used in switches and
/// comparisons. These integer sizes may be invalid types. LLVM backends can
/// handle this, but since this backend does not conform to the normal process,
/// we undo this optimization here instead.
///
/// If we could add a flag to our LLVM target to indiciate "please do not create
/// malformed types" that would make this pass redundant.
llvm::ModulePass *createUndoTruncateToOddIntegerPass();

/// Cluster module-scope __constant variables.
/// @return An LLVM module pass.
///
/// Replace all live module-scope __constant variables by a single such variable
/// of struct type.  Assumes none of the constants contain pointers.  Eliminates
/// any dead module-scope __constant variables.
llvm::ModulePass *createClusterModuleScopeConstantVars();

/// Cluster plain-old-data kernel arguments into a single struct argument.
/// @return An LLVM module pass.
///
/// The idea is to save on the number of StorageBuffer (SSBO) arguments, as that
/// is a very limited resource.  Vulkan requires a minimum of 4 StorageBuffer
/// arguments (maxPerStageDescriptorStorageBuffers), which is very easy to
/// reach.
llvm::ModulePass *createClusterPodKernelArgumentsPass();

/// Splat select scalar condition with vector data operands.
/// @return An LLVM module pass.
///
/// Converts a select with scalar bool argument but vector operands so that
/// the bool condition is converted into a bool vector with as many elements
/// as the operands.
llvm::ModulePass *createSplatSelectConditionPass();

/// Hide loads from __constant address space.
/// @return An LLVM module pass.
///
/// Wrap the result of a load from __constant address space.  This prevents
/// the instcombine pass from generating selects over pointer-to-constant.
/// See https://github.com/google/clspv/issues/71
llvm::ModulePass *createHideConstantLoadsPass();

/// Unhide loads from __constant address space.
/// @return An LLVM module pass.
///
/// Unwrap the result of a load from __constant address space.
llvm::ModulePass *createUnhideConstantLoadsPass();

/// Rewrite insertvalue instructions.
/// @return An LLVM module pass.
///
/// Rewrite a chain of insertvalue instructions that cover all
/// members of a struct, so that it becomes a single new builtin
/// corresponding to an OpCompositeConstruct.  Only affects
/// insertvalue instructions with a single index operand.
///
/// Also, if -hack-inserts option is used, then also rewrite
/// chains of insertvalue instructions that only cover some but
/// not all of a struct.
llvm::ModulePass *createRewriteInsertsPass();

/// Allocate descriptors.
/// @return An LLVM module pass.
///
/// Replaces compile time samplers (from the sampler map), and kernel
/// arguments to descriptors.  Encoding is via compiler builtins
/// starting with "clspv.resource.*".  Uses of those kernel arguments
/// and samplers are replaced by calls the special functions yielding
/// the appropriately typed pointers.
llvm::ModulePass *createAllocateDescriptorsPass(
    llvm::ArrayRef<std::pair<unsigned, std::string>> samplerMap);

/// Direct Resource Access
/// @return An LLVM module pass.
///
/// For kernel arguments that map to resource variables (descriptors),
/// try to avoid passing them by pointer down into helper functions.
/// Find and exploit commonality among callees of each helper function.
/// Assumes descriptors have been allocated and mapped to function
/// calls of the form @clspv.resource.var.*.
llvm::ModulePass *createDirectResourceAccessPass();

/// Signed compare fixup
/// @return An LLVM module pass.
///
/// If -hack-scf is used, then rewrite signed integer comparisons
/// into other equivalent code that does not use signed integer
/// comparisons.  Works around a driver bug.
llvm::ModulePass *createSignedCompareFixupPass();

/// Share Module Scope Variables
/// @return An LLVM module pass.
///
/// Attempts to de-duplicate module scope Workgroup scope variables between
/// kernels. Module scope variables of the same type can be merged if they are
/// used by an exclusive set of kernels. This pass should run before direct
/// resource access to enable more opportunities for that pass.
llvm::ModulePass *createShareModuleScopeVariablesPass();

/// Exhaustively inline entry points
/// @return An LLVM module pass.
///
/// Exhaustively inlines all kernels in the module.
llvm::ModulePass *createInlineEntryPointsPass();
/// Scalarize composite instructions.
/// @return An LLVM module pass
///
/// Scalarizes instructions that return composite types. Works around driver
/// bugs. See HackPhis().
llvm::ModulePass *createScalarizePass();

/// Transform types for UBOs to conform to Vulkan 14.5.4 rules.
/// @return An LLVM module pass
///
/// Performs type mutation on the module so that types destined for UBOs satisfy
/// requirements in SPIR-V. It is assumed that the types are correct except for
/// LLVM inserted padding added to represent the types as laid out in OpenCL C.
llvm::ModulePass *createUBOTypeTransformPass();

/// Removes unused arguments from non-kernel functions.
/// @return An LLVM module pass
llvm::ModulePass *createRemoveUnusedArgumentsPass();

/// Specializes or inlines functions with UBO arguments to satisfy SPIR-V
/// requirements.
llvm::ModulePass *createMultiVersionUBOFunctionsPass();

/// Specialize image types.
llvm::ModulePass *createSpecializeImageTypesPass();

/// Fixes up the structurized cfg to have valid structured control flow.
/// Currently performs the following changes:
/// * Add a block to split a continue block used a merge block.
llvm::FunctionPass *createFixupStructuredCFGPass();

/// Adds attributes to intrinsic and builtin functions to produce a better
/// optimization outcome.
llvm::ModulePass *createAddFunctionAttributesPass();

/// Undo specific instcombine transformations that are harmful to generating
/// SPIR-V.
llvm::ModulePass *createUndoInstCombinePass();

/// Removes FreezeInsts from the IR.
llvm::ModulePass *createStripFreezePass();

/// Annotates kernels with the metadata indicating how the POD args should be
/// handled.
llvm::ModulePass *createAutoPodArgsPass();

/// Strips some builtin library functions when -cl-native-math is specified to
/// provide faster, lower precision alternatives.
llvm::ModulePass *createNativeMathPass();

} // namespace clspv
