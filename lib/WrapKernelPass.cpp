#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "WrapKernelPass.h"

using namespace llvm;

void clspv::WrapKernelPass::runOnFunction(Module &M, llvm::Function *F) {
  SmallVector<Type *, 8> NewParamTypes;
  for (auto &Arg : F->args()) {
    NewParamTypes.push_back(Arg.getType());
  }

  auto *NewFuncTy = FunctionType::get(F->getReturnType(), NewParamTypes, false);

  auto NewFunc = Function::Create(NewFuncTy, F->getLinkage());
  NewFunc->setName(F->getName().str());
  F->setName(F->getName().str() + ".inner");
  NewFunc->setCallingConv(F->getCallingConv());
  NewFunc->copyAttributesFrom(F);

  for (auto &arg : F->args()) {
    NewFunc->getArg(arg.getArgNo())->setName(arg.getName());
  }

  F->setCallingConv(CallingConv::SPIR_FUNC);
  for (auto &U : F->uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      CI->setCallingConv(CallingConv::SPIR_FUNC);
    }
  }
  NewFunc->copyMetadata(F, 0);
  F->clearMetadata();

  IRBuilder<> Builder(BasicBlock::Create(M.getContext(), "entry", NewFunc));

  // Copy args from src func to new func
  // Get the arguments of the source function.
  SmallVector<Value *, 8> WrappedArgs;
  for (unsigned ArgNum = 0; ArgNum < F->arg_size(); ArgNum++) {
    auto *NewArg = NewFunc->getArg(ArgNum);
    WrappedArgs.push_back(NewArg);
  }

  auto *CallInst = Builder.CreateCall(F, WrappedArgs);
  CallInst->setCallingConv(CallingConv::SPIR_FUNC);
  Builder.CreateRetVoid();

  // Insert the function after the original, to preserve ordering
  // in the module as much as possible.
  auto &FunctionList = M.getFunctionList();
  for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
       Iter != IterEnd; ++Iter) {
    if (&*Iter == F) {
      FunctionList.insertAfter(Iter, NewFunc);
      break;
    }
  }
}

bool isCalled(llvm::Function &F) {
  for (auto &U : F.uses()) {
    if (dyn_cast<CallInst>(U.getUser())) {
      return true;
    }
  }
  return false;
}

PreservedAnalyses clspv::WrapKernelPass::run(llvm::Module &M,
                                             ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  SmallVector<Function *, 8> FuncsToWrap;

  for (auto &F : M.functions()) {
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL && isCalled(F)) {
      FuncsToWrap.emplace_back(&F);
    }
  }
  for (unsigned i = 0; i < FuncsToWrap.size(); ++i) {
    runOnFunction(M, FuncsToWrap[i]);
  }
  return PA;
}
