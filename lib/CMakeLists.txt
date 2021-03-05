# Copyright 2017 The Clspv Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Core clspv library.  This contains support code for the driver, including
# the pass pipeline.
add_library(clspv_core
  ${CMAKE_CURRENT_SOURCE_DIR}/Compiler.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FrontendPlugin.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Sampler.cpp
)

# Pass library.  Transformation passes and pass-specific support are
# defined here.  This must be loadable by LLVM opt for testing individual
# passes.
add_library(clspv_passes OBJECT
  ${CMAKE_CURRENT_SOURCE_DIR}/AddFunctionAttributesPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/AllocateDescriptorsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ArgKind.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/AutoPodArgsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Builtins.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/CallGraphOrderedFunctions.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ClusterPodKernelArgumentsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ClusterConstants.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ComputeStructuredOrder.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ConstantEmitter.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Constants.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/DeclarePushConstantsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/DefineOpenCLWorkItemBuiltinsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/DescriptorCounter.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/DirectResourceAccessPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FixupStructuredCFGPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FunctionInternalizerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/HideConstantLoadsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineEntryPointsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithPointerBitCastArgPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithPointerToFunctionArgPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithSingleCallSitePass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Layout.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/LongVectorLoweringPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/MultiVersionUBOFunctionsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/NativeMathPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/NormalizeGlobalVariable.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/OpenCLInlinerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Option.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Passes.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/PushConstant.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SPIRVOp.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SPIRVProducerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RemoveUnusedArguments.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReorderBasicBlocksPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplaceLLVMIntrinsicsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplaceOpenCLBuiltinPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplacePointerBitcastPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RewriteInsertsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ScalarizePass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ShareModuleScopeVariables.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SignedCompareFixupPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SimplifyPointerBitcastPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SpecConstant.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SpecializeImageTypes.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SplatArgPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SplatSelectCondition.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/StripFreezePass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Types.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UBOTypeTransformPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoBoolPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoByvalPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoGetElementPtrConstantExprPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoInstCombinePass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoSRetPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoTranslateSamplerFoldPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/UndoTruncateToOddIntegerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ZeroInitializeAllocasPass.cpp
)

foreach(clspv_lib clspv_core clspv_passes)
  # Enable C++11 for our executable
  target_compile_features(${clspv_lib} PRIVATE cxx_range_for)

  target_include_directories(${clspv_lib} PRIVATE ${SPIRV_HEADERS_INCLUDE_DIRS})

  target_include_directories(${clspv_lib} PRIVATE ${LLVM_INCLUDE_DIRS})

  target_include_directories(${clspv_lib} PRIVATE ${CLANG_INCLUDE_DIRS})

  target_include_directories(${clspv_lib} PUBLIC ${CLSPV_INCLUDE_DIRS})

endforeach(clspv_lib)

set(CLSPV_LLVM_COMPONENTS LLVMAnalysis LLVMScalarOpts LLVMCore LLVMTransformUtils LLVMCodeGen)

if(${EXTERNAL_LLVM} EQUAL 1)
  include(${CLSPV_LLVM_BINARY_DIR}/lib/cmake/llvm/LLVMConfig.cmake)

  llvm_map_components_to_libnames(CLSPV_LLVM_LINKS ${CLSPV_LLVM_COMPONENTS})

  include(${CLSPV_LLVM_BINARY_DIR}/lib/cmake/clang/ClangConfig.cmake)
endif()

# clspv_c_strings, clspv_glsl, and clspv_reflection are used by SPIRVProducerPass.cpp.
add_dependencies(clspv_passes clspv_c_strings clspv_glsl clspv_reflection)
target_link_libraries(clspv_passes PRIVATE ${CLSPV_LLVM_COMPONENTS})

# clspv_baked_opencl_header and clspv_builtin_library are used by Compiler.cpp.
add_dependencies(clspv_core clspv_baked_opencl_header clspv_builtin_library)
target_link_libraries(clspv_core PUBLIC clspv_passes)
target_link_libraries(clspv_core PRIVATE clangCodeGen)

if (MSVC)
  set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/SPIRVProducerPass.cpp"
    # 4596: Upgrade to newer LLVM.  See https://github.com/google/clspv/issues/153
    PROPERTIES COMPILE_FLAGS "/Wall /WX /wd4710 /wd4820 /wd4625 /wd4626 /wd5026 /wd5027 /wd4061 /wd4711 /wd4996 /wd4530 /wd4577 /wd4514 /wd4365 /wd4987 /wd4774 /wd4623 /wd4571 /wd4596 /wd5039 /wd5045"
  )
endif()

if(ENABLE_CLSPV_TOOLS_INSTALL)
  install(
    TARGETS clspv_core clspv_passes
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )
endif(ENABLE_CLSPV_TOOLS_INSTALL)
