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

// Returns true if the function is an OpenCL image builtin.
bool IsImageBuiltin(llvm::StringRef name);
inline bool IsImageBuiltin(llvm::Function *f) {
  return IsImageBuiltin(f->getName());
}

// Returns true if the function is an OpenCL sampled image read.
bool IsSampledImageRead(llvm::StringRef name);
inline bool IsSampledImageRead(llvm::Function *f) {
  return IsSampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL sampled image read of float type.
bool IsFloatSampledImageRead(llvm::StringRef name);
inline bool IsFloatSampledImageRead(llvm::Function *f) {
  return IsFloatSampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL sampled image read of uint type.
bool IsUintSampledImageRead(llvm::StringRef name);
inline bool IsUintSampledImageRead(llvm::Function *f) {
  return IsUintSampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL sampled image read of int type.
bool IsIntSampledImageRead(llvm::StringRef name);
inline bool IsIntSampledImageRead(llvm::Function *f) {
  return IsIntSampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL image read.
bool IsUnsampledImageRead(llvm::StringRef name);
inline bool IsUnsampledImageRead(llvm::Function* f) {
  return IsUnsampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL image read of float type.
bool IsFloatUnsampledImageRead(llvm::StringRef name);
inline bool IsFloatUnsampledImageRead(llvm::Function* f) {
  return IsFloatUnsampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL image read of uint type.
bool IsUintUnsampledImageRead(llvm::StringRef name);
inline bool IsUintUnsampledImageRead(llvm::Function* f) {
  return IsUintUnsampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL image read of int type.
bool IsIntUnsampledImageRead(llvm::StringRef name);
inline bool IsIntUnsampledImageRead(llvm::Function* f) {
  return IsIntUnsampledImageRead(f->getName());
}

// Returns true if the function is an OpenCL image write.
bool IsImageWrite(llvm::StringRef name);
inline bool IsImageWrite(llvm::Function *f) {
  return IsImageWrite(f->getName());
}

// Returns true if the function is an OpenCL image write of float type.
bool IsFloatImageWrite(llvm::StringRef name);
inline bool IsFloatImageWrite(llvm::Function *f) {
  return IsFloatImageWrite(f->getName());
}

// Returns true if the function is an OpenCL image write of uint type.
bool IsUintImageWrite(llvm::StringRef name);
inline bool IsUintImageWrite(llvm::Function *f) {
  return IsUintImageWrite(f->getName());
}

// Returns true if the function is an OpenCL image write of int type.
bool IsIntImageWrite(llvm::StringRef name);
inline bool IsIntImageWrite(llvm::Function *f) {
  return IsIntImageWrite(f->getName());
}

// Returns true if the function is an OpenCL image height query.
bool IsGetImageHeight(llvm::StringRef name);
inline bool IsGetImageHeight(llvm::Function *f) {
  return IsGetImageHeight(f->getName());
}

// Returns true if the function is an OpenCL image width query.
bool IsGetImageWidth(llvm::StringRef name);
inline bool IsGetImageWidth(llvm::Function *f) {
  return IsGetImageWidth(f->getName());
}

// Returns true if the function is an OpenCL image depth query.
bool IsGetImageDepth(llvm::StringRef name);
inline bool IsGetImageDepth(llvm::Function *f) {
  return IsGetImageDepth(f->getName());
}

// Returns true if the function is an OpenCL image dim query.
bool IsGetImageDim(llvm::StringRef name);
inline bool IsGetImageDim(llvm::Function *f) {
  return IsGetImageDim(f->getName());
}

// Returns true if the function is an OpenCL image query.
bool IsImageQuery(llvm::StringRef name);
inline bool IsImageQuery(llvm::Function *f) {
  return IsImageQuery(f->getName());
}

} // namespace clspv

#endif // CLSPV_LIB_BUILTINS_H_
