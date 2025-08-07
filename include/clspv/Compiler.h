// Copyright 2018 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_INCLUDE_CLSPV_COMPILER_H_
#define CLSPV_INCLUDE_CLSPV_COMPILER_H_

#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

namespace clspv {
// DEPRECATED: This function will be replaced by an expanded API.
int Compile(const int argc, const char *const argv[]);

// Compile from a source string.
//
// For use with clBuildProgram. The input program is passed as |program|.
// Command line options to clspv are passed as |options|. |output_binary| must
// be non-null.
int CompileFromSourceString(const std::string &program,
                            const std::string & /*removed*/,
                            const std::string &options,
                            std::vector<uint32_t> *output_binary,
                            std::string *output_log = nullptr);

// Compile from multiple source strings.
//
// For use in clLinkProgram.
// Command line options to clspv are passed as |options|.
int CompileFromSourcesString(const std::vector<std::string> &programs,
                             const std::string &options,
                             std::vector<uint32_t> *output_buffer,
                             std::string *output_log);
} // namespace clspv

// C API
typedef enum ClspvError {
  CLSPV_SUCCESS = 0,
  CLSPV_OUT_OF_HOST_MEM,
  CLSPV_INVALID_ARG,
  CLSPV_ERROR
} ClspvError;

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

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
    const size_t program_count, const size_t *program_sizes,
    const char **programs, const char *options, char **output_binary,
    size_t *output_binary_size, char **output_log);

// Frees the output memory from clspvCompileFromSourcesString
//
// |output_binary|      - Handle to spv
// |output_log|         - Handle to compiler build log
static inline void clspvFreeOutputBuildObjs(char *output_binary,
                                            char *output_log) {
  free(output_binary);
  output_binary = NULL;
  free(output_log);
  output_log = NULL;
}

#ifdef __cplusplus
}
#endif

#endif // CLSPV_INCLUDE_CLSPV_COMPILER_H_
