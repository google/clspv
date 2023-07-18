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

#ifndef CLSPV_API_CLSPV_H_
#define CLSPV_API_CLSPV_H_

#include <stddef.h>
#include <stdint.h>

typedef enum ClspvError {
  CLSPV_SUCCESS = 0,
  CLSPV_INVALID_CONTAINER,
  CLSPV_INVALID_ARG,
  CLSPV_ERROR
} ClspvError;

typedef struct ClspvContainerImpl *ClspvContainer;

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Create Clspv container.
//
// |container| - Opaque handle to created Clspv container.
//               Returns NULL on failure.
EXPORT ClspvContainer clspvCreateContainer(void);

// Destroy Clspv container.
//
// |container| - Opaque handle to created Clspv container.
EXPORT void clspvDestroyContainer(ClspvContainer container);

// Compile from source string(s).
//
// |container|          - Handle to container object.
// |program_count|      - Number of programs passed in "programs" list.
// |program_sizes|      - Length of each program in bytes,
//                        will assume program is null-terminated if size is 0
//                        or all programs are null-terminated if param is NULL.
// |programs|           - List of program objects (OpenCL C or LLVM IR sources).
// |options|            - String of options to pass to Clspv compiler.
// |output_binary|      - Handle to compiler output/result.
// |output_binary_size| - Size of compiler output/result (in bytes).
// |output_log|         - Handle to compiler build log.
EXPORT ClspvError clspvCompileFromSourcesString(
    ClspvContainer container, const size_t program_count,
    const size_t *program_sizes, const char **programs, const char *options,
    char **output_binary, size_t *output_binary_size, const char **output_log);

#ifdef __cplusplus
}
#endif

#endif // CLSPV_API_CLSPV_H_
