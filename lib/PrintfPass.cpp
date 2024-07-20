// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "clspv/Option.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

#include "Constants.h"
#include "PushConstant.h"
#include "Types.h"

#include "PrintfPass.h"

using namespace llvm;

std::optional<std::string> clspv::PrintfPass::GetStringLiteral(Value *Val) {
  GlobalVariable *GlobalVal = nullptr;
  Instruction *ConstExprEquivInstr = nullptr;
  // If opaque pointers aren't enabled, the global may be hidden behind a
  // GEP constexpr
  if (auto *CE = dyn_cast<ConstantExpr>(Val)) {
    ConstExprEquivInstr = CE->getAsInstruction();
    if (auto *GEPInstr = dyn_cast<GetElementPtrInst>(ConstExprEquivInstr)) {
      auto *Ptr = GEPInstr->getPointerOperand();
      if (auto *GV = dyn_cast<GlobalVariable>(Ptr)) {
        GlobalVal = GV;
      }
    }
  }

  // If there wasn't a GEP then the global will be used directly instead
  if (!GlobalVal) {
    GlobalVal = dyn_cast<GlobalVariable>(Val);
  }

  if (GlobalVal) {
    auto *Initializer = GlobalVal->getInitializer();
    if (auto *InitArray = dyn_cast<ConstantDataArray>(Initializer)) {
      if (InitArray->isString()) {
        if (ConstExprEquivInstr)
          ConstExprEquivInstr->deleteValue();
        return InitArray->getAsString().str();
      }
    }
    // The empty C string, and strings of null chars, are
    // constant-aggregate-zero.
    if (auto *InitArray = dyn_cast<ConstantAggregateZero>(Initializer)) {
      if (auto *arrTy = dyn_cast<ArrayType>(InitArray->getType())) {
        if (arrTy->getElementType()->isIntegerTy(8)) {
          return std::string(arrTy->getNumElements(), '\0');
        }
      }
    }
  }

  // Not a string.
  return {};
}

unsigned clspv::PrintfPass::GetPrintfStoreSize(const DataLayout &DL, Type *Ty) {
  return std::max(4ul, (unsigned long)DL.getTypeStoreSize(Ty).getFixedValue());
}

