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


cmake_minimum_required(VERSION 3.4.3)

# If we are the parent CMakeLists.txt, need to declare a project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(clspv)
endif()

# Check if required third-party dependencies exist.
macro(use_component path)
if(NOT IS_DIRECTORY ${path})
  message(FATAL_ERROR "Required component '${path}' does not exist! Please run 'python utils/fetch_sources.py' in the '${CMAKE_CURRENT_SOURCE_DIR}' folder.")
endif()
endmacro()

option(SKIP_CLSPV_TOOLS_INSTALL "Skip installation" ${SKIP_CLSPV_TOOLS_INSTALL})
if(NOT ${SKIP_CLSPV_TOOLS_INSTALL})
  set(ENABLE_CLSPV_TOOLS_INSTALL ON)
endif()


if(${CMAKE_CXX_COMPILER_ID} MATCHES "GNU")
	# GCC 7.3 complains about LLVM code: RetryAfterSignal in lib/Support/Process.cpp
	# Silence that warning for now.
	# TODO(dneto): Upgrade to newer LLVM to avoid this issue.
	add_compile_options("-Wno-noexcept-type")
endif()


use_component(${CMAKE_CURRENT_SOURCE_DIR}/third_party/clang)
use_component(${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm)

if (NOT DEFINED SPIRV_HEADERS_SOURCE_DIR)
  set(SPIRV_HEADERS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/SPIRV-Headers)
  use_component(${SPIRV_HEADERS_SOURCE_DIR})
endif()

if (NOT DEFINED SPIRV_TOOLS_SOURCE_DIR)
  set(SPIRV_TOOLS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/SPIRV-Tools)
  use_component(${SPIRV_TOOLS_SOURCE_DIR})
endif()

if (NOT TARGET spirv-dis)
  # First tell SPIR-V Tools where to find SPIR-V Headers
  set(SPIRV-Headers_SOURCE_DIR ${SPIRV_HEADERS_SOURCE_DIR})

  # Bring in the SPIR-V Tools repository which we'll use for testing
  add_subdirectory(${SPIRV_TOOLS_SOURCE_DIR}
      ${CMAKE_CURRENT_BINARY_DIR}/third_party/SPIRV-Tools EXCLUDE_FROM_ALL)
endif()

set(SPIRV_TOOLS_BINARY_DIR "$<TARGET_FILE_DIR:spirv-dis>")

set(CLSPV_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(CLSPV_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CLSPV_BINARY_DIR}/include
)

# First tell LLVM where to find clang.
set(LLVM_EXTERNAL_CLANG_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/clang)

# Then pull in LLVM for building.
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm EXCLUDE_FROM_ALL)

set(SPIRV_HEADERS_INCLUDE_DIRS
  ${SPIRV_HEADERS_SOURCE_DIR}/include/
)

set(LLVM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm)
set(LLVM_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/third_party/llvm)
set(LLVM_INCLUDE_DIRS
  ${LLVM_SOURCE_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/third_party/llvm/include
)

set(CLANG_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/clang)
set(CLANG_INCLUDE_DIRS
  ${CLANG_SOURCE_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/third_party/llvm/tools/clang/include
)

if(NOT WIN32)
  # Disable RTTI and exceptions (to match LLVM)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti -fno-exceptions")
endif()

# Bring in our cmake folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Bring in our lib folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/lib)

# Bring in our tools folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tools)

# Bring in our test folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/test)


if(ENABLE_CLSPV_TOOLS_INSTALL)
  install(
    FILES
      ${CMAKE_CURRENT_SOURCE_DIR}/include/clspv/AddressSpace.h
      ${CMAKE_CURRENT_SOURCE_DIR}/include/clspv/Passes.h
    DESTINATION
      ${CMAKE_INSTALL_INCLUDEDIR}/clspv/)
endif(ENABLE_CLSPV_TOOLS_INSTALL)
