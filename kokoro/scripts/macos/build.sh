#!/bin/bash
# Copyright 2018 The Clspv Authors. All rights reserved.
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
BUILD_TYPE=$1

SKIP_TESTS="False"

# Get NINJA.
wget -q https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-mac.zip
unzip -q ninja-mac.zip
chmod +x ninja
export PATH="$PWD:$PATH"

# Get Cmake (required for Kokoro Apple Silicon images)
CMAKE_VER=3.30.2
wget -q https://github.com/Kitware/CMake/releases/download/v$CMAKE_VER/cmake-$CMAKE_VER-macos-universal.tar.gz
tar xf cmake-$CMAKE_VER-macos-universal.tar.gz
chmod +x cmake-$CMAKE_VER-macos-universal/CMake.app/Contents/bin/*
export PATH="$PWD/cmake-$CMAKE_VER-macos-universal/CMake.app/Contents/bin:$PATH"


# Get dependencies.
cd $SRC
python utils/fetch_sources.py

mkdir build && cd $SRC/build

# Invoke the build.
BUILD_SHA=${KOKORO_GITHUB_COMMIT:-$KOKORO_GITHUB_PULL_REQUEST_COMMIT}
echo $(date): Starting build...
# Kokoro MacOS is not finding libxml2 propoerly, so disable that support.
cmake -GNinja -DLLVM_ENABLE_LIBXML2=0 -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang ..

echo $(date): Build everything...
ninja
echo $(date): Build completed.

echo $(date): Starting unit tests...
if [ $SKIP_TESTS = "False" ]
then
  ninja check-spirv
  ninja check-spirv-64
fi
echo $(date): Unit tests completed.

