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
# Display commands being run.
set -x

BUILD_ROOT=$PWD
SRC=$PWD/github/clspv
CONFIG=$1
COMPILER=$2

SKIP_TESTS="False"
BUILD_TYPE="Debug"

# We need a newer libstdc++ for clvk
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update -qq
sudo apt install -y g++-7

CMAKE_C_CXX_COMPILER=""
if [ $COMPILER = "clang" ]; then
  # Use newer clang than default.
  CMAKE_C_CXX_COMPILER="-DCMAKE_C_COMPILER=/usr/bin/clang-5.0 -DCMAKE_CXX_COMPILER=/usr/bin/clang++-5.0"
else
  # Specify we want to build with GCC 7 (which supports C++14)
  sudo add-apt-repository ppa:ubuntu-toolchain-r/test
  sudo apt-get update
  sudo apt-get install -y gcc-7 g++-7
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100 --slave /usr/bin/g++ g++ /usr/bin/g++-7
  sudo update-alternatives --set gcc "/usr/bin/gcc-7"
  CMAKE_C_CXX_COMPILER="-DCMAKE_C_COMPILER=/usr/bin/gcc-7 -DCMAKE_CXX_COMPILER=/usr/bin/g++-7"
fi

# Possible configurations are:
# ASAN, RELEASE, DEBUG, DEBUG_EXCEPTION, RELEASE_MINGW

if [ $CONFIG = "RELEASE" ] || [ $CONFIG = "RELEASE_MINGW" ]
then
  BUILD_TYPE="RelWithDebInfo"
fi

ADDITIONAL_CMAKE_FLAGS=""
if [ $CONFIG = "ASAN" ]
then
  ADDITIONAL_CMAKE_FLAGS="-DCMAKE_CXX_FLAGS=-fsanitize=address -DCMAKE_C_FLAGS=-fsanitize=address"
  export ASAN_SYMBOLIZER_PATH=/usr/bin/llvm-symbolizer-3.4
elif [ $CONFIG = "COVERAGE" ]
then
  ADDITIONAL_CMAKE_FLAGS="-DENABLE_CODE_COVERAGE=ON"
  SKIP_TESTS="True"
elif [ $CONFIG = "DEBUG_EXCEPTION" ]
then
  ADDITIONAL_CMAKE_FLAGS="-DDISABLE_EXCEPTIONS=ON -DDISABLE_RTTI=ON"
elif [ $CONFIG = "RELEASE_MINGW" ]
then
  ADDITIONAL_CMAKE_FLAGS="-Dgtest_disable_pthreads=ON -DCMAKE_TOOLCHAIN_FILE=$SRC/cmake/linux-mingw-toolchain.cmake"
  SKIP_TESTS="True"
fi

# Get NINJA.
wget -q https://github.com/ninja-build/ninja/releases/download/v1.8.2/ninja-linux.zip
unzip -q ninja-linux.zip
export PATH="$PWD:$PATH"

# Get newer version of CMake
wget -q https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz
tar xf cmake-3.16.0-Linux-x86_64.tar.gz
export PATH="$PWD/cmake-3.16.0-Linux-x86_64/bin:$PATH"

# Get Clspv dependencies.
cd $SRC
python utils/fetch_sources.py

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
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE $ADDITIONAL_CMAKE_FLAGS $CMAKE_C_CXX_COMPILER \
  -DVULKAN_HEADERS_INSTALL_DIR="$VULKAN_HEADERS_BUILD" -DBUILD_WSI_WAYLAND_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF "$VULKAN_LOADER_SRC"
ninja
echo $(date): Vulkan-Loader build completed.

# Get and build SwiftShader
echo $(date): Starting SwiftShader build...
SWIFTSHADER_SRC="$BUILD_ROOT/github/swiftshader"
SWIFTSHADER_BUILD="$SWIFTSHADER_SRC/kokoro-build"
git clone https://swiftshader.googlesource.com/SwiftShader.git "$SWIFTSHADER_SRC"
cd "$SWIFTSHADER_SRC" && git submodule update --init
mkdir "$SWIFTSHADER_BUILD" && cd "$SWIFTSHADER_BUILD"
# Use gold to workaround an issue with GNU ld v2.26
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE $ADDITIONAL_CMAKE_FLAGS $CMAKE_C_CXX_COMPILER \
  -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=gold" \
  -DBUILD_VULKAN=ON -DBUILD_EGL=OFF -DBUILD_GLESv2=OFF -DBUILD_GLES_CM=OFF -DBUILD_SAMPLES=OFF -DBUILD_TESTS=OFF "$SWIFTSHADER_SRC"
ninja
echo $(date): SwiftShader build completed.

# Get and build Clvk
echo $(date): Starting Clvk build...
CLVK_SRC="$BUILD_ROOT/github/clvk"
CLVK_BUILD="$CLVK_SRC/build"
git clone https://github.com/kpet/clvk "$CLVK_SRC"
cd "$CLVK_SRC" && git submodule update --init
mkdir "$CLVK_BUILD" && cd "$CLVK_BUILD"
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE $ADDITIONAL_CMAKE_FLAGS $CMAKE_C_CXX_COMPILER \
  -DCLVK_CLSPV_ONLINE_COMPILER=ON -DCLSPV_SOURCE_DIR="$SRC" \
  -DCLVK_VULKAN_IMPLEMENTATION=custom -DVulkan_INCLUDE_DIRS=$CLVK_SRC/external/Vulkan-Headers/include -DVulkan_LIBRARIES="$VULKAN_LOADER_BUILD/loader/libvulkan.so" \
  "$CLVK_SRC"
ninja
echo $(date): Clvk build completed.

# Run Clvk tests
echo $(date): Starting Clvk smoke tests...
if [ $SKIP_TESTS = "False" ]
then
  export VK_ICD_FILENAMES="$SWIFTSHADER_BUILD/Linux/vk_swiftshader_icd.json"
  ./simple_test
fi
echo $(date): Clvk smoke tests completed.
