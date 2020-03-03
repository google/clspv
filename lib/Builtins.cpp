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

#include <stdlib.h>
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
////  Mangled name parsing utilities
////////////////////////////////////////////////////////////////////////////////

// capture real name of function and struct types
std::string GetUnmangledName(const std::string &str, size_t *pos) {
  char *end;
  int name_len = strtol(&str[*pos], &end, 10);
  if (!name_len) {
    return "";
  }
  size_t name_pos = end - str.data();

  std::string real_name = str.substr(name_pos, name_len);
  *pos = name_pos + name_len;
  return real_name;
}

// capture parameter type and qualifiers based on Itanium ABI with OpenCL types
bool GetParameterType(const std::string &mangled_name,
                      clspv::Builtins::ParamTypeInfo *type_info, size_t *pos) {
  // Parse a parameter type encoding
  char type_code = mangled_name[(*pos)++];

  int blen = 1;
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
    std::string address_space = GetUnmangledName(mangled_name, pos);
    return GetParameterType(mangled_name, type_info, pos);
  }

  case 'D':
    type_code = mangled_name[(*pos)++];
    if (type_code == 'v') { // OCL vector
      char *end;
      int numElems = strtol(&mangled_name[*pos], &end, 10);
      if (!numElems) {
        return false;
      }
      type_info->vector_size = numElems;
      *pos = end - mangled_name.data();

      if (mangled_name[(*pos)++] != '_') {
        return false;
      }
      return GetParameterType(mangled_name, type_info, pos);
    } else if (type_code == 'h') { // OCL half
      type_info->type_id = Type::FloatTyID;
      type_info->is_signed = true;
      type_info->byte_len = 2;
    } else {
      assert(0);
    }
    break;

    // element types
  case 'l':
    blen <<= 1; // long
  case 'i':
    blen <<= 1; // int
  case 's':
    blen <<= 1; // short
  case 'c':     // char
  case 'a':     // signed char
    type_info->type_id = Type::IntegerTyID;
    type_info->is_signed = true;
    type_info->byte_len = blen;
    break;
  case 'm':
    blen <<= 1; // unsigned long
  case 'j':
    blen <<= 1; // unsigned int
  case 't':
    blen <<= 1; // unsigned short
  case 'h':     // unsigned char
    type_info->type_id = Type::IntegerTyID;
    type_info->is_signed = false;
    type_info->byte_len = blen;
    break;
  case 'd':
    blen = 2; // double float
  case 'f':
    blen <<= 2; // single float
    type_info->type_id = Type::FloatTyID;
    type_info->is_signed = true;
    type_info->byte_len = blen;
    break;
  case 'v': // void
    break;
  case 'S':
    if (mangled_name[(*pos)++] != '_') {
      return false;
    }
    break;
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
  case '6':
  case '7':
  case '8':
  case '9': {
    type_info->type_id = Type::StructTyID;
    (*pos)--;
    type_info->name = GetUnmangledName(mangled_name, pos);
    break;
  }
  case '.':
    return false;
  default:
#ifdef DEBUG
    printf("Func: %s\n", mangled_name.c_str());
    llvm_unreachable("failed to demangle name");
#endif
    return false;
  }
  return true;
}
} // namespace

////////////////////////////////////////////////////////////////////////////////
// FunctionInfo::GetFromMangledNameCheck
//   - parse mangled name as far as possible. Some names are an aggregate of
//   fields separated by '.'
bool Builtins::FunctionInfo::GetFromMangledNameCheck(
    const std::string &mangled_name) {
  size_t pos = 0;
  size_t len;
  if (mangled_name[pos++] != '_' || mangled_name[pos++] != 'Z') {
    name_ = mangled_name;
    return false;
  }

  name_ = GetUnmangledName(mangled_name, &pos);

  if (!name_.compare(0, 8, "convert_")) {
    // deduce return type from name
    char tok = name_[8];
    return_type_.is_signed = tok != 'u'; // unsigned
    return_type_.type_id = tok == 'f' ? Type::FloatTyID : Type::IntegerTyID;
  }

  ParamTypeInfo prev_type_info;

  auto mangled_name_len = mangled_name.length();
  while (pos < mangled_name_len) {
    ParamTypeInfo type_info = prev_type_info;
    if (!GetParameterType(mangled_name, &type_info, &pos)) {
      return false;
    }
    params_.push_back(std::move(type_info));

    prev_type_info = type_info;
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
    return pi.name == "ocl_sampler";
  }
  return false;
}

bool Builtins::IsUintSampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImageui) {
    const auto &pi = fi.getParameter(1);
    return pi.name == "ocl_sampler";
  }
  return false;
}

bool Builtins::IsIntSampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagei) {
    const auto &pi = fi.getParameter(1);
    return pi.name == "ocl_sampler";
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
    return pi.name != "ocl_sampler";
  }
  return false;
}

bool Builtins::IsUintUnsampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImageui) {
    const auto &pi = fi.getParameter(1);
    return pi.name != "ocl_sampler";
  }
  return false;
}

bool Builtins::IsIntUnsampledImageRead(StringRef _name) {
  const auto &fi = Lookup(_name);
  if (fi.getType() == kReadImagei) {
    const auto &pi = fi.getParameter(1);
    return pi.name != "ocl_sampler";
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
