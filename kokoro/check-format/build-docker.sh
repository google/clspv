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

# This script should be run from the project root directory.

# Fail on any error.
set -e

# Verify this script is run from the root directory.
[ -d .git ]
[ -f docs/OpenCLCOnVulkan.md ]

# This is required to run any git command in the docker since owner will
# have changed between the clone environment, and the docker container.
# Marking the root of the repo as safe for ownership changes.
git config --global --add safe.directory $(pwd)

# The docker image should have set these
[ -f "$CLANG_FORMAT" ]
[ -f "$CLANG_FORMAT_DIFF" ]

echo $(date): Check formatting...
# $1 should be FULL for continuous build, so formatting is checked against the
# parent of HEAD.
# Otherwise, compare formatting against 'main'
./utils/check_code_format.sh $1
echo $(date): check completed.
