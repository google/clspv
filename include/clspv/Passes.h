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

#include <string>
#include <utility>
#include <vector>

namespace llvm {
// This is against Google C++ style guide.
class PassBuilder;
class PassInstrumentationCallbacks;
} // namespace llvm

namespace clspv {

// Registers call back for pass builder to tie into pass pipeline parsing.
void RegisterClspvPassBuilderCallback(llvm::PassBuilder *PB);

// Registers the class to pass name mapping.
void RegisterClspvPasses(llvm::PassInstrumentationCallbacks *PIC);

} // namespace clspv
