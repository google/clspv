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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"

namespace clspv {

// Return the functions reachable from entry point functions, where
// callers appear before callees.  OpenCL C does not permit recursion
// or function or pointers, so this is always well defined.  The ordering
// should be reproducible from one run to the next.
llvm::UniqueVector<llvm::Function *> CallGraphOrderedFunctions(llvm::Module &M);

} // namespace clspv
