// Copyright 2019 The Clspv Authors. All rights reserved.
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

#include "llvm/Passes/PassBuilder.h"

#include "Passes.h"

namespace clspv {

void RegisterClspvPassBuilderCallback(llvm::PassBuilder *PB) {
  PB->registerPipelineParsingCallback(
      [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
         llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
#define MODULE_PASS(NAME, CREATE_PASS)                                         \
  if (NAME == Name) {                                                          \
    MPM.addPass(CREATE_PASS());                                                \
    return true;                                                               \
  }
#define FUNCTION_PASS(NAME, CREATE_PASS)                                       \
  if (NAME == Name) {                                                          \
    MPM.addPass(llvm::createModuleToFunctionPassAdaptor(CREATE_PASS()));       \
    return true;                                                               \
  }
#include "PassRegistry.def"
#undef FUNCTION_PASS
#undef MODULE_PASS
        return false;
      });
}

void RegisterClspvPasses(llvm::PassInstrumentationCallbacks *PIC) {
#define MODULE_PASS(NAME, CREATE_PASS)                                         \
  PIC->addClassToPassName(CREATE_PASS::name(), NAME);
#define FUNCTION_PASS(NAME, CREATE_PASS)                                       \
  PIC->addClassToPassName(CREATE_PASS::name(), NAME);
#include "PassRegistry.def"
#undef FUNCTION_PASS
#undef MODULE_PASS
}

} // namespace clspv
