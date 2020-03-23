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

  if (!name_.compare(0, 8, "convert_")) {
    // deduce return type from name, only for convert
    char tok = name_[8];
    return_type_.is_signed = tok != 'u'; // unsigned
    return_type_.type_id = tok == 'f' ? Type::FloatTyID : Type::IntegerTyID;
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
}

// get const ParamTypeInfo for nth parameter
const Builtins::ParamTypeInfo &
Builtins::FunctionInfo::getParameter(size_t _arg) const {
  assert(params_.size() > _arg);
  return params_[_arg];
}

// Test for OCL Sampler parameter type
bool Builtins::ParamTypeInfo::isSampler() const {
  return type_id == Type::StructTyID && name == "ocl_sampler";
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
////  Legacy interface
////////////////////////////////////////////////////////////////////////////////
bool Builtins::IsImageBuiltin(StringRef name) {
  auto func_type = Lookup(name).getType();
  return func_type > kType_Image_Start && func_type < kType_Image_End;
}

bool Builtins::IsSampledImageRead(StringRef name) {
  return IsFloatSampledImageRead(name) || IsUintSampledImageRead(name) ||
         IsIntSampledImageRead(name);
}

bool Builtins::IsFloatSampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagef) {
    const auto &pi = fi.getParameter(1);
    return pi.isSampler();
  }
  return false;
}

bool Builtins::IsUintSampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImageui) {
    const auto &pi = fi.getParameter(1);
    return pi.isSampler();
  }
  return false;
}

bool Builtins::IsIntSampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagei) {
    const auto &pi = fi.getParameter(1);
    return pi.isSampler();
  }
  return false;
}

bool Builtins::IsUnsampledImageRead(StringRef name) {
  return IsFloatUnsampledImageRead(name) || IsUintUnsampledImageRead(name) ||
         IsIntUnsampledImageRead(name);
}

bool Builtins::IsFloatUnsampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagef) {
    const auto &pi = fi.getParameter(1);
    return !pi.isSampler();
  }
  return false;
}

bool Builtins::IsUintUnsampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImageui) {
    const auto &pi = fi.getParameter(1);
    return !pi.isSampler();
  }
  return false;
}

bool Builtins::IsIntUnsampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagei) {
    const auto &pi = fi.getParameter(1);
    return !pi.isSampler();
  }
  return false;
}

bool Builtins::IsImageWrite(StringRef name) {
  auto func_code = Lookup(name).getType();
  return func_code == kWriteImagef || func_code == kWriteImageui ||
         func_code == kWriteImagei || func_code == kWriteImageh;
}

bool Builtins::IsFloatImageWrite(StringRef name) {
  return Lookup(name) == kWriteImagef;
}

bool Builtins::IsUintImageWrite(StringRef name) {
  return Lookup(name) == kWriteImageui;
}

bool Builtins::IsIntImageWrite(StringRef name) {
  return Lookup(name) == kWriteImagei;
}

bool Builtins::IsGetImageHeight(StringRef name) {
  return Lookup(name) == kGetImageHeight;
}

bool Builtins::IsGetImageWidth(StringRef name) {
  return Lookup(name) == kGetImageWidth;
}

bool Builtins::IsGetImageDepth(StringRef name) {
  return Lookup(name) == kGetImageDepth;
}

bool Builtins::IsGetImageDim(StringRef name) {
  return Lookup(name) == kGetImageDim;
}

bool Builtins::IsImageQuery(StringRef name) {
  auto func_code = Lookup(name).getType();
  return func_code == kGetImageHeight || func_code == kGetImageWidth ||
         func_code == kGetImageDepth || func_code == kGetImageDim;
}
