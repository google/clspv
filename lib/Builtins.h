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

#ifndef CLSPV_LIB_BUILTINS_H_
#define CLSPV_LIB_BUILTINS_H_

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

namespace clspv {

bool IsImageBuiltin(llvm::StringRef name);
inline bool IsImageBuiltin(llvm::Function *f) {
  return IsImageBuiltin(f->getName());
}

bool IsSampledImageRead(llvm::StringRef name);
inline bool IsSampledImageRead(llvm::Function *f) {
  return IsSampledImageRead(f->getName());
}

bool IsFloatSampledImageRead(llvm::StringRef name);
inline bool IsFloatSampledImageRead(llvm::Function *f) {
  return IsFloatSampledImageRead(f->getName());
}

bool IsUintSampledImageRead(llvm::StringRef name);
inline bool IsUintSampledImageRead(llvm::Function *f) {
  return IsUintSampledImageRead(f->getName());
}

bool IsIntSampledImageRead(llvm::StringRef name);
inline bool IsIntSampledImageRead(llvm::Function *f) {
  return IsIntSampledImageRead(f->getName());
}

bool IsImageWrite(llvm::StringRef name);
inline bool IsImageWrite(llvm::Function *f) {
  return IsImageWrite(f->getName());
}

bool IsFloatImageWrite(llvm::StringRef name);
inline bool IsFloatImageWrite(llvm::Function *f) {
  return IsFloatImageWrite(f->getName());
}

bool IsUintImageWrite(llvm::StringRef name);
inline bool IsUintImageWrite(llvm::Function *f) {
  return IsUintImageWrite(f->getName());
}

bool IsIntImageWrite(llvm::StringRef name);
inline bool IsIntImageWrite(llvm::Function *f) {
  return IsIntImageWrite(f->getName());
}

bool IsGetImageHeight(llvm::StringRef name);
inline bool IsGetImageHeight(llvm::Function *f) {
  return IsGetImageHeight(f->getName());
}

bool IsGetImageWidth(llvm::StringRef name);
inline bool IsGetImageWidth(llvm::Function *f) {
  return IsGetImageWidth(f->getName());
}

} // namespace clspv

#endif // CLSPV_LIB_BUILTINS_H_
