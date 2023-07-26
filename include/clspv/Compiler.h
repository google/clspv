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

#endif // CLSPV_INCLUDE_CLSPV_COMPILER_H_
