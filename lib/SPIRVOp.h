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

#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ModRef.h"

#include "spirv/unified1/spirv.hpp"

namespace clspv {

using namespace llvm;

// Insert a call to a specific SPIR-V instruction after Insert
//
// A function with a name guaranteed to be unique for each combination of types
// in Args will be used to represent the SPIR-V instruction until the
// SPIRVProducerPass.
//
// The attributes passed via Attributes must all be function attributes.
// They will be set on the function representing the SPIR-V instruction.
//
// Since this function may modify the symbol table of the module containing
// Insert, it shouldn't be used while iterating over the symbols of that module
// unless the caller knows that no new function will be created.
//
// If using this function to insert an instruction that has pointer operands
// ensure that InferType also handles type inference for that instruction (see
// lib/Types.cpp).
Instruction *
InsertSPIRVOp(Instruction *Insert, spv::Op Opcode,
              ArrayRef<Attribute::AttrKind> Attributes, Type *RetType,
              ArrayRef<Value *> Args,
              const MemoryEffects &MemEffects = MemoryEffects::unknown());

} // namespace clspv