void clspv::PrintfPass::DefinePrintfInstance(Module &M, CallInst *CI,
                                             unsigned PrintfID) {
  // Drop the format string from the arguments
  SmallVector<Value *, 8> NewArgs;
  SmallVector<Type *, 8> NewArgTypes;
  unsigned ArgsSize = 0;
  auto ArgIter = CI->arg_begin();
  ArgIter++;
  for (; ArgIter != CI->arg_end(); ArgIter++) {
    NewArgs.push_back(*ArgIter);
    NewArgTypes.push_back((*ArgIter)->getType());
    ArgsSize += GetPrintfStoreSize(M.getDataLayout(), (*ArgIter)->getType());
  }

  // Create a new function with the new arguments, update the CallInst
  std::string FuncName = "__clspv.printf." + std::to_string(PrintfID);
  auto &Ctx = M.getContext();
  auto Int32Ty = IntegerType::getInt32Ty(Ctx);
  auto Int64Ty = IntegerType::getInt64Ty(Ctx);
  auto *FuncTy = FunctionType::get(Int32Ty, NewArgTypes, false);
  auto FuncCallee = M.getOrInsertFunction(FuncName, FuncTy);
  auto *Func = dyn_cast<Function>(FuncCallee.getCallee());
  assert(Func);
  Func->setIsNewDbgInfoFormat(true);

  auto *NewCI = CallInst::Create(Func, NewArgs, "", CI);
  CI->replaceAllUsesWith(NewCI);
  CI->eraseFromParent();

  // Define the new function
  unsigned AllocSize = ArgsSize + 4;
  unsigned AllocSizeInts = AllocSize / 4;
  auto *ConstantZero = ConstantInt::get(Int32Ty, 0);
  auto *ConstantOne = ConstantInt::get(Int32Ty, 1);
  auto *ConstantNegOne = ConstantInt::get(Int32Ty, -1);
  auto *ConstantPrintfID = ConstantInt::get(Int32Ty, PrintfID);
  auto *ConstantAllocSize = ConstantInt::get(Int32Ty, AllocSizeInts);
  auto *ConstantBuffSize =
      ConstantInt::get(Int32Ty, clspv::Option::PrintfBufferSize() / 4);
  const auto &DL = M.getDataLayout();

  auto *EntryBB = BasicBlock::Create(Ctx, "entry", Func);
  auto *CopyArgsBB = BasicBlock::Create(Ctx, "copy_args", Func);
  auto *CopyPrintfIdBB = BasicBlock::Create(Ctx, "copy_printf_id", Func);
  auto *TestPrintfIdBB = BasicBlock::Create(Ctx, "test_printf_id", Func);
  auto *ExitBB = BasicBlock::Create(Ctx, "exit", Func);
  IRBuilder<> IR{EntryBB};

  auto *BufferArrayTy = ArrayType::get(Int32Ty, 0);
  auto *BufferTy = StructType::get(BufferArrayTy);
  Value *Buffer;
  if (clspv::Option::PhysicalStorageBuffers()) {
    auto *BufferAddressPtr = clspv::GetPushConstantPointer(
        EntryBB, clspv::PushConstant::PrintfBufferPointer);
    auto *BufferAddress = IR.CreateLoad(IR.getInt64Ty(), BufferAddressPtr);
    Buffer = IR.CreateIntToPtr(
        BufferAddress, PointerType::get(BufferTy, clspv::AddressSpace::Global));
  } else {
    Buffer = M.getNamedGlobal(clspv::PrintfBufferVariableName());
  }

  // Try to reserve a block of the printf buffer. The first i32 of the buffer
  // stores the offset of the next available memory
  auto *GEP = GetElementPtrInst::Create(
      BufferTy, Buffer, {ConstantZero, ConstantZero, ConstantZero});
  IR.Insert(GEP);
  Value *Offset =
      IR.CreateAtomicRMW(AtomicRMWInst::Add, GEP, ConstantAllocSize,
                         MaybeAlign(4), AtomicOrdering::SequentiallyConsistent);
  Offset = IR.CreateAdd(Offset, ConstantOne);
  Value *EndOffset = IR.CreateAdd(Offset, ConstantAllocSize);
  Value *ArgsOffset = IR.CreateAdd(Offset, ConstantOne);

  // Now check that we have enough space to store the printf id and the args
  auto *ICmp = IR.CreateICmpULE(EndOffset, ConstantBuffSize);
  IR.CreateCondBr(ICmp, CopyArgsBB, TestPrintfIdBB);

  //
  // Copy Printf ID
  //
  IR.SetInsertPoint(CopyPrintfIdBB);
  auto *ReturnValue = IR.CreatePHI(Int32Ty, 2);
  ReturnValue->addIncoming(ConstantOne, CopyArgsBB);
  ReturnValue->addIncoming(ConstantNegOne, TestPrintfIdBB);
  // Store the printf ID
  auto *PrintfIDGEP = GetElementPtrInst::Create(
      BufferTy, Buffer, {ConstantZero, ConstantZero, Offset});
  IR.Insert(PrintfIDGEP);
  IR.CreateStore(ConstantPrintfID, PrintfIDGEP);
  IR.CreateBr(ExitBB);

  //
  // Test Printf Id
  //
  IR.SetInsertPoint(TestPrintfIdBB);
  ICmp = IR.CreateICmpULE(ArgsOffset, ConstantBuffSize);
  IR.CreateCondBr(ICmp, CopyPrintfIdBB, ExitBB);

  //
  // Copy Args
  //
  IR.SetInsertPoint(CopyArgsBB);

  // Store the value of each argument
  for (size_t i = 0; i < Func->arg_size(); i++) {
    Value *Arg = Func->getArg(i);
    // Everything has to go into an i32 buffer, bitcast floats to ints if needed
    if (Arg->getType()->isFloatingPointTy()) {
      auto *IntTy =
          IntegerType::get(Ctx, Arg->getType()->getScalarSizeInBits());
      Arg = IR.CreateBitCast(Arg, IntTy);
    } else if (Arg->getType()->isPointerTy()) {
      auto IntTy = clspv::PointersAre64Bit(M) ? Int64Ty : Int32Ty;
      Arg = IR.CreatePtrToInt(Arg, IntTy);
    }

    // Vectors that are smaller than 4 bytes need padded to reach this size
    if (Arg->getType()->isVectorTy() &&
        Arg->getType()->getScalarSizeInBits() < 32) {
      auto VecStoreSize = DL.getTypeStoreSizeInBits(Arg->getType());
      auto *EquivIntTy = IntegerType::get(Ctx, VecStoreSize);
      Arg = IR.CreateBitCast(Arg, EquivIntTy);

      if (VecStoreSize < 32)
        Arg = IR.CreateZExt(Arg, Int32Ty);
    }

    Value *ArgStoreGEP = GetElementPtrInst::Create(
        BufferTy, Buffer, {ConstantZero, ConstantZero, ArgsOffset});
    IR.Insert(ArgStoreGEP);

    // If the integer is now anything but i32, bitcast the pointer
    if (Arg->getType() != Int32Ty) {
      auto *NewTy =
          PointerType::get(Arg->getType(), clspv::AddressSpace::Global);
      ArgStoreGEP = IR.CreatePointerCast(ArgStoreGEP, NewTy);
    }

    IR.CreateStore(Arg, ArgStoreGEP);
    auto *StoreSize =
        ConstantInt::get(Int32Ty, DL.getTypeStoreSize(Arg->getType()) / 4);
    if (i + 1 < Func->arg_size()) {
      ArgsOffset = IR.CreateAdd(ArgsOffset, StoreSize);
    }
  }
  IR.CreateBr(CopyPrintfIdBB);

  // Return 0 on success, otherwise -1
  IR.SetInsertPoint(ExitBB);
  auto *ReturnCodePhi = IR.CreatePHI(Int32Ty, 2);
  ReturnCodePhi->addIncoming(ReturnValue, CopyPrintfIdBB);
  ReturnCodePhi->addIncoming(ConstantNegOne, TestPrintfIdBB);
  IR.CreateRet(ReturnCodePhi);
}

