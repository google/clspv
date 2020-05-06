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

# Get clang-format-8.0.0.
# Once kokoro upgrades the Ubuntu VMs, we can use 'apt-get install clang-format'
curl -L http://releases.llvm.org/8.0.0/clang+llvm-8.0.0-linux-x86_64-ubuntu14.04.tar.xz -o clang-llvm.tar.xz
tar xf clang-llvm.tar.xz
export PATH=$PWD/clang+llvm-8.0.0-linux-x86_64-ubuntu14.04/bin:$PATH

cd $SRC
curl -L http://llvm.org/svn/llvm-project/cfe/trunk/tools/clang-format/clang-format-diff.py -o utils/clang-format-diff.py;

echo $(date): Check formatting...
./utils/check_code_format.sh $1
echo $(date): check completed.
