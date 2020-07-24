// Copyright 2020 The Clspv Authors. All rights reserved.
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

#include <fstream>
#include <iostream>
#include <string>

#include "spirv-tools/libspirv.hpp"

#include "ReflectionParser.h"

void PrintUsage() {
  const std::string help = R"(Usage: clspv-reflection [--target-env <env>] [-o <outfile>] <infile>

Options:
--target-env <env>  Specify the SPIR-V environment. Must be one of:
                    spv1.0, spv1.3, spv1.5, vulkan1.0 or vulkan1.1.
                    Default is spv1.0.
-o <outfile>        Specify the output filename.
                    If not output file is specified, output goes to
                    stdout.
)";

  std::cout << help;
}

int main(const int argc, const char *const argv[]) {
  std::string filename;
  std::string outfile;
  spv_target_env env(SPV_ENV_UNIVERSAL_1_0);
  for (int i = 1; i < argc; ++i) {
    const std::string option(argv[i]);
    if (option == "-h" || option == "--help") {
      PrintUsage();
      return 0;
    } else if (option == "--target-env") {
      ++i;
      if (!spvParseTargetEnv(argv[i], &env)) {
        std::cerr << "Error: invalid target env: " << argv[i] << "\n";
        return -1;
      }
      switch (env) {
        case SPV_ENV_UNIVERSAL_1_0:
        case SPV_ENV_UNIVERSAL_1_3:
        case SPV_ENV_UNIVERSAL_1_5:
        case SPV_ENV_VULKAN_1_0:
        case SPV_ENV_VULKAN_1_1:
          break;
        default:
          std::cerr << "Error: invalid target env: " << argv[i] << "\n";
          return -1;
      }
    } else if (option == "-o") {
      ++i;
      outfile = std::string(argv[i]);
    } else { 
      if (!filename.empty()) {
        std::cerr << "Error: too many positional arguments specified\n";
        return -1;
      }
      filename = std::string(argv[i]);
    }
  }

  if (filename.empty()) {
    std::cerr << "Error: no binary file specified\n";
    return -1;
  }

  std::ifstream str(filename.c_str(), std::ifstream::in |
                                          std::ifstream::binary |
                                          std::ifstream::ate);
  if (!str) {
    std::cerr << "Error: failed to open '" << filename << "'\n";
    return -1;
  }
  std::streampos size = str.tellg();
  std::vector<uint32_t> binary(size / 4, 0);
  str.seekg(std::ios::beg);
  str.read(reinterpret_cast<char*>(binary.data()), size);
  str.close();

  spvtools::SpirvTools tools(env);
  if (!tools.Validate(binary)) {
    std::cerr << "Error: invalid binary\n";
    return -1;
  }

  std::ostream* ostr = &std::cout;
  if (!outfile.empty()) {
    ostr = new std::ofstream(outfile.c_str());
  }
  bool ok = clspv::ParseReflection(binary, env, ostr);
  if (!outfile.empty()) {
    auto fstr = reinterpret_cast<std::ofstream*>(ostr);
    fstr->close();
    delete fstr;
  }
  if (!ok) {
    std::cerr << "Error: failed to parse reflection info\n";
    return -1;
  }

  return 0;
}

