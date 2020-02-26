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

#include <unordered_map>
#include <stdlib.h>

using namespace llvm;
using namespace clspv;

////////////////////////////////////////////////////////////////////////////////
// utilities for const char* map keys
struct cstr_hash {
  std::size_t operator()(const char *cstr) const {
    std::size_t hash = 5381;
    for ( ; *cstr != '\0' ; ++cstr)
      hash = (hash * 33) + *cstr;
    return hash;
  }
};
struct cstr_eq {
  bool operator()(const char* a, const char *b) const { return strcmp(a, b) == 0; }
};

////////////////////////////////////////////////////////////////////////////////
////  Convert Builtin function name to a Type enum
////////////////////////////////////////////////////////////////////////////////
static Builtins::EBuiltinType GetBuiltinType(const std::string& _name) {
  static std::unordered_map<const char*, Builtins::EBuiltinType, cstr_hash, cstr_eq> s_func_map = {

#include "BuiltinsGen.cpp"

    // Internal
    { "clspv.fract.f",                             Builtins::EFract                                  },
    { "clspv.fract.v2f",                           Builtins::EFract                                  },
    { "clspv.fract.v3f",                           Builtins::EFract                                  },
    { "clspv.fract.v4f",                           Builtins::EFract                                  },

    { "__clspv_vloada_half2",                      Builtins::EVloadaHalf                             },
    { "__clspv_vloada_half4",                      Builtins::EVloadaHalf                             },
 
  };

  auto ii = s_func_map.find(_name.c_str());
  if (ii != s_func_map.end()) {
    return (*ii).second;
  }
  return Builtins::EBuiltinNone;
}

////////////////////////////////////////////////////////////////////////////////
////  FunctionInfo
////////////////////////////////////////////////////////////////////////////////

static bool GetUnmangledName(const std::string& str, size_t& pos, std::string& name) {
  char* end;
  int nameLen = strtol(&str[pos], &end, 10);
  if (!nameLen) {
    return false;
  }
  pos = end - str.data();

  name = str.substr(pos, nameLen);
  pos += nameLen;
  return true;
}

static bool GetParameterType(clspv::Builtins::ParamTypeInfo& ti, const std::string& name, size_t& pos) {
  // Parse a parameter type encoding
  char typeCode = name[pos++];

  int blen = 1;
  switch (typeCode) {
    // qualifiers
  case 'P':                         // Pointer
  case 'R':                         // Reference
    return GetParameterType(ti, name, pos);
  case 'k':                         // ??? not part of cxxabi
  case 'K':                         // const
  case 'V':                         // volatile
    return GetParameterType(ti, name, pos);
  case 'U': {                       // Address space
    std::string address_space;
    if (!GetUnmangledName(name, pos, address_space)) {
      return false;
    }
    return GetParameterType(ti, name, pos);
  }

  case 'D':
    typeCode = name[pos++];
    if (typeCode == 'v') {        // OCL vector
      char* end;
      int numElems = strtol(&name[pos], &end, 10);
      if (!numElems) {
        return false;
      }
      ti.vsiz = numElems;
      pos = end - name.data();

      if (name[pos++] != '_') {
        return false;
      }
      return GetParameterType(ti, name, pos);
    } else if (typeCode == 'h') { // OCL half
      ti.type      = Type::FloatTyID;
      ti.sign      = true;
      ti.blen      = 2;
    } else {
      assert(0);
    }
    break;

    // element types
  case 'l': blen <<= 1;             // long
  case 'i': blen <<= 1;             // int
  case 's': blen <<= 1;             // short
  case 'c':                         // char
  case 'a':                         // signed char
    ti.type      = Type::IntegerTyID;
    ti.sign      = true;
    ti.blen      = blen;
    break;
  case 'm': blen <<= 1;             // unsigned long
  case 'j': blen <<= 1;             // unsigned int
  case 't': blen <<= 1;             // unsigned short
  case 'h':                         // unsigned char
    ti.type      = Type::IntegerTyID;
    ti.sign      = false;
    ti.blen      = blen;
    break;
  case 'd': blen   = 2;            // double float
  case 'f': blen <<= 2;            // single float
    ti.type      = Type::FloatTyID;
    ti.sign      = true;
    ti.blen      = blen;
    break;
  case 'v': // void
    break;
  case 'S':
    if (name[pos++] != '_') {
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
    ti.type = Type::StructTyID;
    pos--;
    if (!GetUnmangledName(name, pos, ti.name)) {
      return false;
    }
    break;
  }
  case '.':
    return false;
  default:
#ifdef DEBUG
    printf("Func: %s\n", name.c_str());
    assert(0);
#endif
    return false;
  }
  return true;
}

