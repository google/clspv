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

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.in ${CMAKE_CURRENT_BINARY_DIR}/lit.cfg @ONLY)

add_custom_target(check-spirv
  COMMAND ${LLVM_SOURCE_DIR}/utils/lit/lit.py --verbose ${CMAKE_CURRENT_BINARY_DIR}
    --path ${LLVM_BINARY_DIR}/bin
    --path ${SPIRV_TOOLS_BINARY_DIR}/
    --path "$<TARGET_FILE_DIR:clspv>"
  DEPENDS clspv spirv-as spirv-dis spirv-val spirv-opt FileCheck not
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
