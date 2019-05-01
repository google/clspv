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

#include "llvm/IR/GlobalVariable.h"

namespace clspv {

// Normalize global variables to remove constant expression bitcasts of the
// entire variable. Only considers constant address space variables. Introduces
// a new global variable for each case of type casting to remove the cast.
// Rewrites variable intializers.
void NormalizeGlobalVariables(llvm::Module &M);

}
