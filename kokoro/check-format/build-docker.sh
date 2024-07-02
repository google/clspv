#!/bin/bash
# Copyright 2020 The Clspv Authors. All rights reserved.
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

. /bin/using.sh # Declare the bash 'using' function

# Display commands being run.
set -x

BUILD_ROOT=$PWD
SRC=$PWD/github/clspv

# This is required to run any git command in the docker since owner will
# have changed between the clone environment, and the docker container.
# Marking the root of the repo as safe for ownership changes.
git config --global --add safe.directory $SRC

using python-3.12
using clang-8.0.0
which clang-format

cd $SRC
python3 utils/fetch_sources.py
cp third_party/llvm/clang/tools/clang-format/clang-format-diff.py utils/clang-format-diff.py

echo $(date): Check formatting...
./utils/check_code_format.sh
echo $(date): check completed.
