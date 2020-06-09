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

#include "Builtins.h"

#include <cstdlib>
#include <unordered_map>

using namespace llvm;
using namespace clspv;

namespace {
////////////////////////////////////////////////////////////////////////////////
////  Convert Builtin function name to a Type enum
////////////////////////////////////////////////////////////////////////////////
Builtins::BuiltinType LookupBuiltinType(const std::string &name) {

// Build static map of builtin function names
#include "BuiltinsMap.inc"

  auto ii = s_func_map.find(name.c_str());
  if (ii != s_func_map.end()) {
    return (*ii).second;
  }
  return Builtins::kBuiltinNone;
}

////////////////////////////////////////////////////////////////////////////////
// Mangled name parsing utilities
// - We only handle Itanium-style C++ mangling, plus modifications for OpenCL.
////////////////////////////////////////////////////////////////////////////////

// Given a mangled name starting at character position |pos| in |str|, extracts
// the original name (without mangling) and updates |pos| so it will index the
// character just past that original name (which might be just past the end of
// the string). If the mangling is invalid, then an empty string is returned,
// and |pos| is not updated. Example: if str = "_Z3fooi", and *pos = 2, then
// returns "foo" and adds 4 to *pos.
std::string GetUnmangledName(const std::string &str, size_t *pos) {
  char *end = nullptr;
  assert(*pos < str.size());
  auto name_len = strtol(&str[*pos], &end, 10);
  if (!name_len) {
    return "";
  }
  ptrdiff_t name_pos = end - str.data();
  if (name_pos + name_len > str.size()) {
    // Protect against maliciously large number.
    return "";
  }

  *pos = name_pos + name_len;
  return str.substr(size_t(name_pos), name_len);
}

// Capture parameter type and qualifiers starting at |pos|
// - return new parsing position pos, or zero for error
size_t GetParameterType(const std::string &mangled_name,
                        clspv::Builtins::ParamTypeInfo *type_info, size_t pos) {
  // Parse a parameter type encoding
  char type_code = mangled_name[pos++];

  switch (type_code) {
    // qualifiers
  case 'P': // Pointer
  case 'R': // Reference
    return GetParameterType(mangled_name, type_info, pos);
  case 'k': // ??? not part of cxxabi
  case 'K': // const
  case 'V': // volatile
    return GetParameterType(mangled_name, type_info, pos);
  case 'U': { // Address space
    // address_space name not captured
    (void)GetUnmangledName(mangled_name, &pos);
    return GetParameterType(mangled_name, type_info, pos);
  }
    // OCL types
  case 'D':
    type_code = mangled_name[pos++];
    if (type_code == 'v') { // OCL vector
      char *end = nullptr;
      int numElems = strtol(&mangled_name[pos], &end, 10);
      if (!numElems) {
        return 0;
      }
      type_info->vector_size = numElems;
      pos = end - mangled_name.data();
      if (pos > mangled_name.size()) {
        // Protect against maliciously large number.
        return 0;
      }

      if (mangled_name[pos++] != '_') {
        return 0;
      }
      return GetParameterType(mangled_name, type_info, pos);
    } else if (type_code == 'h') { // OCL half
      type_info->type_id = Type::FloatTyID;
      type_info->is_signed = true;
      type_info->byte_len = 2;
      return pos;
    } else {
#ifdef DEBUG
      llvm::outs() << "Func: " << mangled_name << "\n";
      llvm_unreachable("failed to demangle name");
#endif
      return 0;
    }
    break;

    // element types
  case 'l': // long
  case 'i': // int
  case 's': // short
  case 'c': // char
  case 'a': // signed char
    type_info->type_id = Type::IntegerTyID;
    type_info->is_signed = true;
    break;
  case 'm': // unsigned long
  case 'j': // unsigned int
  case 't': // unsigned short
  case 'h': // unsigned char
    type_info->type_id = Type::IntegerTyID;
    type_info->is_signed = false;
    break;
  case 'd': // double float
  case 'f': // single float
    type_info->type_id = Type::FloatTyID;
    type_info->is_signed = true;
    break;
  case 'v': // void
    break;
  case '1': // struct name
  case '2': // - a <positive length number> for size of the following name
  case '3': // - e.g. struct Foobar {} - would be encoded as '6Foobar'
  case '4': // https://itanium-cxx-abi.github.io/cxx-abi/abi.html#mangle.unqualified-name
  case '5':
  case '6':
  case '7':
  case '8':
  case '9':
    type_info->type_id = Type::StructTyID;
    pos--;
    type_info->name = GetUnmangledName(mangled_name, &pos);
    break;
  case '.':
    return 0;
  default:
#ifdef DEBUG
    llvm::outs() << "Func: " << mangled_name << "\n";
    llvm_unreachable("failed to demangle name");
#endif
    return 0;
  }

  switch (type_code) {
    // element types
  case 'l': // long
  case 'm': // unsigned long
  case 'd': // double float
    type_info->byte_len = 8;
    break;
  case 'i': // int
  case 'j': // unsigned int
  case 'f': // single float
    type_info->byte_len = 4;
    break;
  case 's': // short
  case 't': // unsigned short
    type_info->byte_len = 2;
    break;
  case 'c': // char
  case 'a': // signed char
  case 'h': // unsigned char
    type_info->byte_len = 1;
    break;
  default:
    break;
  }
  return pos;
}
} // namespace

