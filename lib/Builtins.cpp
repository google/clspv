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

#include "llvm/Support/raw_ostream.h"

#include "Builtins.h"
#include "clspv/spirv_glsl.hpp"

#include <cstdlib>
#include <unordered_map>

using namespace llvm;
using namespace clspv;

////////////////////////////////////////////////////////////////////////////////
////  Convert Builtin function name to a Type enum
////////////////////////////////////////////////////////////////////////////////
Builtins::BuiltinType Builtins::LookupBuiltinType(const std::string &name) {

// Build static map of builtin function names
#include "BuiltinsMap.inc"

  auto ii = s_func_map.find(name.c_str());
  if (ii != s_func_map.end()) {
    return (*ii).second;
  }
  return Builtins::kBuiltinNone;
}

namespace {

const std::string kPreviousParam = "__clspv_previous_param";

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
  if (static_cast<std::size_t>(name_pos + name_len) > str.size()) {
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
  case 'A': { // Atomic type
    if (mangled_name.substr(pos, 5) == "tomic")
      return GetParameterType(mangled_name, type_info, pos + 5);
    return 0;
  }
  case 'S':
    // same as previous parameter
    if (mangled_name[pos] != '_') {
      return 0;
    }
    type_info->name = kPreviousParam;
    return pos + 1;
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
      type_info->type_id = Type::HalfTyID;
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
      // handle duplicate param_type. Comes in two flavours:
      // S_ and S#_.
      char p1 = mangled_name[pos + 1];
      if (p1 != '_' && (mangled_name[pos + 2] != '_')) {
        return false;
      }
      pos += p1 == '_' ? 2 : 3;
      if (params_.empty()) {
        return false;
      }
      params_.push_back(params_.back());
    } else if ((pos = GetParameterType(mangled_name, &type_info, pos))) {
      if (type_info.type_id == llvm::Type::VoidTyID &&
          type_info.name == kPreviousParam) {
        // After additional demangling, the underlying data type is the same as
        // the previous parameter.
        if (!params_.empty()) {
          params_.push_back(params_.back());
        } else {
          return false;
        }
      } else {
        params_.push_back(type_info);
      }
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

Builtins::ParamTypeInfo &Builtins::FunctionInfo::getParameter(size_t _arg) {
  assert(params_.size() > _arg);
  return params_[_arg];
}

// Test for OCL Sampler parameter type
bool Builtins::ParamTypeInfo::isSampler() const {
  return type_id == Type::StructTyID &&
         (name == "ocl_sampler" || name == "opencl.sampler_t");
}

llvm::Type *Builtins::ParamTypeInfo::DataType(LLVMContext &context) const {
  if (isSampler()) {
    llvm_unreachable("sampler is unhandled");
  }

  Type *ty = nullptr;
  switch (type_id) {
    case llvm::Type::IntegerTyID:
      ty = llvm::IntegerType::get(context, byte_len * 8);
      break;
    case llvm::Type::HalfTyID:
      ty = llvm::Type::getHalfTy(context);
      break;
    case llvm::Type::FloatTyID:
      ty = llvm::Type::getFloatTy(context);
      break;
    case llvm::Type::DoubleTyID:
      ty = llvm::Type::getDoubleTy(context);
      break;
    default:
      llvm_unreachable("unsupported type");
      break;
  }

  if (vector_size > 0) {
    ty = FixedVectorType::get(ty, vector_size);
  }

  return ty;
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
      std::string arg_name = GetMangledTypeName(arg_type);
      if (arg_name.size() > 1 && arg_type == last_arg_type) {
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

std::string
Builtins::GetMangledFunctionName(const Builtins::FunctionInfo &info) {
  // This is a best-effort attempt at reconstructing the mangled name for the
  // given function. Because demangling is a lossy process some information may
  // be lost and is therefore no longer available.
  std::string name;
  raw_string_ostream out(name);

  StringRef function_name = info.getName();
  out << "_Z" << function_name.size() << function_name;

  for (size_t i = 0; i < info.getParameterCount(); ++i) {
    const auto &param = info.getParameter(i);

    if (param.vector_size != 0) {
      out << "Dv" << param.vector_size << '_';
    }

    switch (param.type_id) {
    case Type::FloatTyID:
    case Type::HalfTyID:
      switch (param.byte_len) {
      case 2:
        out << "Dh";
        break;
      case 4:
        out << "f";
        break;
      case 8:
        out << "d";
        break;
      default:
        llvm_unreachable("Invalid byte_len for floating point type.");
        break;
      }
      break;

    case Type::IntegerTyID:
      if (param.is_signed) {
        switch (param.byte_len) {
        case 1:
          // Not enough information to distinguish between char (c) and signed
          // char (a).
          out << 'c';
          break;
        case 2:
          out << "s";
          break;
        case 4:
          out << "i";
          break;
        case 8:
          out << "l";
          break;
        default:
          llvm_unreachable("Invalid byte_len for signed integer type.");
          break;
        }
      } else {
        switch (param.byte_len) {
        case 1:
          out << 'h';
          break;
        case 2:
          out << "t";
          break;
        case 4:
          out << "j";
          break;
        case 8:
          out << "m";
          break;
        default:
          llvm_unreachable("Invalid byte_len for unsigned integer type.");
          break;
        }
      }
      break;

    case Type::StructTyID:
      out << param.name.size() << param.name;
      break;

    default:
      llvm_unreachable("Unsupported type id");
      break;
    }
  }

  out.flush();
  return name;
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
    break;
  }
  case Type::FixedVectorTyID: {
    auto VecTy = cast<VectorType>(Ty);
    mangled_type_str =
        "Dv" + std::to_string(VecTy->getElementCount().getKnownMinValue()) +
        "_" + GetMangledTypeName(VecTy->getElementType());
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

glsl::ExtInst
Builtins::getExtInstEnum(const Builtins::FunctionInfo &func_info) {
  switch (func_info.getType()) {
  case Builtins::kClamp: {
    auto param_type = func_info.getParameter(0);
    if (IsFloatTypeID(param_type.type_id)) {
      return glsl::ExtInst::ExtInstNClamp;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSClamp
                                : glsl::ExtInst::ExtInstUClamp;
  }
  case Builtins::kMax: {
    auto param_type = func_info.getParameter(0);
    if (IsFloatTypeID(param_type.type_id)) {
      return glsl::ExtInst::ExtInstFMax;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSMax
                                : glsl::ExtInst::ExtInstUMax;
  }
  case Builtins::kMin: {
    auto param_type = func_info.getParameter(0);
    if (IsFloatTypeID(param_type.type_id)) {
      return glsl::ExtInst::ExtInstFMin;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSMin
                                : glsl::ExtInst::ExtInstUMin;
  }
  case Builtins::kAbs:
    return glsl::ExtInst::ExtInstSAbs;
  case Builtins::kFmax:
    return glsl::ExtInst::ExtInstNMax;
  case Builtins::kFmin:
    return glsl::ExtInst::ExtInstNMin;
  case Builtins::kDegrees:
    return glsl::ExtInst::ExtInstDegrees;
  case Builtins::kRadians:
    return glsl::ExtInst::ExtInstRadians;
  case Builtins::kMix:
    return glsl::ExtInst::ExtInstFMix;
  case Builtins::kAcos:
  case Builtins::kAcospi:
    return glsl::ExtInst::ExtInstAcos;
  case Builtins::kAcosh:
    return glsl::ExtInst::ExtInstAcosh;
  case Builtins::kAsin:
  case Builtins::kAsinpi:
    return glsl::ExtInst::ExtInstAsin;
  case Builtins::kAsinh:
    return glsl::ExtInst::ExtInstAsinh;
  case Builtins::kAtan:
  case Builtins::kAtanpi:
    return glsl::ExtInst::ExtInstAtan;
  case Builtins::kAtanh:
    return glsl::ExtInst::ExtInstAtanh;
  case Builtins::kAtan2:
  case Builtins::kAtan2pi:
    return glsl::ExtInst::ExtInstAtan2;
  case Builtins::kCeil:
    return glsl::ExtInst::ExtInstCeil;
  case Builtins::kSin:
  case Builtins::kHalfSin:
  case Builtins::kNativeSin:
    return glsl::ExtInst::ExtInstSin;
  case Builtins::kSinh:
    return glsl::ExtInst::ExtInstSinh;
  case Builtins::kCos:
  case Builtins::kHalfCos:
  case Builtins::kNativeCos:
    return glsl::ExtInst::ExtInstCos;
  case Builtins::kCosh:
    return glsl::ExtInst::ExtInstCosh;
  case Builtins::kTan:
  case Builtins::kHalfTan:
  case Builtins::kNativeTan:
    return glsl::ExtInst::ExtInstTan;
  case Builtins::kTanh:
    return glsl::ExtInst::ExtInstTanh;
  case Builtins::kExp:
  case Builtins::kHalfExp:
  case Builtins::kNativeExp:
    return glsl::ExtInst::ExtInstExp;
  case Builtins::kExp2:
  case Builtins::kHalfExp2:
  case Builtins::kNativeExp2:
    return glsl::ExtInst::ExtInstExp2;
  case Builtins::kLog:
  case Builtins::kHalfLog:
  case Builtins::kNativeLog:
    return glsl::ExtInst::ExtInstLog;
  case Builtins::kLog2:
  case Builtins::kHalfLog2:
  case Builtins::kNativeLog2:
    return glsl::ExtInst::ExtInstLog2;
  case Builtins::kFabs:
    return glsl::ExtInst::ExtInstFAbs;
  case Builtins::kFma:
    return glsl::ExtInst::ExtInstFma;
  case Builtins::kFloor:
    return glsl::ExtInst::ExtInstFloor;
  case Builtins::kLdexp:
    return glsl::ExtInst::ExtInstLdexp;
  case Builtins::kPow:
  case Builtins::kPowr:
  case Builtins::kHalfPowr:
  case Builtins::kNativePowr:
    return glsl::ExtInst::ExtInstPow;
  case Builtins::kRint:
    return glsl::ExtInst::ExtInstRoundEven;
  case Builtins::kRound:
    return glsl::ExtInst::ExtInstRound;
  case Builtins::kSqrt:
  case Builtins::kHalfSqrt:
  case Builtins::kNativeSqrt:
    return glsl::ExtInst::ExtInstSqrt;
  case Builtins::kRsqrt:
  case Builtins::kHalfRsqrt:
  case Builtins::kNativeRsqrt:
    return glsl::ExtInst::ExtInstInverseSqrt;
  case Builtins::kTrunc:
    return glsl::ExtInst::ExtInstTrunc;
  case Builtins::kFrexp:
    return glsl::ExtInst::ExtInstFrexp;
  case Builtins::kClspvFract:
  case Builtins::kFract:
    return glsl::ExtInst::ExtInstFract;
  case Builtins::kSign:
    return glsl::ExtInst::ExtInstFSign;
  case Builtins::kLength:
  case Builtins::kFastLength:
    return glsl::ExtInst::ExtInstLength;
  case Builtins::kDistance:
  case Builtins::kFastDistance:
    return glsl::ExtInst::ExtInstDistance;
  case Builtins::kStep:
    return glsl::ExtInst::ExtInstStep;
  case Builtins::kSmoothstep:
    return glsl::ExtInst::ExtInstSmoothStep;
  case Builtins::kCross:
    return glsl::ExtInst::ExtInstCross;
  case Builtins::kNormalize:
  case Builtins::kFastNormalize:
    return glsl::ExtInst::ExtInstNormalize;
  case Builtins::kSpirvPack:
    return glsl::ExtInst::ExtInstPackHalf2x16;
  case Builtins::kSpirvUnpack:
    return glsl::ExtInst::ExtInstUnpackHalf2x16;
  default:
    break;
  }

  // TODO: improve this by checking the intrinsic id.
  if (func_info.getName().find("llvm.fmuladd.") == 0) {
    return glsl::ExtInst::ExtInstFma;
  }
  if (func_info.getName().find("llvm.sqrt.") == 0) {
    return glsl::ExtInst::ExtInstSqrt;
  }
  if (func_info.getName().find("llvm.trunc.") == 0) {
    return glsl::ExtInst::ExtInstTrunc;
  }
  if (func_info.getName().find("llvm.ctlz.") == 0) {
    return glsl::ExtInst::ExtInstFindUMsb;
  }
  if (func_info.getName().find("llvm.cttz.") == 0) {
    return glsl::ExtInst::ExtInstFindILsb;
  }
  if (func_info.getName().find("llvm.ceil.") == 0) {
    return glsl::ExtInst::ExtInstCeil;
  }
  if (func_info.getName().find("llvm.rint.") == 0) {
    return glsl::ExtInst::ExtInstRoundEven;
  }
  if (func_info.getName().find("llvm.fabs.") == 0) {
    return glsl::ExtInst::ExtInstFAbs;
  }
  if (func_info.getName().find("llvm.abs.") == 0) {
    return glsl::ExtInst::ExtInstSAbs;
  }
  if (func_info.getName().find("llvm.floor.") == 0) {
    return glsl::ExtInst::ExtInstFloor;
  }
  if (func_info.getName().find("llvm.sin.") == 0) {
    return glsl::ExtInst::ExtInstSin;
  }
  if (func_info.getName().find("llvm.cos.") == 0) {
    return glsl::ExtInst::ExtInstCos;
  }
  if (func_info.getName().find("llvm.exp.") == 0) {
    return glsl::ExtInst::ExtInstExp;
  }
  if (func_info.getName().find("llvm.log.") == 0) {
    return glsl::ExtInst::ExtInstLog;
  }
  if (func_info.getName().find("llvm.pow.") == 0) {
    return glsl::ExtInst::ExtInstPow;
  }
  if (func_info.getName().find("llvm.smax.") == 0) {
    return glsl::ExtInst::ExtInstSMax;
  }
  if (func_info.getName().find("llvm.smin.") == 0) {
    return glsl::ExtInst::ExtInstSMin;
  }
  if (func_info.getName().find("llvm.umax.") == 0) {
    return glsl::ExtInst::ExtInstUMax;
  }
  if (func_info.getName().find("llvm.umin.") == 0) {
    return glsl::ExtInst::ExtInstUMin;
  }
  return kGlslExtInstBad;
}

glsl::ExtInst
Builtins::getIndirectExtInstEnum(const Builtins::FunctionInfo &func_info) {
  switch (func_info.getType()) {
  case Builtins::kAcospi:
    return glsl::ExtInst::ExtInstAcos;
  case Builtins::kAsinpi:
    return glsl::ExtInst::ExtInstAsin;
  case Builtins::kAtanpi:
    return glsl::ExtInst::ExtInstAtan;
  case Builtins::kAtan2pi:
    return glsl::ExtInst::ExtInstAtan2;
  default:
    break;
  }
  return kGlslExtInstBad;
}

glsl::ExtInst Builtins::getDirectOrIndirectExtInstEnum(
    const Builtins::FunctionInfo &func_info) {
  auto direct = getExtInstEnum(func_info);
  if (direct != kGlslExtInstBad)
    return direct;
  return getIndirectExtInstEnum(func_info);
}

bool Builtins::BuiltinWithGenericPointer(StringRef name) {
  if (name.contains("fract") || name.contains("frexp") ||
      name.contains("modf") || name.contains("remquo") ||
      name.contains("lgamma_r") || name.contains("vstore_half") ||
      name.contains("sincos"))
    return true;
  return false;
}

bool Builtins::IsFloatTypeID(llvm::Type::TypeID type_id) {
  return type_id == llvm::Type::FloatTyID || type_id == llvm::Type::HalfTyID;
}
