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

# Translate a path under KOKORO_ROOT_DIR to the corresponding host VM path under
# KOKORO_HOST_ROOT_DIR when running Docker sibling containers on Kokoro Instances.
function to_host_path() {
  local path="$1"
  if [ -n "${KOKORO_HOST_ROOT_DIR:-}" ] && [ -n "${KOKORO_ROOT_DIR:-}" ]; then
    local container_root="${KOKORO_ROOT_DIR%/}"
    local host_root="${KOKORO_HOST_ROOT_DIR%/}"
    if [ "${path}" = "${container_root}" ]; then
      echo "${host_root}"
    elif [[ "${path}" == "${container_root}/"* ]]; then
      echo "${host_root}${path#${container_root}}"
    else
      echo "${path}"
    fi
  else
    echo "${path}"
  fi
}

docker run --rm -i \
  --volume "$(to_host_path "${ROOT_DIR}"):${ROOT_DIR}" \
  --volume "$(to_host_path "${KOKORO_ARTIFACTS_DIR}"):/mnt/artifacts" \
  --workdir "${ROOT_DIR}" \
  --env BUILD_TOOLCHAIN="gcc" \
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
