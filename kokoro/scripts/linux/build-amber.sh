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
AMBER_SRC=$PWD/github/amber

cd $SRC
python3 utils/fetch_sources.py

cd $BUILD_ROOT/github
git clone https://github.com/google/amber.git amber
cd $BUILD_ROOT/github/amber
python3 tools/git-sync-deps --with-swiftshader

mkdir build && cd $BUILD_ROOT/github/amber/build

if [ "$BUILD_TOOLCHAIN" == "clang" ]; then
  using clang-13.0.1
fi

# Invoke the build.
BUILD_SHA=${KOKORO_GITHUB_COMMIT:-$KOKORO_GITHUB_PULL_REQUEST_COMMIT}
echo $(date): Starting build...
cmake -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DAMBER_ENABLE_SWIFTSHADER=TRUE -DAMBER_USE_CLSPV=TRUE \
  -DBUILD_WSI_XCB_SUPPORT=OFF \
  -DAMBER_CLSPV_DIR=$SRC -DAMBER_CLSPV_LLVM_DIR=$SRC/third_party/llvm \
   ..

echo $(date): Build everything...
ninja
echo $(date): Build completed.

echo $(date): Starting amber tests...
python3 $SRC/amber/run_tests.py \
  --amber $BUILD_ROOT/github/amber/build/amber \
  --dir $SRC/amber \
  --swiftshader \
  --vk-icd $BUILD_ROOT/github/amber/build/Linux/vk_swiftshader_icd.json
echo $(date): Unit tests completed.
