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
AMBER_SRC=$PWD/github/amber
CONFIG=$1
COMPILER=$2

BUILD_TYPE="Debug"

CMAKE_C_CXX_COMPILER=""
if [ $COMPILER = "clang" ]; then
  # Use newer clang than default.
  CMAKE_C_CXX_COMPILER="-DCMAKE_C_COMPILER=/usr/bin/clang-5.0 -DCMAKE_CXX_COMPILER=/usr/bin/clang++-5.0"
else
  # Use newer gcc than default.
  CMAKE_C_CXX_COMPILER="-DCMAKE_C_COMPILER=/usr/bin/gcc-5 -DCMAKE_CXX_COMPILER=/usr/bin/g++-5"
fi

# Possible configurations are:
# ASAN, COVERAGE, RELEASE, DEBUG, DEBUG_EXCEPTION, RELEASE_MINGW

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

# Get dependencies.
cd $SRC
/usr/bin/python3 utils/fetch_sources.py

cd $BUILD_ROOT/github
git clone https://github.com/google/amber.git amber
cd $BUILD_ROOT/github/amber
/usr/bin/python3 tools/git-sync-deps

mkdir build && cd $BUILD_ROOT/github/amber/build

# Invoke the build.
BUILD_SHA=${KOKORO_GITHUB_COMMIT:-$KOKORO_GITHUB_PULL_REQUEST_COMMIT}
echo $(date): Starting build...
cmake -DPYTHON_EXECUTABLE:FILEPATH=/usr/bin/python3 -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DAMBER_ENABLE_SWIFTSHADER=TRUE -DAMBER_USE_CLSPV=TRUE \
  -DAMBER_CLSPV_DIR=$SRC -DAMBER_CLSPV_LLVM_DIR=$SRC/third_party/llvm \
  $ADDITIONAL_CMAKE_FLAGS $CMAKE_C_CXX_COMPILER ..

echo $(date): Build everything...
ninja
echo $(date): Build completed.

echo $(date): Starting amber tests...
export VK_ICD_FILENAMES=$BUILD_ROOT/github/amber/build/Linux/vk_swiftshader_icd.json
/usr/bin/python3 $SRC/amber/run_tests.py \
  --amber $BUILD_ROOT/github/amber/build/amber \
  --dir $SRC/amber \
  --swiftshader
echo $(date): Unit tests completed.

