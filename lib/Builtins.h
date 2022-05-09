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

#include <string>

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

#include "BuiltinsEnum.h"

#define BUILTIN_IN_GROUP(BUILTIN, GROUP)                                       \
  (BUILTIN > Builtins::kType_##GROUP##_Start &&                                \
   BUILTIN < Builtins::kType_##GROUP##_End)

namespace clspv {

namespace Builtins {

struct ParamTypeInfo {
  bool is_signed = false;                            // is element type signed
  llvm::Type::TypeID type_id = llvm::Type::VoidTyID; // element type
  uint32_t byte_len = 0;                             // element byte length
  int vector_size = 0; // number of elements (0 == not a vector)
  std::string name;    // struct name

  bool isSampler() const;

  // Returns the LLVM type conveyed by mangling.
  // Currently only supports gentypes from the OpenCL C spec.
  llvm::Type *DataType(llvm::LLVMContext &context) const;
};

class FunctionInfo {
  bool is_valid_ = false;
  Builtins::BuiltinType type_ = Builtins::kBuiltinNone;
  std::string name_;
  ParamTypeInfo return_type_; // only used for convert, where return type is
                              // embedded in the name
  std::vector<ParamTypeInfo> params_;

public:
  FunctionInfo() = default;
  FunctionInfo(const std::string &_name);

  bool isValid() const { return is_valid_; }
  Builtins::BuiltinType getType() const { return type_; }
  operator int() const { return type_; }
  const std::string &getName() const { return name_; }
  const ParamTypeInfo &getParameter(size_t arg) const;
  ParamTypeInfo &getParameter(size_t arg);
  const ParamTypeInfo &getLastParameter() const { return params_.back(); }
  size_t getParameterCount() const { return params_.size(); }
  const ParamTypeInfo &getReturnType() const { return return_type_; }

private:
  bool GetFromMangledNameCheck(const std::string &mangled_name);
};

/// Primary Interface
// returns a FunctionInfo representation of the mangled name
const FunctionInfo &Lookup(const std::string &mangled_name);
inline const FunctionInfo &Lookup(llvm::StringRef mangled_name) {
  return Lookup(mangled_name.str());
}
inline const FunctionInfo &Lookup(llvm::Function *func) {
  return Lookup(func->getName());
}

// Generate a mangled name loosely based on Itanium mangled naming but
// reversible by GetFromMangledName
std::string GetMangledFunctionName(const char *name, llvm::Type *type);

std::string GetMangledFunctionName(const char *name);

std::string GetMangledFunctionName(const FunctionInfo &Info);

std::string GetMangledTypeName(llvm::Type *T);

} // namespace Builtins

} // namespace clspv

#endif // CLSPV_LIB_BUILTINS_H_
