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

#include "UndoSRetPass.h"

using namespace llvm;

PreservedAnalyses clspv::UndoSRetPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  LLVMContext &Context = M.getContext();

  SmallVector<Function *, 8> WorkList;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    if (F.getReturnType()->isVoidTy()) {
      for (Argument &Arg : F.args()) {
        // Check sret attribute.
        if (Arg.hasStructRetAttr()) {
          // We found a function that needs to be modified!
          WorkList.push_back(&F);
        }
      }
    }
  }

  for (Function *F : WorkList) {
    auto InsertPoint = F->getEntryBlock().getFirstNonPHIOrDbg();

    for (Argument &Arg : F->args()) {
      // Check sret attribute.
      if (Arg.hasStructRetAttr()) {
        Type *RetTy = Arg.getParamStructRetType();
        // Create alloca instruction for return value on function's entry
        // block.
        AllocaInst *RetVal =
            new AllocaInst(RetTy, 0, nullptr, "retval", InsertPoint);

        // Change arg's users with retval.
        Arg.replaceAllUsesWith(RetVal);

        // Create new function type with real return type instead of sret
        // argument.
        SmallVector<Type *, 8> NewFuncParamTys;
        for (const auto &Arg : F->args()) {
          // Ignore argument with sret attribute.
          if (Arg.hasStructRetAttr()) {
            continue;
          }
          NewFuncParamTys.push_back(Arg.getType());
        }
        FunctionType *NewFuncTy =
            FunctionType::get(RetTy, NewFuncParamTys, false);

        // Create new function.
        Function *NewFunc = Function::Create(NewFuncTy, F->getLinkage());
        NewFunc->takeName(F);

        // Insert the function just after the original to preserve the ordering
        // of the functions within the module.
        auto &FunctionList = M.getFunctionList();

        for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
             Iter != IterEnd; ++Iter) {
          // If we find our functions place in the iterator.
          if (&*Iter == F) {
            FunctionList.insertAfter(Iter, NewFunc);
            break;
          }
        }

        // Map original function's arguments to new function's arguments.
        ValueToValueMapTy VMap;
        auto NewArg = NewFunc->arg_begin();
        for (auto &Arg : F->args()) {
          if (Arg.hasStructRetAttr()) {
            VMap[&Arg] = UndefValue::get(Arg.getType());
            continue;
          }
          NewArg->setName(Arg.getName());
          VMap[&Arg] = &*(NewArg++);
        }

        // Clone original function into new function.
        SmallVector<ReturnInst *, 4> RetInsts;
        CloneFunctionInto(NewFunc, F, VMap,
                          CloneFunctionChangeType::LocalChangesOnly, RetInsts);

        // Change return instruction like this.
        //
        // %retv = load %retval;
        // ret %retv;
        for (auto Ret : RetInsts) {
          LoadInst *LD = new LoadInst(RetTy, VMap[RetVal], "", Ret);
          ReturnInst *NewRet = ReturnInst::Create(Context, LD, Ret);
          Ret->replaceAllUsesWith(NewRet);
          Ret->eraseFromParent();
        }

        SmallVector<User *, 8> ToRemoves;

        // Update caller site.
        for (auto User : F->users()) {
          if (CallInst *Call = dyn_cast<CallInst>(User)) {
            // Create new call instruction for new function without sret.
            SmallVector<Value *, 8> NewArgs(Call->arg_begin() + 1,
                                            Call->arg_end());
            CallInst *NewCall = CallInst::Create(NewFunc, NewArgs, "", Call);

            NewCall->takeName(Call);
            NewCall->setCallingConv(Call->getCallingConv());
            NewCall->setDebugLoc(Call->getDebugLoc());

            // Copy attributes over, but skip the attributes for the first
            // parameter since it is removed.  In particular, the old
            // first parameter has a StructRet attribute that should disappear.
            auto attrs(Call->getAttributes());
            AttributeList new_attrs(
                AttributeList::get(Context, AttributeList::FunctionIndex,
                                   AttrBuilder(Context, attrs.getFnAttrs())));
            new_attrs = new_attrs.addAttributesAtIndex(
                Context, AttributeList::ReturnIndex,
                AttrBuilder(Context, attrs.getRetAttrs()));
            for (unsigned i = 1; i < Call->arg_size(); i++) {
              new_attrs = new_attrs.addParamAttributes(
                  Context, i - 1, AttrBuilder(Context, attrs.getParamAttrs(i)));
            }
            NewCall->setAttributes(new_attrs);

            // Store the value we returned from our function call into the
            // the orignal destination.
            new StoreInst(NewCall, Call->getArgOperand(0), Call);
          }

          ToRemoves.push_back(User);
        }

        for (User *U : ToRemoves) {
          U->dropAllReferences();
          if (Instruction *I = dyn_cast<Instruction>(U)) {
            I->eraseFromParent();
          }
        }

        // We found the argument that had sret, so we are done with this
        // function!
        break;
      }
    }

    // Delete original functions with sret argument.
    F->dropAllReferences();
    F->eraseFromParent();
  }

  return PA;
}
