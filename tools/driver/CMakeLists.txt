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

add_executable(clspv ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

# Enable C++11 for our executable
target_compile_features(clspv PRIVATE cxx_range_for)

target_include_directories(clspv PRIVATE ${CLSPV_INCLUDE_DIRS})

target_link_libraries(clspv PRIVATE clspv_passes clspv_core)

set_target_properties(clspv PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CLSPV_BINARY_DIR}/bin)

if(ENABLE_CLSPV_TOOLS_INSTALL)
  install(TARGETS clspv
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif(ENABLE_CLSPV_TOOLS_INSTALL)
