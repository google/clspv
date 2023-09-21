#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Pass.h"

#include "WrapKernelPass.h"

#include "Constants.h"

using namespace llvm;

void clspv::WrapKernelPass::runOnFunction(Module &M,llvm::Function &F) {
    F.removeFnAttr("kernel");
    // Create a new function to wrap the kernel function
    SmallVector<Type *, 8> NewParamTypes;
    for (auto &Arg : F.args()) {
        NewParamTypes.push_back(Arg.getType());
    }
    
    auto *NewFuncTy =
        FunctionType::get(F.getReturnType(), NewParamTypes, false);

    auto NewFunc = Function::Create(NewFuncTy, F.getLinkage());
    F.setName(NewFunc->getName().str() + ".inner");
    NewFunc->setCallingConv(F.getCallingConv());

    NewFunc->copyAttributesFrom(&F);

    F.setCallingConv(CallingConv::SPIR_FUNC);
    for (auto &U : F.uses()) {
      if (auto CI = dyn_cast<CallInst>(U.getUser())) {
        CI->setCallingConv(CallingConv::SPIR_FUNC);
      }
    }
    NewFunc->copyMetadata(&F, 0);

    IRBuilder<> Builder(BasicBlock::Create(M.getContext(), "entry", NewFunc));

    // Copy args from src func to new func
    // Get the arguments of the source function.
        SmallVector<Value *, 8> WrappedArgs;
    for (unsigned ArgNum = 0; ArgNum < F.arg_size(); ArgNum++) {
      auto *OriginalArgTy = F.getArg(ArgNum)->getType();
      auto *NewArg = NewFunc->getArg(ArgNum);
      if (OriginalArgTy != NewArg->getType()) {
        auto *IntAsPtr = Builder.CreateIntToPtr(NewArg, OriginalArgTy);
        WrappedArgs.push_back(IntAsPtr);

        // We can't attach metadata to arguments directly, so add to this
        // use instead. Subsequent passes can determine whether the POD
        // contains a pointer by checking the users of the argument.
        if (auto *InstAsPtrInstr = dyn_cast<Instruction>(IntAsPtr)) {
          auto *EmptyMD = MDNode::get(F.getContext(), {});
          InstAsPtrInstr->setMetadata(clspv::PointerPodArgMetadataName(),
                                      EmptyMD);
          continue;
        }
        llvm_unreachable("IntToPtr is not an instruction!");
      }

      WrappedArgs.push_back(NewArg);
    }

    auto *CallInst = Builder.CreateCall(&F, WrappedArgs);
    CallInst->setCallingConv(CallingConv::SPIR_FUNC);
    Builder.CreateRetVoid();

    // Insert the function after the original, to preserve ordering
    // in the module as much as possible.
    auto &FunctionList = M.getFunctionList();
    for (auto Iter = FunctionList.begin(), IterEnd = FunctionList.end();
         Iter != IterEnd; ++Iter) {
      if (&*Iter == &F) {
        FunctionList.insertAfter(Iter, NewFunc);
        break;
      }
    }

    // Inline the function into the wrapper
    InlineFunctionInfo info;
    InlineFunction(*CallInst, info);
}

PreservedAnalyses clspv::WrapKernelPass::run(llvm::Module &M,
                                                     ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  SmallVector<Function *, 8> FuncsToDelete;
  bool nextIsWrap = false;
  for (auto &F : M.functions()) {
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL && !nextIsWrap) {
        runOnFunction(M,F);
        nextIsWrap = true;
    } else {
        nextIsWrap = false;
    }
  }
  
  return PA;
}