////////////////////////////////////////////////////////////////////////////////
// FunctionInfo::GetFromMangledNameCheck
//   - parse mangled name as far as possible. Some names are an aggregate of
//   fields separated by '.'
//   - extract name and parameter types, and return type for 'convert' functions
//   - return true if the mangled name can be fully parsed
bool Builtins::FunctionInfo::GetFromMangledNameCheck(
    const std::string &mangled_name) {
  size_t pos = 0;
  if (!(mangled_name[pos++] == '_' && mangled_name[pos++] == 'Z')) {
    name_ = mangled_name;
    return false;
  }

  name_ = GetUnmangledName(mangled_name, &pos);
  if (name_.empty()) {
    return false;
  }

  auto mangled_name_len = mangled_name.size();
  while (pos < mangled_name_len) {
    ParamTypeInfo type_info;
    if (mangled_name[pos] == 'S') {
      // handle duplicate param_type
      if (mangled_name[pos + 1] != '_') {
        return false;
      }
      pos += 2;
      if (params_.empty()) {
        return false;
      }
      params_.push_back(params_.back());
    } else if ((pos = GetParameterType(mangled_name, &type_info, pos))) {
      params_.push_back(type_info);
    } else {
      return false;
    }
  }

  return true;
}

////////////////////////////////////////////////////////////////////////////////
// FunctionInfo ctor - parses mangled name
Builtins::FunctionInfo::FunctionInfo(const std::string &mangled_name) {
  is_valid_ = GetFromMangledNameCheck(mangled_name);
  type_ = LookupBuiltinType(name_);
  if (type_ == kConvert) {
    // deduce return type from name, only for convert
    char tok = name_[8];
    return_type_.is_signed = tok != 'u'; // unsigned
    return_type_.type_id = tok == 'f' ? Type::FloatTyID : Type::IntegerTyID;
  }
}

// get const ParamTypeInfo for nth parameter
const Builtins::ParamTypeInfo &
Builtins::FunctionInfo::getParameter(size_t _arg) const {
  assert(params_.size() > _arg);
  return params_[_arg];
}

// Test for OCL Sampler parameter type
bool Builtins::ParamTypeInfo::isSampler() const {
  return type_id == Type::StructTyID &&
         (name == "ocl_sampler" || name == "opencl.sampler_t");
}

////////////////////////////////////////////////////////////////////////////////
////  Lookup interface
////   - only demangle once for any name encountered
////////////////////////////////////////////////////////////////////////////////
const Builtins::FunctionInfo &
Builtins::Lookup(const std::string &mangled_name) {
  static std::unordered_map<std::string, FunctionInfo> s_mangled_map;
  auto fi = s_mangled_map.emplace(mangled_name, mangled_name);
  return (*fi.first).second;
}

////////////////////////////////////////////////////////////////////////////////
// Generate a mangled name loosely based on Itanium mangling
std::string Builtins::GetMangledFunctionName(const char *name, Type *type) {
  assert(name);
  std::string mangled_name =
      std::string("_Z") + std::to_string(strlen(name)) + name;
  if (auto *func_type = dyn_cast<FunctionType>(type)) {
    Type *last_arg_type = nullptr;
    for (auto *arg_type : func_type->params()) {
      if (arg_type == last_arg_type) {
        mangled_name += "S_";
      } else {
        mangled_name += GetMangledTypeName(arg_type);
        last_arg_type = arg_type;
      }
    }
  } else {
    mangled_name += GetMangledTypeName(type);
  }
  return mangled_name;
}

// The mangling follows the Itanium convention.
std::string Builtins::GetMangledFunctionName(const char *name) {
  assert(name);
  return std::string("_Z") + std::to_string(strlen(name)) + name;
}

// The mangling loosely follows the Itanium convention.
// Its purpose is solely to ensure uniqueness of names, it is not
// meant to convey type information.
std::string Builtins::GetMangledTypeName(Type *Ty) {
  std::string mangled_type_str;

  switch (Ty->getTypeID()) {
  case Type::VoidTyID:
    return "v";
  case Type::HalfTyID:
    return "Dh";
  case Type::FloatTyID:
    return "f";
  case Type::DoubleTyID:
    return "d";

  case Type::IntegerTyID:
    switch (Ty->getIntegerBitWidth()) {
    case 1:
      return "b";
    case 8:
      return "h";
    case 16:
      return "t";
    case 32:
      return "j";
    case 64:
      return "m";
    default:
      assert(0);
      break;
    }
    break;

  case Type::StructTyID: {
    auto *StrTy = cast<StructType>(Ty);
    if (StrTy->isLiteral()) {
      assert(StrTy->getNumElements() == 1);
      return GetMangledTypeName(StrTy->getElementType(0));
    }
    mangled_type_str =
        std::to_string(Ty->getStructName().size()) + Ty->getStructName().str();
    break;
  }
  case Type::ArrayTyID:
    mangled_type_str = "P" + GetMangledTypeName(Ty->getArrayElementType());
    break;
  case Type::PointerTyID: {
    mangled_type_str = "P";
    auto AS = Ty->getPointerAddressSpace();
    if (AS != 0) {
      std::string AS_name = "AS" + std::to_string(AS);
      mangled_type_str += "U" + std::to_string(AS_name.size()) + AS_name;
    }
    mangled_type_str += GetMangledTypeName(Ty->getPointerElementType());
    break;
  }
  case Type::FixedVectorTyID: {
    auto VecTy = cast<VectorType>(Ty);
    mangled_type_str = "Dv" + std::to_string(VecTy->getNumElements()) + "_" +
                       GetMangledTypeName(VecTy->getElementType());
    break;
  }

  case Type::FunctionTyID:
  case Type::X86_FP80TyID:
  case Type::FP128TyID:
  case Type::PPC_FP128TyID:
  case Type::LabelTyID:
  case Type::MetadataTyID:
  case Type::X86_MMXTyID:
  case Type::TokenTyID:
  default:
    assert(0);
    break;
  }
  return mangled_type_str;
}
