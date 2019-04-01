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

if (ENABLE_CLSPV_OPT)
  set(CLSPV_TEST_SUFFIXES "['.cl', '.ll']")
else()
  set(CLSPV_TEST_SUFFIXES "['.cl']")
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.in ${CMAKE_CURRENT_BINARY_DIR}/lit.cfg @ONLY)

# Visual Studio puts LLVM executables in different location.
set (LLVM_BINARY_SUBDIR bin)
if (CMAKE_GENERATOR MATCHES "Visual Studio")
  set (LLVM_BINARY_SUBDIR ${CMAKE_BUILD_TYPE}/bin)
endif()

set(CLSPV_TEST_DEPENDS clspv spirv-as spirv-dis spirv-val spirv-opt)
if (NOT ${EXTERNAL_LLVM} EQUAL 1)
  set(CLSPV_TEST_DEPENDS ${CLSPV_TEST_DEPENDS} FileCheck not)
endif()

if (ENABLE_CLSPV_OPT)
  set(CLSPV_TEST_DEPENDS ${CLSPV_TEST_DEPENDS} clspv-opt)
  set(CLSPV_TEST_ADDITIONAL_PATH --path "$<TARGET_FILE_DIR:clspv-opt>")
endif()

# Use absolute paths in case of external LLVM.
get_filename_component(LIT_PATH ${LLVM_SOURCE_DIR}/utils/lit/lit.py ABSOLUTE)
get_filename_component(FILECHECK_PATH ${LLVM_BINARY_DIR}/${LLVM_BINARY_SUBDIR} ABSOLUTE)

add_custom_target(check-spirv
  COMMAND python ${LIT_PATH} --verbose ${CMAKE_CURRENT_BINARY_DIR}
    --path ${FILECHECK_PATH}
    --path ${SPIRV_TOOLS_BINARY_DIR}/
    --path "$<TARGET_FILE_DIR:clspv>"
    ${CLSPV_TEST_ADDITIONAL_PATH}
  DEPENDS ${CLSPV_TEST_DEPENDS}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
