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

#include "ConstantEmitter.h"

#include <cassert>

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APInt.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace clspv {

void ConstantEmitter::Emit(Constant *c) {
  AlignTo(Layout.getABITypeAlignment(c->getType()));
  if (auto i = dyn_cast<ConstantInt>(c)) {
    EmitInt(i);
  } else if (auto f = dyn_cast<ConstantFP>(c)) {
    EmitFP(f);
  } else if (auto st = dyn_cast<ConstantStruct>(c)) {
    EmitStruct(st);
  } else if (auto ag = dyn_cast<ConstantArray>(c)) {
    EmitAggregate(ag);
  } else if (auto ag = dyn_cast<ConstantVector>(c)) {
    EmitAggregate(ag);
  } else if (auto cds = dyn_cast<ConstantDataSequential>(c)) {
    EmitDataSequential(cds);
  } else if (auto ag = dyn_cast<ConstantAggregate>(c)) {
    EmitAggregate(ag);
  } else if (auto ag = dyn_cast<ConstantAggregateZero>(c)) {
    EmitAggregateZero(ag);
  } else {
    errs() << "Don't know how to emit " << *c << " with value id "
           << int(c->getValueID()) << " compared to "
           << int(Value::ConstantVectorVal) << "\n";
    llvm_unreachable("Unhandled constant");
  }
}

void ConstantEmitter::EmitZeroes(size_t n) {
  for (size_t i = 0; i < n; ++i) {
    Out << "00";
    ++Offset;
  }
}

void ConstantEmitter::AlignTo(size_t alignment) {
  size_t overflow = Offset % alignment;
  if (overflow) {
    const size_t padding = alignment - overflow;
    EmitZeroes(padding);
  }
  assert(0 == (Offset % alignment));
}

void ConstantEmitter::EmitStruct(ConstantStruct *c) {
  const StructLayout *sl = Layout.getStructLayout(c->getType());
  AlignTo(sl->getAlignment().value()); // Might be redundant.
  const size_t BaseOffset = Offset;
  for (unsigned i = 0; i < c->getNumOperands(); ++i) {
    EmitZeroes(sl->getElementOffset(i) - (Offset - BaseOffset));
    Emit(c->getOperand(i));
  }
  EmitZeroes(sl->getSizeInBytes() - (Offset - BaseOffset));
}

void ConstantEmitter::EmitDataSequential(ConstantDataSequential *c) {
  for (unsigned i = 0; i < c->getNumElements(); ++i) {
    // The elements will align themselves.
    Constant *elem = c->getElementAsConstant(i);
    Emit(elem);
  }
}

void ConstantEmitter::EmitAggregate(ConstantAggregate *c) {
  for (unsigned i = 0; i < c->getNumOperands(); ++i) {
    // The elements will align themselves.
    Emit(c->getOperand(i));
  }
}

void ConstantEmitter::EmitAggregateZero(ConstantAggregateZero *c) {
  if (StructType *sty = dyn_cast<StructType>(c->getType())) {

    const StructLayout *sl = Layout.getStructLayout(sty);
    AlignTo(sl->getAlignment().value()); // Might be redundant.
    const size_t BaseOffset = Offset;
    for (unsigned i = 0; i < c->getNumElements(); ++i) {
      EmitZeroes(sl->getElementOffset(i) - (Offset - BaseOffset));
      Emit(c->getElementValue(i));
    }
    EmitZeroes(sl->getSizeInBytes() - (Offset - BaseOffset));

  } else {
    for (unsigned i = 0; i < c->getNumElements(); ++i) {
      // The elements will align themselves.
      Emit(c->getElementValue(i));
    }
  }
}

void ConstantEmitter::EmitInt(ConstantInt *c) {
  EmitRaw(c->getBitWidth(), c->getValue().getRawData());
}

void ConstantEmitter::EmitFP(ConstantFP *c) {
  APInt asInt = c->getValueAPF().bitcastToAPInt();
  EmitRaw(asInt.getBitWidth(), asInt.getRawData());
}

void ConstantEmitter::EmitRaw(unsigned num_bits, const uint64_t *data) {
  unsigned num_bytes = (num_bits + 7) / 8;
  while (num_bytes) {
    uint64_t word = *data++;
    for (int i = 0; i < 8 && num_bytes; --num_bytes, ++i) {
      EmitByte(word & 0xff);
      word = (word >> 8);
    }
  }
}

void ConstantEmitter::EmitByte(size_t byte) {
  static const char hex[] = "0123456789abcdef";
  Out << hex[(byte & 0xf0) >> 4] << hex[byte & 0xf];
  ++Offset;
}

} // namespace clspv
