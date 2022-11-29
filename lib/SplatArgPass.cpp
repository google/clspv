// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <list>

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Builtins.h"
#include "SplatArgPass.h"

using namespace clspv;
using namespace llvm;

#define DEBUG_TYPE "splatarg"

// Programmatically convert mangled_name to vectorized version
std::string
clspv::SplatArgPass::getSplatName(const Builtins::FunctionInfo &func_info,
                                  const Builtins::ParamTypeInfo &param_info,
                                  bool three_params) {
  const char *type_code = "f";
  uint32_t index = Log2_32(param_info.byte_len);
  assert(index <= 3);
  const char *signed_int_type_tbl[] = {"c", "s", "i", "l"};
  const char *unsigned_int_type_tbl[] = {"h", "t", "j", "m"};
  const char *float_type_tbl[] = {"", "Dh", "f", "d"};
  switch (param_info.type_id) {
  case Type::IntegerTyID:
    type_code = param_info.is_signed ? signed_int_type_tbl[index]
                                     : unsigned_int_type_tbl[index];
    break;
  case Type::FloatTyID:
    if (index == 0)
      llvm_unreachable("Unsupported float type");
    type_code = float_type_tbl[index];
    break;
  default:
    llvm_unreachable("Unsupported type");
  }
  const auto &func_name = func_info.getName();
  return "_Z" + std::to_string(func_name.size()) + func_name + "Dv" +
         std::to_string(param_info.vector_size) + "_" + type_code +
         (three_params ? "S_S_" : "S_");
}

// Create replacement function once
Function *
clspv::SplatArgPass::getReplacementFunction(Function &F,
                                            const std::string &NewCallName) {
  Module *M = F.getParent();

  // Create new callee function type with vector type.
  Type *VectorType = F.getArg(0)->getType();
  SmallVector<Type *, 4> NewCalleeParamTys;
  for (auto ai = F.arg_begin(); ai != F.arg_end(); ++ai) {
    auto &Arg = *ai;
    if (Arg.getType()->isVectorTy()) {
      NewCalleeParamTys.push_back(Arg.getType());
    } else {
      NewCalleeParamTys.push_back(VectorType);
    }
  }

  FunctionType *NewCalleeTy =
      FunctionType::get(F.getReturnType(), NewCalleeParamTys, false);

  // Create new callee function declaration with new function type.
  Function *NewCallee = cast<Function>(
      M->getOrInsertFunction(NewCallName, NewCalleeTy).getCallee());
  NewCallee->setCallingConv(CallingConv::SPIR_FUNC);

  return NewCallee;
}

// Replace each callee to vectorized version
//  - also vectorize parameters
void clspv::SplatArgPass::replaceCall(Function *NewCallee, CallInst *Call) {
  Function *Callee = Call->getCalledFunction();
  FunctionType *CalleeTy = Callee->getFunctionType();
  VectorType *VTy = cast<VectorType>(Call->getType());

  // Change target of call instruction.
  Call->setCalledFunction(NewCallee);

  // Change operands of call instruction.
  IRBuilder<> Builder(Call);
  for (unsigned i = 0; i < CalleeTy->getNumParams(); i++) {
    if (!CalleeTy->getParamType(i)->isVectorTy()) {
      Value *NewArg =
          Builder.CreateVectorSplat(VTy->getElementCount().getKnownMinValue(),
                                    Call->getArgOperand(i), "arg_splat");
      Call->setArgOperand(i, NewArg);
      // We might have just replaced a scalar integer type with a vector type
      // and carried across some attributes which are illegal for vector types,
      // so drop those now.
      if(NewArg->getType()->getScalarType()->isIntegerTy()) {
        Call->removeParamAttr(i, Attribute::SExt);
        Call->removeParamAttr(i, Attribute::ZExt);
      }
    }
  }

  Call->setCallingConv(CallingConv::SPIR_FUNC);
}

PreservedAnalyses SplatArgPass::run(Module &M, ModuleAnalysisManager &) {
  std::list<std::pair<Function *, const Builtins::FunctionInfo &>> func_list;
  // Collect candidates
  for (auto &F : M.getFunctionList()) {
    // process only function declarations
    if (F.isDeclaration() && !F.use_empty()) {
      auto &func_info = Builtins::Lookup(&F);
      auto func_type = func_info.getType();
      switch (func_type) {
      case Builtins::kClamp:
      case Builtins::kMix:
      case Builtins::kMax:
      case Builtins::kFmax:
      case Builtins::kMin:
      case Builtins::kFmin: {
        auto &param_info = func_info.getParameter(0);
        uint32_t vec_size = param_info.vector_size;
        bool last_is_scalar = func_info.getLastParameter().vector_size == 0;
        if (vec_size != 0 && last_is_scalar) {
          func_list.push_back({&F, func_info});
        }
        break;
      }
      default:
        break;
      }
    }
  }
  // Replace with vectorized version
  for (auto FI : func_list) {
    auto *F = FI.first;
    auto &func_info = FI.second;
    auto func_type = func_info.getType();
    auto &param_info = func_info.getParameter(0);
    bool has_3_params =
        func_type == Builtins::kClamp || func_type == Builtins::kMix;
    std::string NewFName = getSplatName(func_info, param_info, has_3_params);
    Function *NewCallee = getReplacementFunction(*F, NewFName);
    // Replace the users of the function.
    while (!F->use_empty()) {
      User *U = F->user_back();
      replaceCall(NewCallee, dyn_cast<CallInst>(U));
    }
    // Remove if dead
    if (F->use_empty()) {
      F->eraseFromParent();
    }
  }
  PreservedAnalyses PA;
  return PA;
}