// Create a metadata node for the given printf ID, format string and arguments
MDNode *CreatePrintfArgsMetadata(Module &M, ArrayRef<Metadata *> ArgMDs,
                                 const std::string &String, unsigned int ID) {
  auto *ArgsTupleMD = MDTuple::get(M.getContext(), ArgMDs);
  auto *PrintfStringMD = MDString::get(M.getContext(), String);
  auto *PrintfIDConst = ConstantInt::get(Type::getInt32Ty(M.getContext()), ID);
  auto *PrintfIDMD = ConstantAsMetadata::get(PrintfIDConst);
  return MDNode::get(M.getContext(), {PrintfIDMD, PrintfStringMD, ArgsTupleMD});
}

PreservedAnalyses clspv::PrintfPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  if (!M.getFunction("printf"))
    return PA;

  auto *PrintfMDs = M.getOrInsertNamedMetadata(PrintfMetadataName());

  // Create the printf buffer
  auto &Ctx = M.getContext();
  auto *Int32Ty = IntegerType::getInt32Ty(Ctx);
  auto *BufferTy = ArrayType::get(Int32Ty, 0);
  auto *PrintfBufferTy = StructType::get(BufferTy);
  if (!clspv::Option::PhysicalStorageBuffers()) {
    M.getOrInsertGlobal(PrintfBufferVariableName(), PrintfBufferTy, [&] {
      GlobalVariable *GV = new GlobalVariable(
          M, PrintfBufferTy, /*isConstant=*/false, GlobalValue::ExternalLinkage,
          nullptr, PrintfBufferVariableName(), nullptr,
          GlobalValue::NotThreadLocal, clspv::AddressSpace::Global);
      GV->setAlignment(Align(1));
      return GV;
    });
  }

  unsigned PrintfID = 0;

  SmallVector<Function *, 8> FunctionsUsingPrintf;
  SmallVector<CallInst *, 8> PrintfsToProcess;
  for (auto &F : M) {
    bool UsesPrintf = false;
    for (auto &BB : F) {
      for (auto &Inst : BB) {
        if (auto *CI = dyn_cast<CallInst>(&Inst)) {
          auto *Callee = CI->getCalledFunction();
          if (Callee->getName() == "printf") {
            PrintfsToProcess.push_back(CI);
            UsesPrintf = true;
          }
        }
      }
    }
    if (UsesPrintf) {
      FunctionsUsingPrintf.push_back(&F);
    }
  }

  for (auto *CI : PrintfsToProcess) {
    // Check format string is valid
    auto *FmtStringValue = CI->getArgOperand(0);
    auto FmtString = GetStringLiteral(FmtStringValue);
    if (!FmtString.has_value()) {
      continue;
    }

    auto &DL = M.getDataLayout();
    SmallVector<Metadata *, 8> ArgMD;
    auto PrintfCallID = PrintfID++;
    // Process arguments, build argument metadata
    for (unsigned i = 1; i < CI->arg_size(); i++) {
      Value *Arg = CI->getArgOperand(i);
      Type *ArgType = Arg->getType();

      // Literal Arg are store using a 32bits identifier, which differs when
      // using 64bits pointers from the size returned by GetPrintfStoreSize.
      bool IsStringLiteral = GetStringLiteral(Arg).has_value();
      unsigned ArgSize = IsStringLiteral ? 4 : GetPrintfStoreSize(DL, ArgType);

      auto *ArgSizeConst = ConstantInt::get(Int32Ty, ArgSize);
      ArgMD.push_back(ConstantAsMetadata::get(ArgSizeConst));
    }

    auto *PrintfMD =
        CreatePrintfArgsMetadata(M, ArgMD, FmtString.value(), PrintfCallID);
    PrintfMDs->addOperand(PrintfMD);

    // Get string literal arguments to printf (not including format string) and
    // hoist them out as separate format strings. This way we don't need to
    // worry about storing byte-sized strings in an i32 buffer.
    for (unsigned i = 1; i < CI->arg_size(); i++) {
      Value *Arg = CI->getArgOperand(i);
      auto StringLiteral = GetStringLiteral(Arg);
      if (StringLiteral.has_value()) {
        auto StringLiteralID = PrintfID++;
        auto *StringLiteralMD = CreatePrintfArgsMetadata(
            M, {}, StringLiteral.value(), StringLiteralID);
        PrintfMDs->addOperand(StringLiteralMD);

        // The printf now stores the string's ID rather than its data
        CI->setArgOperand(i, ConstantInt::get(Int32Ty, StringLiteralID));
      }
    }

    DefinePrintfInstance(M, CI, PrintfCallID);
  }

  for (auto &F : FunctionsUsingPrintf) {
    if (F->getCallingConv() == CallingConv::SPIR_KERNEL) {
      if (!F->getMetadata(clspv::PrintfKernelMetadataName())) {
        F->addMetadata(clspv::PrintfKernelMetadataName(),
                       *MDNode::get(M.getContext(), {}));
      }
    } else {
      for (auto &F : M) {
        if (!F.getMetadata(clspv::PrintfKernelMetadataName())) {
          F.addMetadata(clspv::PrintfKernelMetadataName(),
                        *MDNode::get(M.getContext(), {}));
        }
        break;
      }
    }
  }

  // Tidy up metadata if there were no printfs
  if (PrintfMDs->getNumOperands() == 0) {
    PrintfMDs->eraseFromParent();
    return PA;
  }

  // The original printf function should be unused now
  auto *PrintfFunc = M.getFunction("printf");
  if (PrintfFunc) {
    PrintfFunc->eraseFromParent();
  }

  return PA;
}
