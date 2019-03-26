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

#include <libgen.h>
#include <list>
#include <stdio.h>
#include <string>
#include <unistd.h>

#include "llvm/Support/CommandLine.h"

namespace {

static llvm::cl::opt<int> clo_verbose(
    "clo-verbose", llvm::cl::init(0),
    llvm::cl::desc("Verbosity level.  Higher values increase verbosity."));

static llvm::cl::opt<std::string>
    clo_opt("clo-opt", llvm::cl::init(LLVM_OPT),
            llvm::cl::desc("Path to LLVM's 'opt' tool."));

static llvm::cl::opt<std::string>
    clo_passes("clo-passes", llvm::cl::init(CLSPV_PASSES_SO),
               llvm::cl::desc("Path to libclspv_passes.so."));

int RunOpt(int argc, const char *argv[]) {
  size_t new_argc =
      argc + 1 /* "-load" */ + 1 /* clo_passes */ + 1 /* nullptr */;
  const char **new_argv = new const char *[new_argc];
  size_t i = 0;
  new_argv[i++] = clo_opt.c_str();
  new_argv[i++] = "-load";
  new_argv[i++] = clo_passes.c_str();
  for (size_t j = 1; j < argc; j++) {
    new_argv[i++] = argv[j];
  }
  new_argv[i] = nullptr;

  if (clo_verbose > 0) {
    fprintf(stderr, "Executing: ");
    for (auto i = 0; i < new_argc - 1; i++) {
      fprintf(stderr, "%s ", new_argv[i]);
    }
    fprintf(stderr, "\n");
  }

  char *new_environ[] = {NULL};
  execve(new_argv[0], const_cast<char *const *>(new_argv), new_environ);
  perror("execve");
  return -1;
}

const char **ConvertToCArray(std::vector<const char *> args) {
  const char **argv = new const char *[args.size()];
  size_t i = 0;
  for (const auto &arg : args)
    argv[i++] = arg;
  return argv;
}

} // namespace

int main(int argc, const char *argv[]) {
  // Make sure that we only parse the command-line options registered for this
  // app.  Any argument not recognized is passed as-is to 'opt'.
  llvm::StringMap<llvm::cl::Option *> &options =
      llvm::cl::getRegisteredOptions();

  std::vector<const char *> args_to_keep;
  args_to_keep.push_back(argv[0]);

  std::vector<const char *> args_to_pass;
  args_to_pass.push_back(argv[0]);

  for (int i = 1; i < argc; ++i) {
    std::string arg(argv[i]);
    bool should_keep_arg = false;
    for (const auto &option : options) {
      // If this argument is something that we recognize, keep it.
      if (arg.find(option.getKey().str()) != std::string::npos) {
        should_keep_arg = true;
        break;
      }
    }

    if (should_keep_arg) {
      args_to_keep.push_back(argv[i]);
    } else {
      args_to_pass.push_back(argv[i]);
    }
  }

  llvm::cl::ParseCommandLineOptions(
      args_to_keep.size(), ConvertToCArray(args_to_keep),
      "Clspv wrapper tool for LLVM opt.\n\nThis tool loads the clspv passes "
      "library into opt and calls it with the given options.\nAny argument not "
      "recognized by this tool is passed directly to opt.\n");

  return RunOpt(args_to_pass.size(), ConvertToCArray(args_to_pass));
}
