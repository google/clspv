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

# Define build type for clspv_core
if (CLSPV_SHARED_LIB)
  set(CLSPV_LIB_TYPE SHARED)
else ()
  set(CLSPV_LIB_TYPE STATIC)
endif ()

# Core clspv library.  This contains support code for the driver, including
# the pass pipeline.
add_library(clspv_core ${CLSPV_LIB_TYPE}
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
  ${CMAKE_CURRENT_SOURCE_DIR}/AnnotationToMetadataPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/BitcastUtils.cpp
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
  ${CMAKE_CURRENT_SOURCE_DIR}/FeatureMacro.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FixupBuiltinsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FixupStructuredCFGPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/FunctionInternalizerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/HideConstantLoadsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineEntryPointsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithImageMetadataGetterPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithPointerBitCastArgPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithPointerToFunctionArgPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/InlineFuncWithSingleCallSitePass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/KernelArgNamesToMetadataPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Layout.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/LogicalPointerToIntPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/LongVectorLoweringPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SetImageChannelMetadataPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ThreeElementVectorLoweringPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/WrapKernelPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/LowerAddrSpaceCastPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/LowerPrivatePointerPHIPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/MultiVersionUBOFunctionsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/NativeMathPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/NormalizeGlobalVariable.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/OpenCLInlinerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Option.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/Passes.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/PhysicalPointerArgsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/PrintfPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/PushConstant.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SPIRVOp.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SPIRVProducerPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RemoveUnusedArguments.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReorderBasicBlocksPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplaceLLVMIntrinsicsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplaceOpenCLBuiltinPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/ReplacePointerBitcastPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RewriteInsertsPass.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/RewritePackedStructs.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/SamplerUtils.cpp
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

# Dependencies of clspv_lib
set(CLSPV_LLVM_COMPONENTS
  LLVMAggressiveInstCombine
  LLVMAnalysis
  LLVMCodeGen
  LLVMCore
  LLVMInstCombine
  LLVMInstrumentation
  LLVMObjCARCOpts
  LLVMPasses
  LLVMScalarOpts
  LLVMSupport
  LLVMTransformUtils
  LLVMVectorize
  LLVMipo
)

if(${EXTERNAL_LLVM} EQUAL 1)
  include(${CLSPV_LLVM_BINARY_DIR}/lib/cmake/llvm/LLVMConfig.cmake)

  llvm_map_components_to_libnames(CLSPV_LLVM_LINKS ${CLSPV_LLVM_COMPONENTS})

  include(${CLSPV_LLVM_BINARY_DIR}/lib/cmake/clang/ClangConfig.cmake)
endif()

# clspv_c_strings, clspv_glsl, and clspv_reflection are used by SPIRVProducerPass.cpp.
add_dependencies(clspv_passes clspv_c_strings clspv_glsl clspv_reflection)
target_link_libraries(clspv_passes PRIVATE ${CLSPV_LLVM_COMPONENTS})

# clspv_baked_opencl_header and clspv_builtin_library are used by Compiler.cpp.
add_dependencies(clspv_core clspv_baked_opencl_header clspv_builtin_library clspv64_builtin_library)
target_link_libraries(clspv_core PUBLIC clspv_passes)
target_link_libraries(clspv_core PRIVATE
  LLVMIRReader
  LLVMLinker
  ${CLSPV_LLVM_COMPONENTS}
  clangAST
  clangBasic
  clangCodeGen
  clangFrontend
  clangSerialization
)

if (MSVC)
  set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/SPIRVProducerPass.cpp"
    # 4596: Upgrade to newer LLVM.  See https://github.com/google/clspv/issues/153
    PROPERTIES COMPILE_FLAGS "/Wall /WX /wd4710 /wd4820 /wd4625 /wd4626 /wd5026 /wd5027 /wd4061 /wd4711 /wd4996 /wd4530 /wd4577 /wd4514 /wd4365 /wd4987 /wd4774 /wd4623 /wd4571 /wd4596 /wd5039 /wd5045"
  )
endif()

if (ENABLE_CLSPV_INSTALL)
  include(../cmake/util.cmake)
  if (NOT CLSPV_SHARED_LIB)
    clspv_combine_static_lib(clspv_combined clspv_core)
  endif()

  install(
    FILES
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/AddressSpace.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/ArgKind.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/Compiler.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/FeatureMacro.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/Option.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/Passes.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/PushConstant.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/Sampler.h
      ${CMAKE_CURRENT_SOURCE_DIR}/../include/clspv/SpecConstant.h
    DESTINATION
      ${CMAKE_INSTALL_INCLUDEDIR}/clspv/)

  install(
    TARGETS clspv_core clspv_passes
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

  if (NOT CLSPV_SHARED_LIB)
    # Since clspv_combined is defined as an imported library, we cannot use the
    # install() directive to install it. Install it like a normal file.
    get_target_property(generated_location clspv_combined LOCATION)
    string(REGEX MATCH "Visual Studio .*" vs_generator "${CMAKE_GENERATOR}")
    if (NOT "${vs_generator}" STREQUAL "")
      # With Visual Studio generators, the LOCATION property is not properly
      # expanded according to the current build configuration. We need to work
      # around this problem by manually substitution.
      string(REPLACE "$(Configuration)" "\${CMAKE_INSTALL_CONFIG_NAME}"
        install_location "${generated_location}")
      install(FILES ${install_location} DESTINATION ${CMAKE_INSTALL_LIBDIR})
    else()
      install(FILES ${generated_location} DESTINATION ${CMAKE_INSTALL_LIBDIR})
    endif()
  endif()
endif()
