// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <iostream>
#include <libgen.h>
#include <list>
#include <string>
#include <unistd.h>

namespace {

int RunOpt(int argc, const char *argv[]) {
  const char **new_argv = new const char *[argc + 4];
  size_t i = 0;
  new_argv[i++] = LLVM_OPT;
  new_argv[i++] = "-load";
  new_argv[i++] = CLSPV_PASSES_SO;
  for (size_t j = 1; j < argc; j++) {
    new_argv[i++] = argv[j];
  }
  new_argv[i] = nullptr;

  std::cout << "Executing: ";
  for (auto i = 0; i < argc + 4; i++)
    std::cout << new_argv[i];
  std::cout << "\n";

  char *new_environ[] = {NULL};
  execve(new_argv[0], const_cast<char *const *>(new_argv), new_environ);
  perror("execve");
  return -1;
}

} // namespace

int main(int argc, const char *argv[]) { return RunOpt(argc, argv); }
