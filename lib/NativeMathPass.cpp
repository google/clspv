// Copyright 2021 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "Builtins.h"
#include "BuiltinsEnum.h"
#include "NativeMathPass.h"
#include "ReplaceOpenCLBuiltinPass.h"
#include "clspv/Option.h"
#include "clspv/spirv_glsl.hpp"

#include <set>

using namespace llvm;

namespace {
bool is_libclc_builtin(llvm::Function *F) {
  return F->getMetadata("clspv_libclc_builtin");
}

bool is_unsupported_fp64_glsl_op(clspv::glsl::ExtInst Op) {
  switch (Op) {
  case clspv::glsl::ExtInst::ExtInstRadians:
  case clspv::glsl::ExtInst::ExtInstDegrees:
  case clspv::glsl::ExtInst::ExtInstAcos:
  case clspv::glsl::ExtInst::ExtInstAcosh:
  case clspv::glsl::ExtInst::ExtInstAsin:
  case clspv::glsl::ExtInst::ExtInstAsinh:
  case clspv::glsl::ExtInst::ExtInstAtan:
  case clspv::glsl::ExtInst::ExtInstAtanh:
  case clspv::glsl::ExtInst::ExtInstAtan2:
  case clspv::glsl::ExtInst::ExtInstSin:
  case clspv::glsl::ExtInst::ExtInstSinh:
  case clspv::glsl::ExtInst::ExtInstCos:
  case clspv::glsl::ExtInst::ExtInstCosh:
  case clspv::glsl::ExtInst::ExtInstTan:
  case clspv::glsl::ExtInst::ExtInstTanh:
  case clspv::glsl::ExtInst::ExtInstExp:
  case clspv::glsl::ExtInst::ExtInstExp2:
  case clspv::glsl::ExtInst::ExtInstLog:
  case clspv::glsl::ExtInst::ExtInstLog2:
  case clspv::glsl::ExtInst::ExtInstPow:
    return true;
  default:
    return false;
  }
}

bool keep_fp64_libclc_body(const clspv::Builtins::FunctionInfo &Info,
                           const llvm::Function &F) {
  if (F.isDeclaration() || !F.getReturnType()->getScalarType()->isDoubleTy()) {
    return false;
  }
  if (is_unsupported_fp64_glsl_op(clspv::Builtins::getExtInstEnum(Info))) {
    return true;
  }
  switch (Info.getType()) {
  case clspv::Builtins::kExp10:
  case clspv::Builtins::kExpm1:
  case clspv::Builtins::kLog10:
  case clspv::Builtins::kLog1p:
  case clspv::Builtins::kPown:
  case clspv::Builtins::kCospi:
  case clspv::Builtins::kSinpi:
  case clspv::Builtins::kTanpi:
  case clspv::Builtins::kSincos:
    return true;
  default:
    return false;
  }
}
} // namespace

PreservedAnalyses clspv::NativeMathPass::run(Module &M,
                                             ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  auto nativeBuiltins = clspv::Option::UseNativeBuiltins();

  for (auto &F : M) {
    auto info = clspv::Builtins::Lookup(F.getName());

    // Default conversions are declarations replaced by ReplaceOpenCLBuiltinPass
    // with standard cast instructions, whereas saturated and explicit rounding
    // mode conversions have a libclc implementation body that must be kept.
    // FP64 math builtins lacking 64-bit Vulkan SPIR-V GLSL.std.450 support
    // also keep their libclc implementation bodies.
    bool is_convert_with_body =
        info.getType() == Builtins::kConvert && !F.isDeclaration();
    bool keep_libclc_body =
        is_convert_with_body || keep_fp64_libclc_body(info, F);

    bool has_glsl_ext_inst =
        Builtins::getExtInstEnum(info) != Builtins::kGlslExtInstBad;
    bool is_replaceable_builtin =
        ReplaceOpenCLBuiltinPass::ReplaceableBuiltins.count(info.getType()) > 0;
    bool have_native_impl =
        (has_glsl_ext_inst || is_replaceable_builtin) && !keep_libclc_body;
    if (have_native_impl &&
        (nativeBuiltins.count(info.getType()) || clspv::Option::NativeMath())) {
      F.deleteBody();
    } else if (!have_native_impl && !keep_libclc_body &&
               nativeBuiltins.count(info.getType())) {
      llvm::report_fatal_error(
          llvm::StringRef("--use-native-builtins: couldn't replace builtin '" +
                          info.getName() + "' with a native implementation!"));
    } else if (is_libclc_builtin(&F)) {
      // Those builtin has been marked with noinline to make sure that we
      // could replace them with native implementation. Now that we know
      // that we will not do it, let's remove the attribute so that they
      // can be inline if appropriate.
      F.removeFnAttr(Attribute::AttrKind::NoInline);
    }
  }

  // Force inlining of builtin inside builtin
  bool changed = true;
  while (changed) {
    std::vector<CallInst *> to_inline;
    for (auto &F : M) {
      if (is_libclc_builtin(&F)) {
        for (auto *user : F.users()) {
          if (auto *call = dyn_cast<CallInst>(user)) {
            if (is_libclc_builtin(call->getParent()->getParent())) {
              to_inline.push_back(call);
            }
          }
        }
      }
    }
    changed = false;
    for (auto call : to_inline) {
      InlineFunctionInfo IFI;
      changed |= InlineFunction(*call, IFI, false, nullptr, false).isSuccess();
    }
  }

  return PA;
}
