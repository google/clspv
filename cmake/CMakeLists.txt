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

set(CLSPV_GENERATED_INCLUDES_DIR ${CLSPV_BINARY_DIR}/include/clspv)

set(SPIRV_C_STRINGS_INPUT_FILE ${SPIRV_HEADERS_SOURCE_DIR}/include/spirv/unified1/spirv.hpp)
set(SPIRV_C_STRINGS_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/spirv_c_strings.hpp)
set(SPIRV_C_STRINGS_NAMESPACE spv)
set(SPIRV_C_STRINGS_PYTHON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/spirv_c_strings.py)

file(MAKE_DIRECTORY "${CLSPV_GENERATED_INCLUDES_DIR}")

add_custom_target(clspv_c_strings
  DEPENDS ${SPIRV_C_STRINGS_OUTPUT_FILE})

add_custom_command(
  OUTPUT ${SPIRV_C_STRINGS_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${SPIRV_C_STRINGS_PYTHON_FILE}
    --input-file=${SPIRV_C_STRINGS_INPUT_FILE}
    --output-file=${SPIRV_C_STRINGS_OUTPUT_FILE}
    --namespace=${SPIRV_C_STRINGS_NAMESPACE}
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${SPIRV_C_STRINGS_INPUT_FILE} ${SPIRV_C_STRINGS_PYTHON_FILE})

set(DEFINE_CLSPV_BUILTINS_OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/clspv-builtins.h)
set(DEFINE_CLSPV_BUILTINS_PYTHON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/define_clspv_builtins.py)

add_custom_command(OUTPUT ${DEFINE_CLSPV_BUILTINS_OUTPUT_FILE}
    COMMAND ${PYTHON_EXECUTABLE} ${DEFINE_CLSPV_BUILTINS_PYTHON_FILE}
    --output-file=${DEFINE_CLSPV_BUILTINS_OUTPUT_FILE}
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  DEPENDS ${DEFINE_CLSPV_BUILTINS_PYTHON_FILE}
)

set(BAKE_FILE_INPUT_FILE ${DEFINE_CLSPV_BUILTINS_OUTPUT_FILE})
set(BAKE_FILE_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/opencl_builtins_header.h)
set(BAKE_FILE_BASE_HEADER_FILE ${CLANG_SOURCE_DIR}/lib/Headers/opencl-c-base.h)
set(BAKE_FILE_DATA_VARIABLE_NAME clspv_builtins_header_data)
set(BAKE_FILE_SIZE_VARIABLE_NAME clspv_builtins_header_size)
set(BAKE_FILE_DATA_BASE_VARIABLE_NAME opencl_base_builtins_header_data)
set(BAKE_FILE_SIZE_BASE_VARIABLE_NAME opencl_base_builtins_header_size)
set(BAKE_FILE_PYTHON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/bake_file.py)

add_custom_command(OUTPUT ${BAKE_FILE_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${BAKE_FILE_PYTHON_FILE}
    --input-header-file=${BAKE_FILE_INPUT_FILE}
    --input-base-file=${BAKE_FILE_BASE_HEADER_FILE}
    --output-file=${BAKE_FILE_OUTPUT_FILE}
    --header-var=${BAKE_FILE_DATA_VARIABLE_NAME}
    --header-size-var=${BAKE_FILE_SIZE_VARIABLE_NAME}
    --base-var=${BAKE_FILE_DATA_BASE_VARIABLE_NAME}
    --base-size-var=${BAKE_FILE_SIZE_BASE_VARIABLE_NAME}
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${BAKE_FILE_INPUT_FILE} ${BAKE_FILE_PYTHON_FILE} ${BAKE_FILE_BASE_HEADER_FILE}
)

add_custom_target(clspv_baked_opencl_header
  DEPENDS ${STRIP_BANNED_OPENCL_FEATURES_OUTPUT_FILE} ${BAKE_FILE_OUTPUT_FILE}
)

set(SPIRV_GLSL_INPUT_FILE ${SPIRV_HEADERS_SOURCE_DIR}/include/spirv/unified1/extinst.glsl.std.450.grammar.json)
set(SPIRV_GLSL_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/spirv_glsl.hpp)
set(SPIRV_GLSL_PYTHON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/spirv_ext_inst.py)

add_custom_target(clspv_glsl
  DEPENDS ${SPIRV_GLSL_OUTPUT_FILE})

add_custom_command(
  OUTPUT ${SPIRV_GLSL_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${SPIRV_GLSL_PYTHON_FILE}
    --input-file=${SPIRV_GLSL_INPUT_FILE}
    --output-file=${SPIRV_GLSL_OUTPUT_FILE}
    --namespace=glsl
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${SPIRV_GLSL_INPUT_FILE} ${SPIRV_GLSL_PYTHON_FILE})

set(SPIRV_REFLECTION_INPUT_FILE ${SPIRV_HEADERS_SOURCE_DIR}/include/spirv/unified1/extinst.nonsemantic.clspvreflection.grammar.json)
set(SPIRV_REFLECTION_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/spirv_reflection.hpp)
set(SPIRV_REFLECTION_PYTHON_FILE ${CMAKE_CURRENT_SOURCE_DIR}/spirv_ext_inst.py)

add_custom_target(clspv_reflection
  DEPENDS ${SPIRV_REFLECTION_OUTPUT_FILE})

add_custom_command(
  OUTPUT ${SPIRV_REFLECTION_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${SPIRV_REFLECTION_PYTHON_FILE}
    --input-file=${SPIRV_REFLECTION_INPUT_FILE}
    --output-file=${SPIRV_REFLECTION_OUTPUT_FILE}
    --namespace=reflection
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS ${SPIRV_REFLECTION_INPUT_FILE} ${SPIRV_REFLECTION_PYTHON_FILE})

set(CLSPV_LIBRARY_INPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/clspv--.bc)
set(CLSPV_LIBRARY_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/clspv_builtin_library.h)
set(CLSPV_LIBRARY_DATA_VAR_NAME clspv_builtin_library_data)
set(CLSPV_LIBRARY_SIZE_VAR_NAME clspv_builtin_library_size)

set(CLSPV64_LIBRARY_INPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/clspv64--.bc)
set(CLSPV64_LIBRARY_OUTPUT_FILE ${CLSPV_GENERATED_INCLUDES_DIR}/clspv64_builtin_library.h)
set(CLSPV64_LIBRARY_DATA_VAR_NAME clspv64_builtin_library_data)
set(CLSPV64_LIBRARY_SIZE_VAR_NAME clspv64_builtin_library_size)

add_custom_target(clspv_builtin_library
  DEPENDS ${CLSPV_LIBRARY_OUTPUT_FILE})

add_custom_target(clspv64_builtin_library
  DEPENDS ${CLSPV64_LIBRARY_OUTPUT_FILE})

add_custom_command(
  OUTPUT ${CLSPV_LIBRARY_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${BAKE_FILE_PYTHON_FILE}
    --input-header-file=${CLSPV_LIBRARY_INPUT_FILE}
    --output-file=${CLSPV_LIBRARY_OUTPUT_FILE}
    --header-var=${CLSPV_LIBRARY_DATA_VAR_NAME}
    --header-size=${CLSPV_LIBRARY_SIZE_VAR_NAME}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    DEPENDS ${BAKE_FILE_PYTHON_FILE} ${CLSPV_LIBRARY_INPUT_FILE}
)

add_custom_command(
  OUTPUT ${CLSPV64_LIBRARY_OUTPUT_FILE}
  COMMAND ${PYTHON_EXECUTABLE} ${BAKE_FILE_PYTHON_FILE}
    --input-header-file=${CLSPV64_LIBRARY_INPUT_FILE}
    --output-file=${CLSPV64_LIBRARY_OUTPUT_FILE}
    --header-var=${CLSPV64_LIBRARY_DATA_VAR_NAME}
    --header-size=${CLSPV64_LIBRARY_SIZE_VAR_NAME}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    DEPENDS ${BAKE_FILE_PYTHON_FILE} ${CLSPV64_LIBRARY_INPUT_FILE}
)
