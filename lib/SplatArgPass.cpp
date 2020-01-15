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

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "splatarg"

namespace {
struct SplatArgPass : public ModulePass {
  static char ID;
  SplatArgPass() : ModulePass(ID) {}

  const char *getSplatName(StringRef Name);
  bool runOnModule(Module &M) override;
};
} // namespace

char SplatArgPass::ID = 0;
INITIALIZE_PASS(SplatArgPass, "SplatArg", "Splat Argument Pass", false, false)

namespace clspv {
llvm::ModulePass *createSplatArgPass() { return new SplatArgPass(); }
} // namespace clspv

const char *SplatArgPass::getSplatName(StringRef Name) {
  if (Name.equals("_Z5clampDv2_iii")) {
    return "_Z5clampDv2_iS_S_";
  } else if (Name.equals("_Z5clampDv3_iii")) {
    return "_Z5clampDv3_iS_S_";
  } else if (Name.equals("_Z5clampDv4_iii")) {
    return "_Z5clampDv4_iS_S_";
  } else if (Name.equals("_Z5clampDv2_jjj")) {
    return "_Z5clampDv2_jS_S_";
  } else if (Name.equals("_Z5clampDv3_jjj")) {
    return "_Z5clampDv3_jS_S_";
  } else if (Name.equals("_Z5clampDv4_jjj")) {
    return "_Z5clampDv4_jS_S_";
  } else if (Name.equals("_Z5clampDv2_fff")) {
    return "_Z5clampDv2_fS_S_";
  } else if (Name.equals("_Z5clampDv3_fff")) {
    return "_Z5clampDv3_fS_S_";
  } else if (Name.equals("_Z5clampDv4_fff")) {
    return "_Z5clampDv4_fS_S_";
  } else if (Name.equals("_Z5clampDv2_DhDhDh")) {
    return "_Z5clampDv2_DhS_S_";
  } else if (Name.equals("_Z5clampDv3_DhDhDh")) {
    return "_Z5clampDv3_DhS_S_";
  } else if (Name.equals("_Z5clampDv4_DhDhDh")) {
    return "_Z5clampDv4_DhS_S_";

  } else if (Name.equals("_Z3maxDv2_ii")) {
    return "_Z3maxDv2_iS_";
  } else if (Name.equals("_Z3maxDv3_ii")) {
    return "_Z3maxDv3_iS_";
  } else if (Name.equals("_Z3maxDv4_ii")) {
    return "_Z3maxDv4_iS_";
  } else if (Name.equals("_Z3maxDv2_jj")) {
    return "_Z3maxDv2_jS_";
  } else if (Name.equals("_Z3maxDv3_jj")) {
    return "_Z3maxDv3_jS_";
  } else if (Name.equals("_Z3maxDv4_jj")) {
    return "_Z3maxDv4_jS_";
  } else if (Name.equals("_Z3maxDv2_ff")) {
    return "_Z3maxDv2_fS_";
  } else if (Name.equals("_Z3maxDv3_ff")) {
    return "_Z3maxDv3_fS_";
  } else if (Name.equals("_Z3maxDv4_ff")) {
    return "_Z3maxDv4_fS_";
  } else if (Name.equals("_Z3maxDv2_DhDh")) {
    return "_Z3maxDv2_DhS_";
  } else if (Name.equals("_Z3maxDv3_DhDh")) {
    return "_Z3maxDv3_DhS_";
  } else if (Name.equals("_Z3maxDv4_DhDh")) {
    return "_Z3maxDv4_DhS_";
  } else if (Name.equals("_Z4fmaxDv2_ff")) {
    return "_Z4fmaxDv2_fS_";
  } else if (Name.equals("_Z4fmaxDv3_ff")) {
    return "_Z4fmaxDv3_fS_";
  } else if (Name.equals("_Z4fmaxDv4_ff")) {
    return "_Z4fmaxDv4_fS_";
  } else if (Name.equals("_Z4fmaxDv2_DhDh")) {
    return "_Z4fmaxDv2_DhS_";
  } else if (Name.equals("_Z4fmaxDv3_DhDh")) {
    return "_Z4fmaxDv3_DhS_";
  } else if (Name.equals("_Z4fmaxDv4_DhDh")) {
    return "_Z4fmaxDv4_DhS_";

  } else if (Name.equals("_Z3minDv2_ii")) {
    return "_Z3minDv2_iS_";
  } else if (Name.equals("_Z3minDv3_ii")) {
    return "_Z3minDv3_iS_";
  } else if (Name.equals("_Z3minDv4_ii")) {
    return "_Z3minDv4_iS_";
  } else if (Name.equals("_Z3minDv2_jj")) {
    return "_Z3minDv2_jS_";
  } else if (Name.equals("_Z3minDv3_jj")) {
    return "_Z3minDv3_jS_";
  } else if (Name.equals("_Z3minDv4_jj")) {
    return "_Z3minDv4_jS_";
  } else if (Name.equals("_Z3minDv2_ff")) {
    return "_Z3minDv2_fS_";
  } else if (Name.equals("_Z3minDv3_ff")) {
    return "_Z3minDv3_fS_";
  } else if (Name.equals("_Z3minDv4_ff")) {
    return "_Z3minDv4_fS_";
  } else if (Name.equals("_Z3minDv2_DhDh")) {
    return "_Z3minDv2_DhS_";
  } else if (Name.equals("_Z3minDv3_DhDh")) {
    return "_Z3minDv3_DhS_";
  } else if (Name.equals("_Z3minDv4_DhDh")) {
    return "_Z3minDv4_DhS_";
  } else if (Name.equals("_Z4fminDv2_ff")) {
    return "_Z4fminDv2_fS_";
  } else if (Name.equals("_Z4fminDv3_ff")) {
    return "_Z4fminDv3_fS_";
  } else if (Name.equals("_Z4fminDv4_ff")) {
    return "_Z4fminDv4_fS_";
  } else if (Name.equals("_Z4fminDv2_DhDh")) {
    return "_Z4fminDv2_DhS_";
  } else if (Name.equals("_Z4fminDv3_DhDh")) {
    return "_Z4fminDv3_DhS_";
  } else if (Name.equals("_Z4fminDv4_DhDh")) {
    return "_Z4fminDv4_DhS_";

  } else if (Name.equals("_Z3mixDv2_fS_f")) {
    return "_Z3mixDv2_fS_S_";
  } else if (Name.equals("_Z3mixDv3_fS_f")) {
    return "_Z3mixDv3_fS_S_";
  } else if (Name.equals("_Z3mixDv4_fS_f")) {
    return "_Z3mixDv4_fS_S_";
  } else if (Name.equals("_Z3mixDv2_DhS_Dh")) {
    return "_Z3mixDv2_DhS_S_";
  } else if (Name.equals("_Z3mixDv3_DhS_Dh")) {
    return "_Z3mixDv3_DhS_S_";
  } else if (Name.equals("_Z3mixDv4_DhS_Dh")) {
    return "_Z3mixDv4_DhS_S_";
  }

  return nullptr;
}

