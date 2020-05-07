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

. /bin/using.sh # Declare the bash 'using' function

BUILD_ROOT=$PWD
SRC=$PWD/github/clspv

using clang-8.0.0

cd $SRC
cp /bin/clang-8.0.0/clang-format-diff.py utils/clang-format-diff.py

echo $(date): Check formatting...
./utils/check_code_format.sh $1
echo $(date): check completed.
