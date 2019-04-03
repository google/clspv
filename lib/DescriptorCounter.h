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

#ifndef CLSPV_LIB_DESCRIPTOR_COUNTER_H_
#define CLSPV_LIB_DESCRIPTOR_COUNTER_H_

#include "llvm/IR/Module.h"

namespace clspv {

// Returns the current descriptor index for the module.  The first one is 0.
int GetCurrentDescriptorIndex(llvm::Module *M);

// Get the current descriptor index and increment it internally
// so that we never get this one again.  The first one is 0.
int TakeDescriptorIndex(llvm::Module *M);

} // namespace clspv

#endif
