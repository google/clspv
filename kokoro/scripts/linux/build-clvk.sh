#!/bin/bash
# Copyright 2019 The Clspv Authors. All rights reserved.
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

# Fail on any error.
set -e

. /bin/using.sh # Declare the bash 'using' function.

# Display commands being run.
set -x

# Common tools.
using cmake-3.17.2
using gcc-7
using ninja-1.10.0

BUILD_ROOT=$PWD
SRC=$PWD/github/clspv

if [ "$BUILD_TOOLCHAIN" == "clang" ]; then
  using clang-8.0.0
fi

# Get Clspv dependencies.
cd $SRC
/usr/bin/python3 utils/fetch_sources.py

# Get and build Vulkan-Headers
echo $(date): Starting Vulkan-Headers build...
VULKAN_HEADERS_SRC="$BUILD_ROOT/github/vulkan-headers"
VULKAN_HEADERS_BUILD="$VULKAN_HEADERS_SRC/build"
git clone https://github.com/KhronosGroup/Vulkan-Headers "$VULKAN_HEADERS_SRC"
cd "$VULKAN_HEADERS_SRC" && git checkout tags/v1.1.129
mkdir "$VULKAN_HEADERS_BUILD" && cd "$VULKAN_HEADERS_BUILD"
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=$PWD "$VULKAN_HEADERS_SRC"
ninja install
echo $(date): Vulkan-Headers build completed.

# Get and build Vulkan-Loader
echo $(date): Starting Vulkan-Loader build...
VULKAN_LOADER_SRC="$BUILD_ROOT/github/vulkan-loader"
VULKAN_LOADER_BUILD="$VULKAN_LOADER_SRC/build"
git clone https://github.com/KhronosGroup/Vulkan-Loader "$VULKAN_LOADER_SRC"
cd "$VULKAN_LOADER_SRC" && git checkout tags/v1.1.129
mkdir "$VULKAN_LOADER_BUILD" && cd "$VULKAN_LOADER_BUILD"
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DVULKAN_HEADERS_INSTALL_DIR="$VULKAN_HEADERS_BUILD" -DBUILD_WSI_WAYLAND_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF "$VULKAN_LOADER_SRC" -DBUILD_WSI_XCB_SUPPORT=OFF
ninja
echo $(date): Vulkan-Loader build completed.

# Get and build SwiftShader
echo $(date): Starting SwiftShader build...
SWIFTSHADER_SRC="$BUILD_ROOT/github/swiftshader"
SWIFTSHADER_BUILD="$SWIFTSHADER_SRC/kokoro-build"
git clone https://swiftshader.googlesource.com/SwiftShader.git "$SWIFTSHADER_SRC"
cd "$SWIFTSHADER_SRC" && git submodule update --init
mkdir "$SWIFTSHADER_BUILD" && cd "$SWIFTSHADER_BUILD"
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
      -DSWIFTSHADER_WARNINGS_AS_ERRORS=OFF  -DSWIFTSHADER_BUILD_VULKAN=ON -DSWIFTSHADER_BUILD_EGL=OFF -DSWIFTSHADER_BUILD_GLESv2=OFF \
      -DSWIFTSHADER_BUILD_GLES_CM=OFF -DSWIFTSHADER_BUILD_SAMPLES=OFF -DSWIFTSHADER_BUILD_TESTS=OFF -DSWIFTSHADER_BUILD_PVR=OFF \
      "$SWIFTSHADER_SRC"
ninja
echo $(date): SwiftShader build completed.

# Get and build Clvk
echo $(date): Starting Clvk build...
CLVK_SRC="$BUILD_ROOT/github/clvk"
CLVK_BUILD="$CLVK_SRC/build"
git clone https://github.com/kpet/clvk "$CLVK_SRC"
cd "$CLVK_SRC" && git submodule update --init
mkdir "$CLVK_BUILD" && cd "$CLVK_BUILD"
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCLVK_CLSPV_ONLINE_COMPILER=ON -DCLSPV_SOURCE_DIR="$SRC" \
  -DCLVK_VULKAN_IMPLEMENTATION=custom -DVulkan_INCLUDE_DIRS=$CLVK_SRC/external/Vulkan-Headers/include -DVulkan_LIBRARIES="$VULKAN_LOADER_BUILD/loader/libvulkan.so" \
  "$CLVK_SRC"
ninja
echo $(date): Clvk build completed.

# Run Clvk tests
echo $(date): Starting Clvk smoke tests...
export VK_ICD_FILENAMES="$SWIFTSHADER_BUILD/Linux/vk_swiftshader_icd.json"
./simple_test
echo $(date): Clvk smoke tests completed.
