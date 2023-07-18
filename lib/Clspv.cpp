// Copyright 2023 The Clspv Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <cstdint>
#include <iosfwd>
#include <iostream>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

#include "clspv/Clspv.h"
#include "clspv/Compiler.h"

// Global API Mutex
static std::mutex g_clspvMutex;

struct ClspvContainerImpl {
  std::vector<uint32_t> binary;
  std::string buildLog;
  std::mutex containerMutex;
};

ClspvContainer clspvCreateContainer(void) {
  ClspvContainer container = new (std::nothrow) ClspvContainerImpl;
  if (!container) {
    return nullptr;
  }
  return container;
}

void clspvDestroyContainer(ClspvContainer container) {
  std::scoped_lock<std::mutex> sl(g_clspvMutex);
  if (container == nullptr) {
    return;
  }
  delete container;
  container = nullptr;
}

ClspvError clspvCompileFromSourcesString(
    ClspvContainer container, const size_t program_count,
    const size_t *program_sizes, const char **programs, const char *options,
    char **output_binary, size_t *output_binary_size, const char **output_log) {
  if (container == nullptr) {
    return CLSPV_INVALID_CONTAINER;
  }
  if (programs == nullptr || program_count == 0 || output_binary == nullptr ||
      output_binary_size == nullptr) {
    return CLSPV_INVALID_ARG;
  }

  int err = CLSPV_SUCCESS;
  std::string sOptions(options ? options : "");
  std::vector<std::string> vPrograms(program_count);
  for (size_t i = 0; i < program_count; ++i) {
    if (programs[i] == nullptr) {
      return CLSPV_ERROR;
    }
    if (program_sizes && program_sizes[i] != 0) {
      vPrograms[i].assign(programs[i], program_sizes[i]);
    } else {
      vPrograms[i].assign(programs[i]);
    }
  }

  {
    std::scoped_lock<std::mutex> sl(container->containerMutex);

    if (!container->buildLog.empty()) {
      container->buildLog.clear();
    }
    if (!container->binary.empty()) {
      container->binary.clear();
    }

    err = clspv::CompileFromSourcesString(
        vPrograms, sOptions, &container->binary, &container->buildLog);
    if (output_log != nullptr) {
      *output_log = container->buildLog.c_str();
    }

    if (err != 0) {
      return CLSPV_ERROR;
    }

    // Return binary as a char*
    *output_binary = reinterpret_cast<char *>(container->binary.data());
    *output_binary_size = container->binary.size() * sizeof(uint32_t);
  }

  return CLSPV_SUCCESS;
}
