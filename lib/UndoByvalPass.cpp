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

#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "undobyval"

namespace {
struct UndoByvalPass : public ModulePass {
  static char ID;
  UndoByvalPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};
} // namespace

char UndoByvalPass::ID = 0;
INITIALIZE_PASS(UndoByvalPass, "UndoByval", "Undo Byval Pass", false, false)

namespace clspv {
llvm::ModulePass *createUndoByvalPass() { return new UndoByvalPass(); }
} // namespace clspv

bool UndoByvalPass::runOnModule(Module &M) {
  bool Changed = false;

  SmallVector<Function *, 8> WorkList;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    SmallVector<Type *, 8> NewFuncParamTys;
    SmallVector<Argument *, 8> ByValList;
    for (Argument &Arg : F.args()) {
      // Check byval attribute and build new function's parameter type.
      if (Arg.hasByValAttr()) {
        WorkList.push_back(&F);
        Changed = true;
        break;
      }
    }
  }

  for (Function *F : WorkList) {
    SmallVector<Type *, 8> NewFuncParamTys;
    SmallVector<Argument *, 8> ByValList;
    for (Argument &Arg : F->args()) {
      // Check byval attribute and build new function's parameter type.
      if (Arg.hasByValAttr()) {
        PointerType *PTy = cast<PointerType>(Arg.getType());
        Type *ArgTy = PTy->getElementType();
        NewFuncParamTys.push_back(ArgTy);

        ByValList.push_back(&Arg);
      } else {
        NewFuncParamTys.push_back(Arg.getType());
      }
    }

    if (!ByValList.empty()) {
      FunctionType *NewFuncTy =
          FunctionType::get(F->getReturnType(), NewFuncParamTys, false);

      // Create new function.
      Function *NewFunc = Function::Create(NewFuncTy, F->getLinkage());
      NewFunc->takeName(F);

      // Insert the function just after the original to preserve the ordering of
      // the functions within the module.
      auto &FunctionList = M.getFunctionList();

      for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
           Iter != IterEnd; ++Iter) {
        // If we find our functions place in the iterator.
        if (&*Iter == F) {
          FunctionList.insertAfter(Iter, NewFunc);
          break;
        }
      }

      // Create alloca instruction for byval argument on function's entry block.
      auto InsertPoint = F->getEntryBlock().getFirstNonPHIOrDbg();
      ValueToValueMapTy ArgVMap;
      for (Argument *Arg : ByValList) {
        PointerType *PTy = cast<PointerType>(Arg->getType());
        Type *ArgTy = PTy->getElementType();
        AllocaInst *ArgAddr = new AllocaInst(
            ArgTy, 0, nullptr, Arg->getName() + ".addr", InsertPoint);

        // Change arg's users with ArgAddr.
        Arg->replaceAllUsesWith(ArgAddr);
        ArgVMap[Arg] = ArgAddr;
      }

      // Map original function's arguments to new function's arguments.
      ValueToValueMapTy VMap;
      auto NewArg = NewFunc->arg_begin();
      for (auto &Arg : F->args()) {
        NewArg->setName(Arg.getName());
        VMap[&Arg] = &*(NewArg++);
      }

      // Clone original function into new function.
      SmallVector<ReturnInst *, 4> RetInsts;
      CloneFunctionInto(NewFunc, F, VMap, false, RetInsts);

      // Store new arguments to their alloca space.
      for (Argument *Arg : ByValList) {
        Instruction *Alloca = cast<Instruction>(ArgVMap[Arg]);
        Instruction *NewAlloca = cast<Instruction>(VMap[Alloca]);
        Argument *NewArg = cast<Argument>(VMap[Arg]);
        new StoreInst(NewArg, NewAlloca,
                      &*std::next(BasicBlock::iterator(*NewAlloca)));

        // Remove byval attribute.
        NewArg->removeAttr(Attribute::ByVal);
        NewArg->takeName(Arg);
      }

      SmallVector<User *, 8> Users(F->user_begin(), F->user_end());

      // Update caller site.
      for (auto User : Users) {
        // Create new call instruction for new function without byval.
        CallInst *Call = cast<CallInst>(User);
        CallSite CS(Call);

        SmallVector<Value *, 8> Args;

        for (unsigned i = 0; i < CS.arg_size(); i++) {
          auto Arg = CS.getArgument(i);

          if (CS.isByValArgument(i)) {
            Args.push_back(new LoadInst(Arg, "", Call));
          } else {
            Args.push_back(Arg);
          }
        }

        CallInst *NewCall = CallInst::Create(NewFunc, Args, "", Call);
        NewCall->setCallingConv(NewFunc->getCallingConv());

        Call->replaceAllUsesWith(NewCall);
        Call->eraseFromParent();
      }

      F->eraseFromParent();
    }
  }

  return Changed;
}
