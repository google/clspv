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
using cmake-3.31.2
using gcc-13
using ninja-1.10.0
using python-3.12

BUILD_ROOT=$PWD
SRC=$PWD/github/clspv

if [ "$BUILD_TOOLCHAIN" == "clang" ]; then
  using clang-13.0.1
fi

# Get Clspv dependencies.
cd $SRC
python3 utils/fetch_sources.py

VULKAN_VERSION=v1.3.243

# Get and build Vulkan-Headers
echo $(date): Starting Vulkan-Headers build...
VULKAN_HEADERS_SRC="${BUILD_ROOT}/github/vulkan-headers"
VULKAN_HEADERS_BUILD="${VULKAN_HEADERS_SRC}/build"
VULKAN_HEADERS_INSTALL="${VULKAN_HEADERS_SRC}/install"
git clone https://github.com/KhronosGroup/Vulkan-Headers "${VULKAN_HEADERS_SRC}"
git -C "${VULKAN_HEADERS_SRC}" checkout tags/${VULKAN_VERSION}
mkdir "${VULKAN_HEADERS_INSTALL}"
mkdir "${VULKAN_HEADERS_BUILD}"
cmake -G Ninja -DCMAKE_INSTALL_PREFIX="${VULKAN_HEADERS_INSTALL}" -S "${VULKAN_HEADERS_SRC}" -B "${VULKAN_HEADERS_BUILD}"
cmake --build "${VULKAN_HEADERS_BUILD}" --target install
echo $(date): Vulkan-Headers build completed.

# Get and build Vulkan-Loader
echo $(date): Starting Vulkan-Loader build...
VULKAN_LOADER_SRC="${BUILD_ROOT}/github/vulkan-loader"
VULKAN_LOADER_BUILD="${VULKAN_LOADER_SRC}/build"
git clone https://github.com/KhronosGroup/Vulkan-Loader "${VULKAN_LOADER_SRC}"
git -C "${VULKAN_LOADER_SRC}" checkout tags/${VULKAN_VERSION}
mkdir "${VULKAN_LOADER_BUILD}"
cmake -GNinja -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
      -DVULKAN_HEADERS_INSTALL_DIR="${VULKAN_HEADERS_INSTALL}" -DBUILD_WSI_WAYLAND_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF \
      -DBUILD_WSI_XCB_SUPPORT=OFF -S "${VULKAN_LOADER_SRC}" -B "${VULKAN_LOADER_BUILD}"
cmake --build "${VULKAN_LOADER_BUILD}"
echo $(date): Vulkan-Loader build completed.

# Get and build SwiftShader
echo $(date): Starting SwiftShader build...
SWIFTSHADER_SRC="$BUILD_ROOT/github/swiftshader"
SWIFTSHADER_BUILD="$SWIFTSHADER_SRC/kokoro-build"
git clone https://swiftshader.googlesource.com/SwiftShader.git "$SWIFTSHADER_SRC"
mkdir "$SWIFTSHADER_BUILD" && cd "$SWIFTSHADER_BUILD"
cmake -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
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
cmake -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCLVK_CLSPV_ONLINE_COMPILER=ON -DCLSPV_SOURCE_DIR="$SRC" \
  -DCLVK_ENABLE_ASSERTIONS=ON \
  -DCLVK_VULKAN_IMPLEMENTATION=custom -DVulkan_INCLUDE_DIRS=${VULKAN_HEADERS_SRC}/include -DVulkan_LIBRARIES="$VULKAN_LOADER_BUILD/loader/libvulkan.so" \
  -DCLVK_ENABLE_SPIRV_IL=OFF \
  "$CLVK_SRC"
ninja
echo $(date): Clvk build completed.

# Run Clvk tests
echo $(date): Starting Clvk smoke tests...
export VK_ICD_FILENAMES="$SWIFTSHADER_BUILD/Linux/vk_swiftshader_icd.json"
export CLVK_LOG=2
./simple_test
echo $(date): Clvk smoke tests completed.
