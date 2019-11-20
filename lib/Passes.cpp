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

#include "Passes.h"

namespace llvm {

void initializeClspvPasses(PassRegistry &r) {
  initializeAllocateDescriptorsPassPass(r);
  initializeClusterModuleScopeConstantVarsPass(r);
  initializeClusterPodKernelArgumentsPassPass(r);
  initializeDirectResourceAccessPassPass(r);
  initializeDefineOpenCLWorkItemBuiltinsPassPass(r);
  initializeFunctionInternalizerPassPass(r);
  initializeHideConstantLoadsPassPass(r);
  initializeUnhideConstantLoadsPassPass(r);
  initializeInlineEntryPointsPassPass(r);
  initializeInlineFuncWithPointerBitCastArgPassPass(r);
  initializeInlineFuncWithPointerToFunctionArgPassPass(r);
  initializeInlineFuncWithSingleCallSitePassPass(r);
  initializeOpenCLInlinerPassPass(r);
  initializeRemoveUnusedArgumentsPass(r);
  initializeReorderBasicBlocksPassPass(r);
  initializeReplaceLLVMIntrinsicsPassPass(r);
  initializeReplaceOpenCLBuiltinPassPass(r);
  initializeReplacePointerBitcastPassPass(r);
  initializeRewriteInsertsPassPass(r);
  initializeScalarizePassPass(r);
  initializeShareModuleScopeVariablesPassPass(r);
  initializeSignedCompareFixupPassPass(r);
  initializeSimplifyPointerBitcastPassPass(r);
  initializeSplatArgPassPass(r);
  initializeSplatSelectConditionPassPass(r);
  initializeSpecializeImageTypesPassPass(r);
  initializeUBOTypeTransformPassPass(r);
  initializeUndoBoolPassPass(r);
  initializeUndoByvalPassPass(r);
  initializeUndoGetElementPtrConstantExprPassPass(r);
  initializeUndoSRetPassPass(r);
  initializeUndoTranslateSamplerFoldPassPass(r);
  initializeUndoTruncatedSwitchConditionPassPass(r);
  initializeZeroInitializeAllocasPassPass(r);
}

} // namespace llvm
