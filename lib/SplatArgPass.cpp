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
#include "Passes.h"

using namespace clspv;
using namespace llvm;

#define DEBUG_TYPE "splatarg"

namespace {

struct SplatArgPass : public ModulePass {
  static char ID;
  SplatArgPass() : ModulePass(ID) {}

  std::string getSplatName(const Builtins::FunctionInfo &func_info,
                           const Builtins::ParamTypeInfo &param_info,
                           bool three_params);
  Function *getReplacementFunction(Function &F, const std::string &NewCallName);
  void replaceCall(Function *NewCallee, CallInst *Call);

  bool runOnModule(Module &M) override;
};

} // namespace

char SplatArgPass::ID = 0;
INITIALIZE_PASS(SplatArgPass, "SplatArg", "Splat Argument Pass", false, false)

namespace clspv {
llvm::ModulePass *createSplatArgPass() { return new SplatArgPass(); }
} // namespace clspv

namespace {
int log2i(int val) {
  if (val <= 0)
    return -1;
  int log2 = 0;
  while (val >>= 1)
    log2++;
  return log2;
}
} // namespace

// Programmatically convert mangled_name to vectorized version
std::string
SplatArgPass::getSplatName(const Builtins::FunctionInfo &func_info,
                           const Builtins::ParamTypeInfo &param_info,
                           bool three_params) {
  const char *type_code = "f";
  int index = log2i(param_info.byte_len);
  assert(index >= 0 && index <= 3);
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
Function *SplatArgPass::getReplacementFunction(Function &F,
                                               const std::string &NewCallName) {
  Module *M = F.getParent();
  FunctionType *CalleeTy = F.getFunctionType();

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
void SplatArgPass::replaceCall(Function *NewCallee, CallInst *Call) {
  Function *Callee = Call->getCalledFunction();
  FunctionType *CalleeTy = Callee->getFunctionType();
  VectorType *VTy = cast<VectorType>(Call->getType());

  // Change target of call instruction.
  Call->setCalledFunction(NewCallee);

  // Change operands of call instruction.
  IRBuilder<> Builder(Call);
  for (unsigned i = 0; i < CalleeTy->getNumParams(); i++) {
    if (!CalleeTy->getParamType(i)->isVectorTy()) {
      Value *NewArg = Builder.CreateVectorSplat(
          VTy->getNumElements(), Call->getArgOperand(i), "arg_splat");
      Call->setArgOperand(i, NewArg);
    }
  }

  Call->setCallingConv(CallingConv::SPIR_FUNC);
}

bool SplatArgPass::runOnModule(Module &M) {
  std::list<Function *> func_list;
  for (auto &F : M) {
    // process only function declarations
    if (F.empty() && !F.use_empty()) {
      auto &func_info = Builtins::Lookup(&F);
      bool has_3_params = false;
      switch (func_info.getType()) {
      case Builtins::kClamp:
      case Builtins::kMix:
        has_3_params = true;
      case Builtins::kMax:
      case Builtins::kFmax:
      case Builtins::kMin:
      case Builtins::kFmin: {
        auto &param_info = func_info.getParameter(0);
        uint32_t vec_size = param_info.vector_size;
        bool last_is_scalar = func_info.getLastParameter().vector_size == 0;
        if (vec_size != 0 && last_is_scalar) {
          std::string NewFName =
              getSplatName(func_info, param_info, has_3_params);
          Function *NewCallee = getReplacementFunction(F, NewFName);
          // Replace the users of the function.
          for (User *U : F.users()) {
            replaceCall(NewCallee, dyn_cast<CallInst>(U));
          }
          func_list.push_front(&F);
        }
        break;
      }
      default:
        break;
      }
    }
  }
  if (func_list.size() != 0) {
    // remove dead
    for (auto *F : func_list) {
      if (F->use_empty()) {
        F->eraseFromParent();
      }
    }
    return true;
  }
  return false;
}
