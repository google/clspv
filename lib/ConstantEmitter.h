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

#ifndef CLSPV_LIB_CONSTANT_EMITTER_H
#define CLSPV_LIB_CONSTANT_EMITTER_H

#include "llvm/IR/Constant.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/Support/raw_ostream.h"

namespace clspv {

// A Constant value emitter.  Emit the bytes of a constant as if it were
// laid out in memory, converted to hexadecimal.
class ConstantEmitter {
public:
  ConstantEmitter(const llvm::DataLayout &DL, llvm::raw_ostream &out)
      : Layout(DL), Out(out), Offset(0) {}

  void Emit(llvm::Constant *c);

private:
  // Emit |n| zeroes.
  void EmitZeroes(size_t n);
  // Emit just enough zeros to align to the given alignment.
  void AlignTo(size_t alignment);

  void EmitStruct(llvm::ConstantStruct *c);
  // ConstantDataSequential is an LLVM optimization for smallish numeric
  // arrays and vectors.
  void EmitDataSequential(llvm::ConstantDataSequential *c);
  // Aggregate covers both Array and (general) Vector
  void EmitAggregate(llvm::ConstantAggregate *c);
  void EmitAggregateZero(llvm::ConstantAggregateZero *c);
  void EmitInt(llvm::ConstantInt *c);
  void EmitFP(llvm::ConstantFP *c);

  // Emit bytes representing the first num_bits bits from the
  // array at |data|.
  void EmitRaw(unsigned num_bits, const uint64_t* data);

  // Emit a byte as a hex number to the output stream.
  void EmitByte(size_t byte);

  const llvm::DataLayout &Layout;
  // The output stream.
  llvm::raw_ostream &Out;
  // Offset into the memory layout in memory.
  size_t Offset;
};

} // namespace clspv

#endif
