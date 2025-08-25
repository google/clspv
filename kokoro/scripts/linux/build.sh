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

cd $SRC
python3 utils/fetch_sources.py --ci

mkdir build && cd $SRC/build

if [ "$BUILD_TOOLCHAIN" == "clang" ]; then
  using clang-13.0.1
fi

echo $(date): Starting build...
cmake -GNinja -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..

echo $(date): Build everything...
ninja
echo $(date): Build completed.

echo $(date): Starting unit tests...
ninja check-spirv
ninja check-spirv-64
echo $(date): Unit tests completed.
