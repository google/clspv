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

ROOT_DIR=`pwd`
SCRIPT_DIR=`dirname "$BASH_SOURCE"`

docker run --rm -i \
  --volume "${ROOT_DIR}:${ROOT_DIR}" \
  --volume "${KOKORO_ARTIFACTS_DIR}:/mnt/artifacts" \
  --workdir "${ROOT_DIR}" \
  --env BUILD_TOOLCHAIN="clang" \
  --env BUILD_TYPE="Debug" \
  --entrypoint "${ROOT_DIR}/${SCRIPT_DIR}/../scripts/linux/build.sh" \
  us-east4-docker.pkg.dev/shaderc-build/radial-docker/ubuntu-24.04-amd64/cpp-builder


# chown the given directory to the current user, if it exists.
# Docker creates files with the root user - this can upset the Kokoro artifact copier.
function chown_dir() {
  dir=$1
  if [[ -d "$dir" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$dir"
  fi
}

chown_dir "${ROOT_DIR}/github/clspv/build"
chown_dir "${ROOT_DIR}/github/clspv/third_party"
