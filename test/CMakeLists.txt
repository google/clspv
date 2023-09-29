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


cmake_minimum_required(VERSION 3.13.4)

# Enable ccache if installed. Use all default options currently:
# https://ccache.dev/manual/latest.html#_configuration_options
find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
endif(CCACHE_FOUND)

if(NOT COMMAND find_host_package)
  macro(find_host_package)
    find_package(${ARGN})
  endmacro()
endif()

# Tests require Python3
find_host_package(PythonInterp 3 REQUIRED)

# If we are the parent CMakeLists.txt, need to declare a project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(clspv)
endif()

set(CMAKE_CXX_STANDARD 17)

# Make sure CMAKE_BUILD_TYPE gets a value because we rely on it for
# running unit tests correctly on Windows.
if (NOT DEFINED CMAKE_BUILD_TYPE)
  message(STATUS "CMAKE_BUILD_TYPE was not specified, defaulting to Debug")
  set(CMAKE_BUILD_TYPE Debug)
endif()

# Check if required third-party dependencies exist.
macro(use_component path)
if(NOT IS_DIRECTORY ${path})
  message(FATAL_ERROR "Required component '${path}' does not exist! Please run 'python utils/fetch_sources.py' in the '${CMAKE_CURRENT_SOURCE_DIR}' folder.")
endif()
endmacro()

option(CLSPV_SHARED_LIB "Build shared lib of clspv (tools will use shared linkage to libclspv_core.so)" OFF)

option(SKIP_CLSPV_INSTALL "Skip installation" ${SKIP_CLSPV_INSTALL})
if(NOT ${SKIP_CLSPV_INSTALL})
  set(ENABLE_CLSPV_INSTALL ON)
endif()

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

if (NOT DEFINED SPIRV_HEADERS_SOURCE_DIR)
  set(SPIRV_HEADERS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/SPIRV-Headers)
  use_component(${SPIRV_HEADERS_SOURCE_DIR})
endif()

if (NOT DEFINED SPIRV_TOOLS_SOURCE_DIR)
  set(SPIRV_TOOLS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/SPIRV-Tools)
  use_component(${SPIRV_TOOLS_SOURCE_DIR})
endif()

option(CLSPV_BUILD_SPIRV_DIS "Enable build of spirv-dis if the target does not exist" ON)
if (NOT TARGET spirv-dis AND CLSPV_BUILD_SPIRV_DIS)
  # First tell SPIR-V Tools where to find SPIR-V Headers
  set(SPIRV-Headers_SOURCE_DIR ${SPIRV_HEADERS_SOURCE_DIR})

  # Bring in the SPIR-V Tools repository
  add_subdirectory(${SPIRV_TOOLS_SOURCE_DIR}
      ${CMAKE_CURRENT_BINARY_DIR}/third_party/SPIRV-Tools EXCLUDE_FROM_ALL)
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(SPIRV_TOOLS_BINARY_DIR "$<TARGET_FILE_DIR:spirv-dis>")

option(ENABLE_CLSPV_OPT "Enable the clspv-opt driver." ON)

if (NOT DEFINED EXTERNAL_LLVM)
  set(EXTERNAL_LLVM 0)
endif()
if (${EXTERNAL_LLVM} EQUAL 1)
  if (NOT DEFINED CLSPV_LLVM_SOURCE_DIR)
    message(FATAL_ERROR "External LLVM requires CLSPV_LLVM_SOURCE_DIR to be specified")
  endif()
  if (NOT DEFINED CLSPV_CLANG_SOURCE_DIR)
    message(FATAL_ERROR "External LLVM requires CLSPV_CLANG_SOURCE_DIR to be specified")
  endif()
  if (NOT DEFINED CLSPV_LLVM_BINARY_DIR)
    message(FATAL_ERROR "External LLVM requires CLSPV_LLVM_BINARY_DIR to be specified")
  endif()
else()
  # Setup to use the LLVM monorepo.
  if (NOT DEFINED CLSPV_LLVM_SOURCE_DIR)
    set(CLSPV_LLVM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm/llvm)
  endif()

  if (NOT DEFINED CLSPV_CLANG_SOURCE_DIR)
    set(CLSPV_CLANG_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm/clang)
  endif()

  use_component(${CLSPV_LLVM_SOURCE_DIR})
  use_component(${CLSPV_CLANG_SOURCE_DIR})

  # Kokoro bots have older toolchains so make that LLVM check a warning.
  option(LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN "" ON)
  set(CLSPV_LLVM_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR}/third_party/llvm)

  # First tell LLVM where to find clang.
  set(LLVM_EXTERNAL_CLANG_SOURCE_DIR ${CLSPV_CLANG_SOURCE_DIR})

  # Tell LLVM not to build any targets.
  set(LLVM_TARGETS_TO_BUILD ""
      CACHE STRING "Semicolon-separated list of targets to build, or \"all\".")

  # Then pull in LLVM for building.
  add_subdirectory(${CLSPV_LLVM_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/third_party/llvm EXCLUDE_FROM_ALL)

  # Ensure clspv and LLVM use the same build options (e.g. -D_FILE_OFFSET_BITS=64).
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/third_party/llvm/llvm/cmake/modules/)
  include(HandleLLVMOptions)
endif()

set(CLSPV_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(CLSPV_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CLSPV_BINARY_DIR}/include
)

set(SPIRV_HEADERS_INCLUDE_DIRS
  ${SPIRV_HEADERS_SOURCE_DIR}/include/
)

set(LLVM_SOURCE_DIR ${CLSPV_LLVM_SOURCE_DIR})
set(LLVM_BINARY_DIR ${CLSPV_LLVM_BINARY_DIR})
set(LLVM_INCLUDE_DIRS
  ${LLVM_SOURCE_DIR}/include
  ${CLSPV_LLVM_BINARY_DIR}/include
)

set(CLANG_SOURCE_DIR ${CLSPV_CLANG_SOURCE_DIR})
set(CLANG_INCLUDE_DIRS
  ${CLANG_SOURCE_DIR}/include
  ${CLSPV_LLVM_BINARY_DIR}/tools/clang/include
)

if(NOT WIN32)
  # Disable RTTI and exceptions (to match LLVM)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti -fno-exceptions")
endif()

if(${CMAKE_CXX_COMPILER_ID} MATCHES "GNU")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror=unused-variable -Werror=switch")
elseif(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror-unused-variable -Werror-switch")
endif()

# Bring in our cmake folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Bring in our lib folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/lib)

# Bring in our tools folder
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/tools)

option(CLSPV_BUILD_TESTS "Enable the build of clspv tests" ON)
if (CLSPV_BUILD_TESTS)
  # Bring in our test folder
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/test)
endif()
