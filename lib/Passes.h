// Copyright 2019 The Clspv Authors. All rights reserved.
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

#ifndef _CLSPV_LIB_PASSES_H
#define _CLSPV_LIB_PASSES_H

namespace llvm {
class PassRegistry;

// Individual pass initializers.  See the documentation for
// initializeClspvPasses() in include/clspv/Passes.h.
void initializeAddFunctionAttributesPassPass(PassRegistry &);
void initializeAllocateDescriptorsPassPass(PassRegistry &);
void initializeClusterModuleScopeConstantVarsPass(PassRegistry &);
void initializeClusterPodKernelArgumentsPassPass(PassRegistry &);
void initializeDeclarePushConstantsPassPass(PassRegistry &);
void initializeDefineOpenCLWorkItemBuiltinsPassPass(PassRegistry &);
void initializeDirectResourceAccessPassPass(PassRegistry &);
void initializeFixupStructuredCFGPassPass(PassRegistry &);
void initializeFunctionInternalizerPassPass(PassRegistry &);
void initializeHideConstantLoadsPassPass(PassRegistry &);
void initializeUnhideConstantLoadsPassPass(PassRegistry &);
void initializeInlineEntryPointsPassPass(PassRegistry &);
void initializeInlineFuncWithPointerBitCastArgPassPass(PassRegistry &);
void initializeInlineFuncWithPointerToFunctionArgPassPass(PassRegistry &);
void initializeInlineFuncWithSingleCallSitePassPass(PassRegistry &);
void initializeOpenCLInlinerPassPass(PassRegistry &);
void initializeRemoveUnusedArgumentsPass(PassRegistry &);
void initializeReorderBasicBlocksPassPass(PassRegistry &);
void initializeReplaceLLVMIntrinsicsPassPass(PassRegistry &);
void initializeReplaceOpenCLBuiltinPassPass(PassRegistry &);
void initializeReplacePointerBitcastPassPass(PassRegistry &);
void initializeRewriteInsertsPassPass(PassRegistry &);
void initializeScalarizePassPass(PassRegistry &);
void initializeShareModuleScopeVariablesPassPass(PassRegistry &);
void initializeSignedCompareFixupPassPass(PassRegistry &);
void initializeSimplifyPointerBitcastPassPass(PassRegistry &);
void initializeSplatArgPassPass(PassRegistry &);
void initializeSplatSelectConditionPassPass(PassRegistry &);
void initializeSpecializeImageTypesPassPass(PassRegistry &);
void initializeUBOTypeTransformPassPass(PassRegistry &);
void initializeUndoBoolPassPass(PassRegistry &);
void initializeUndoByvalPassPass(PassRegistry &);
void initializeUndoGetElementPtrConstantExprPassPass(PassRegistry &);
void initializeUndoSRetPassPass(PassRegistry &);
void initializeUndoTranslateSamplerFoldPassPass(PassRegistry &);
void initializeUndoTruncatedSwitchConditionPassPass(PassRegistry &);
void initializeZeroInitializeAllocasPassPass(PassRegistry &);
} // namespace llvm

#endif
