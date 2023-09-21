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

#include "AddFunctionAttributesPass.h"
#include "AllocateDescriptorsPass.h"
#include "AnnotationToMetadataPass.h"
#include "AutoPodArgsPass.h"
#include "ClusterConstants.h"
#include "ClusterPodKernelArgumentsPass.h"
#include "DeclarePushConstantsPass.h"
#include "DefineOpenCLWorkItemBuiltinsPass.h"
#include "DirectResourceAccessPass.h"
#include "FixupBuiltinsPass.h"
#include "FixupStructuredCFGPass.h"
#include "FunctionInternalizerPass.h"
#include "HideConstantLoadsPass.h"
#include "InlineEntryPointsPass.h"
#include "InlineFuncWithImageMetadataGetterPass.h"
#include "InlineFuncWithPointerBitCastArgPass.h"
#include "InlineFuncWithPointerToFunctionArgPass.h"
#include "InlineFuncWithSingleCallSitePass.h"
#include "KernelArgNamesToMetadataPass.h"
#include "LogicalPointerToIntPass.h"
#include "LongVectorLoweringPass.h"
#include "LowerAddrSpaceCastPass.h"
#include "LowerPrivatePointerPHIPass.h"
#include "MultiVersionUBOFunctionsPass.h"
#include "NativeMathPass.h"
#include "OpenCLInlinerPass.h"
#include "PhysicalPointerArgsPass.h"
#include "PrintfPass.h"
#include "RemoveUnusedArguments.h"
#include "ReorderBasicBlocksPass.h"
#include "ReplaceLLVMIntrinsicsPass.h"
#include "ReplaceOpenCLBuiltinPass.h"
#include "ReplacePointerBitcastPass.h"
#include "RewriteInsertsPass.h"
#include "RewritePackedStructs.h"
#include "SPIRVProducerPass.h"
#include "ScalarizePass.h"
#include "SetImageChannelMetadataPass.h"
#include "ShareModuleScopeVariables.h"
#include "SignedCompareFixupPass.h"
#include "SimplifyPointerBitcastPass.h"
#include "SpecializeImageTypes.h"
#include "SplatArgPass.h"
#include "SplatSelectCondition.h"
#include "StripFreezePass.h"
#include "ThreeElementVectorLoweringPass.h"
#include "UBOTypeTransformPass.h"
#include "UndoBoolPass.h"
#include "UndoByvalPass.h"
#include "UndoGetElementPtrConstantExprPass.h"
#include "UndoInstCombinePass.h"
#include "UndoSRetPass.h"
#include "UndoTranslateSamplerFoldPass.h"
#include "UndoTruncateToOddIntegerPass.h"
#include "WrapKernelPass.h"
#include "ZeroInitializeAllocasPass.h"

#endif