bool Builtins::FunctionInfo::GetFromMangledNameCheck(const std::string& name) {
  size_t pos = 0;
  size_t len;
  if (name[pos++] != '_' || name[pos++] != 'Z') {
    m_name = name;
    return false;
  }

  if (!GetUnmangledName(name, pos, m_name)) {
    return false;
  }

  if (!m_name.compare(0, 8, "convert_")) {
    // deduce return type from name
    char tok = m_name[8];
    m_return_type.sign      = tok != 'u'; // unsigned
    m_return_type.type      = tok == 'f' ? Type::FloatTyID : Type::IntegerTyID;
  }

  ParamTypeInfo prev_ti;

  while (pos < name.length()) {
    ParamTypeInfo ti = prev_ti;
    if (!GetParameterType(ti, name, pos)) {
      return false;
    }
    m_params.push_back(std::move(ti));

    prev_ti = ti;
  }

  return true;
}

Builtins::FunctionInfo::FunctionInfo(const std::string& _name) {
  m_is_valid = GetFromMangledNameCheck(_name);
  m_type     = GetBuiltinType(m_name);
}

const Builtins::ParamTypeInfo& Builtins::FunctionInfo::getParameter(size_t _arg) const {
  assert(m_params.size() > _arg);
  return m_params[_arg];
}

////////////////////////////////////////////////////////////////////////////////
////  Lookup interface
////////////////////////////////////////////////////////////////////////////////
const Builtins::FunctionInfo& Builtins::Lookup(const std::string& _name) {
  static std::unordered_map<std::string, FunctionInfo> s_mangled_map;
  auto fi = s_mangled_map.emplace(_name, _name);
  return (*fi.first).second;
}


////////////////////////////////////////////////////////////////////////////////
////  Legacy interface
////////////////////////////////////////////////////////////////////////////////
bool Builtins::IsImageBuiltin(StringRef name) {
  auto func_type = Lookup(name).getType();
  return func_type > EType_Image_Start && func_type < EType_Image_End;
}

bool Builtins::IsSampledImageRead(StringRef name) {
  return IsFloatSampledImageRead(name) || IsUintSampledImageRead(name) || IsIntSampledImageRead(name);
}

bool Builtins::IsFloatSampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImagef) {
    const auto& pi = fi.getParameter(1);
    return pi.name == "ocl_sampler";
  }
  return false;
}

bool Builtins::IsUintSampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImageui) {
    const auto& pi = fi.getParameter(1);
    return pi.name == "ocl_sampler";
  }
  return false;
}

bool Builtins::IsIntSampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImagei) {
    const auto& pi = fi.getParameter(1);
    return pi.name == "ocl_sampler";
  }
  return false;
}

bool Builtins::IsUnsampledImageRead(StringRef name) {
  return IsFloatUnsampledImageRead(name) || IsUintUnsampledImageRead(name) || IsIntUnsampledImageRead(name);
}

bool Builtins::IsFloatUnsampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImagef) {
    const auto& pi = fi.getParameter(1);
    return pi.name != "ocl_sampler";
  }
  return false;
}

bool Builtins::IsUintUnsampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImageui) {
    const auto& pi = fi.getParameter(1);
    return pi.name != "ocl_sampler";
  }
  return false;
}

bool Builtins::IsIntUnsampledImageRead(StringRef _name) {
  const auto& fi = Lookup(_name);
  if (fi.getType() == EReadImagei) {
    const auto& pi = fi.getParameter(1);
    return pi.name != "ocl_sampler";
  }
  return false;
}

bool Builtins::IsImageWrite(StringRef name) {
  auto func_code = Lookup(name).getType();
  return func_code == EWriteImagef
    || func_code == EWriteImageui
    || func_code == EWriteImagei
    || func_code == EWriteImageh;
}

bool Builtins::IsFloatImageWrite(StringRef name) {
  return Lookup(name) == EWriteImagef;
}

bool Builtins::IsUintImageWrite(StringRef name) {
  return Lookup(name) == EWriteImageui;
}

bool Builtins::IsIntImageWrite(StringRef name) {
  return Lookup(name) == EWriteImagei;
}

bool Builtins::IsGetImageHeight(StringRef name) {
  return Lookup(name) == EGetImageHeight;
}

bool Builtins::IsGetImageWidth(StringRef name) {
  return Lookup(name) == EGetImageWidth;
}

bool Builtins::IsGetImageDepth(StringRef name) {
  return Lookup(name) == EGetImageDepth;
}

bool Builtins::IsGetImageDim(StringRef name) {
  return Lookup(name) == EGetImageDim;
}

bool Builtins::IsImageQuery(StringRef name) {
  auto func_code = Lookup(name).getType();
  return func_code == EGetImageHeight
    || func_code == EGetImageWidth
    || func_code == EGetImageDepth
    || func_code == EGetImageDim;
}