bool SplatArgPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<CallInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (CallInst *Call = dyn_cast<CallInst>(&I)) {
          Function *Callee = Call->getCalledFunction();
          if (Callee) {
            // If min/max/mix/clamp function call has scalar type argument, we
            // need to splat the scalar type one to vector type.
            if (getSplatName(Callee->getName())) {
              WorkList.push_back(Call);
              Changed = true;
            }
          }
        }
      }
    }
  }

  for (CallInst *Call : WorkList) {
    Function *Callee = Call->getCalledFunction();
    FunctionType *CalleeTy = Callee->getFunctionType();

    // Create new callee function type with vector type.
    SmallVector<Type *, 4> NewCalleeParamTys;
    for (const auto &Arg : Callee->args()) {
      if (Arg.getType()->isVectorTy()) {
        NewCalleeParamTys.push_back(Arg.getType());
      } else {
        NewCalleeParamTys.push_back(Call->getType());
      }
    }

    FunctionType *NewCalleeTy =
        FunctionType::get(Call->getType(), NewCalleeParamTys, false);

    // Create new callee function declaration with new function type.
    StringRef NewCallName(getSplatName(Callee->getName()));
    Function *NewCallee = cast<Function>(
        M.getOrInsertFunction(NewCallName, NewCalleeTy).getCallee());
    NewCallee->setCallingConv(CallingConv::SPIR_FUNC);

    // Change target of call instruction.
    Call->setCalledFunction(NewCalleeTy, NewCallee);

    // Change operands of call instruction.
    IRBuilder<> Builder(Call);
    for (unsigned i = 0; i < CalleeTy->getNumParams(); i++) {
      if (!CalleeTy->getParamType(i)->isVectorTy()) {
        VectorType *VTy = cast<VectorType>(Call->getType());
        Value *NewArg = Builder.CreateVectorSplat(
            VTy->getNumElements(), Call->getArgOperand(i), "arg_splat");
        Call->setArgOperand(i, NewArg);
      }
    }

    Call->setCallingConv(CallingConv::SPIR_FUNC);
  }

  return Changed;
}
