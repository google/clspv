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

#include <vector>

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/Local.h"

#include "ArgKind.h"
#include "BitcastUtils.h"

#include "Types.h"
#include "clspv/Option.h"

#include "RewritePackedStructs.h"

using namespace llvm;

#define DEBUG_TYPE "RewritePackedStructs"

namespace {

unsigned getStructAlignment(Type *Ty, const DataLayout *DL) {
  unsigned structAlignment = 1;
  for (unsigned i = 0; i < Ty->getNumContainedTypes(); i++) {
    Type *ElemTy = Ty->getContainedType(i);

    if (ElemTy->isAggregateType() || ElemTy->isVectorTy()) {
      structAlignment =
          std::max(structAlignment, getStructAlignment(ElemTy, DL));
    } else {
      structAlignment =
          std::max(structAlignment, (unsigned)DL->getTypeAllocSize(ElemTy));
    }
  }
  return structAlignment;
}

/// Map the arguments of the wrapper function to the original arguments of the
/// user-defined function (before transforming types to i8 array).
SmallVector<Value *, 16> mapWrapperArgsToWrappeeArgs(IRBuilder<> &B,
                                                     Function &Wrappee,
                                                     Function &Wrapper,
                                                     const DataLayout *DL) {
  SmallVector<Value *, 16> Args;

  std::size_t ArgumentCount = Wrapper.arg_size();
  Args.reserve(ArgumentCount);

  for (std::size_t i = 0; i < ArgumentCount; ++i) {
    auto *Arg = Wrappee.getArg(i);
    auto *NewArg = Wrapper.getArg(i);
    NewArg->takeName(Arg);
    auto *OldArgTy = Wrappee.getFunctionType()->getParamType(i);

    assert(NewArg->getType()->isPointerTy());
    auto *EquivalentArg = B.CreateBitCast(NewArg, OldArgTy);
    Args.push_back(EquivalentArg);
  }

  return Args;
}

/// Create a new, equivalent function with new packed struct type.
///
/// This is achieved by creating a new function (the "wrapper") which inlines
/// the given function (the "wrappee"). Only the parameters are mapped.
Function *createFunctionWithMappedTypes(Function &F,
                                        FunctionType *EquivalentFunctionTy,
                                        const DataLayout *DL) {
  auto *Wrapper = Function::Create(EquivalentFunctionTy, F.getLinkage());
  Wrapper->takeName(&F);
  Wrapper->setCallingConv(F.getCallingConv());
  Wrapper->copyAttributesFrom(&F);
  Wrapper->copyMetadata(&F, /* offset */ 0);

  BasicBlock::Create(F.getContext(), "", Wrapper);
  IRBuilder<> B(&Wrapper->getEntryBlock());

  // Fill in the body of the wrapper function.
  auto WrappeeArgs = mapWrapperArgsToWrappeeArgs(B, F, *Wrapper, DL);
  CallInst *Call = B.CreateCall(&F, WrappeeArgs);

  B.CreateRetVoid();

  // Ensure wrapper has a parent or InlineFunction will crash.
  F.getParent()->getFunctionList().push_front(Wrapper);

  // Inline the original function.
  InlineFunctionInfo Info;
  auto Result = InlineFunction(*Call, Info);
  if (!Result.isSuccess()) {
    LLVM_DEBUG(dbgs() << "Failed to inline " << F.getName() << '\n');
    LLVM_DEBUG(dbgs() << "Reason: " << Result.getFailureReason() << '\n');
    llvm_unreachable("Unexpected failure when inlining function.");
  }

  // Inlining a function can introduce constant expression that we could not
  // handle afterwards.
  BitcastUtils::RemovedCstExprFromFunction(Wrapper);

  return Wrapper;
}

} // namespace

PreservedAnalyses clspv::RewritePackedStructs::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  DL = &M.getDataLayout();

  SmallVector<Function *, 16> OldKernels;
  for (auto &F : M.functions()) {
    bool needRewriting = false;
    bool isOpaqueFn = false;
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      for (auto &Arg : F.args()) {
        if (Arg.getType()->isOpaquePointerTy()) {
          isOpaqueFn = true;
        }

        // process the function if it has an input buffer with a packed struct
        // type.
        Type *ArgType =
            clspv::InferType(&Arg, F.getParent()->getContext(), &type_cache_);
        auto StructTy = dyn_cast<StructType>(ArgType);
        if (StructTy && StructTy->isPacked()) {
          const auto ArgKind = clspv::GetArgKind(Arg, Arg.getType());
          if (ArgKind == clspv::ArgKind::Buffer ||
              ArgKind == clspv::ArgKind::BufferUBO) {
            needRewriting = true;
          }
        }
      }
    }

    if (needRewriting) {
      if (isOpaqueFn) {
        runOnOpaqueFunction(F);
      } else {
        if (runOnFunction(F)) {
          OldKernels.push_back(&F);
        }
      }
    }
  }

  // Delete the old kernels if we have rewritten them.
  for (auto OldKernel : OldKernels) {
    OldKernel->eraseFromParent();
  }

  return PA;
}

Type *clspv::RewritePackedStructs::getEquivalentType(Type *Ty) {
  auto it = TypeMap.find(Ty);
  if (it != TypeMap.end()) {
    return it->second;
  }

  // Recursive implementation, taking advantage of the cache.
  auto *EquivalentTy = getEquivalentTypeImpl(Ty);
  TypeMap.insert({Ty, EquivalentTy});

  if (EquivalentTy) {
    LLVM_DEBUG(dbgs() << "Generating equivalent type for " << *Ty << ": "
                      << *EquivalentTy << '\n');
  }

  return EquivalentTy;
}

Type *clspv::RewritePackedStructs::getEquivalentTypeImpl(Type *Ty) {
  if (!Ty->isPointerTy() && !Ty->isStructTy() && !Ty->isFunctionTy()) {
    // No rewriting required.
    return nullptr;
  }

  // TODO(#816): remove after final transition.
  if (Ty->isPointerTy()) {
    if (auto *ElementTy =
            getEquivalentType(Ty->getNonOpaquePointerElementType())) {
      return ElementTy->getPointerTo(Ty->getPointerAddressSpace());
    }

    return nullptr;
  }

  if (auto *StructTy = dyn_cast<StructType>(Ty)) {
    if (StructTy->getStructNumElements() == 0)
      return nullptr;
    LLVMContext &Ctx = StructTy->getContainedType(0)->getContext();
    SmallVector<Type *, 16> Types;
    bool Packed = StructTy->isPacked();
    uint32_t structSize = DL->getTypeAllocSize(StructTy);
    uint32_t structAlignment = getStructAlignment(StructTy, DL);

    if (Packed && structSize % structAlignment != 0) {
      ArrayType* ArrayTy = ArrayType::get(Type::getInt8Ty(Ctx), structSize);
      return StructType::get(Ctx, {ArrayTy}, Packed);
    } else {
      return nullptr;
    }
  }

  if (auto *FunctionTy = dyn_cast<FunctionType>(Ty)) {
    if (FunctionTy->isVarArg()) {
      llvm_unreachable("varargs not supported");
    }

    bool RequireRewriting = false;

    // Convert parameter types.
    SmallVector<Type *, 16> EquivalentParamTys;
    EquivalentParamTys.reserve(FunctionTy->getNumParams());
    for (auto *ParamTy : FunctionTy->params()) {
      auto *EquivalentParamTy = getEquivalentTypeOrSelf(ParamTy);
      EquivalentParamTys.push_back(EquivalentParamTy);
      RequireRewriting |= (EquivalentParamTy != ParamTy);
    }

    if (RequireRewriting) {
      return FunctionType::get(FunctionTy->getReturnType(), EquivalentParamTys,
                               FunctionTy->isVarArg());
    } else {
      return nullptr;
    }
  }

#ifndef NDEBUG
  dbgs() << "Unsupported type: " << *Ty << '\n';
#endif
  llvm_unreachable("Unsupported kind of Type.");
}

bool clspv::RewritePackedStructs::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return false;
  }

  // Rewrite the function if needed.
  Function *RewrittenFunction = convertUserDefinedFunction(F);

  if (RewrittenFunction == nullptr) {
    LLVM_DEBUG(dbgs() << "Function " << F.getName()
                      << " doesn't need rewriting\n");
    return false;
  }

  bool Modified = (RewrittenFunction != &F);

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << *RewrittenFunction << '\n');

  return Modified;
}

bool clspv::RewritePackedStructs::runOnOpaqueFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return false;
  }

  bool Modified = false;

  for (auto &Arg : F.args()) {
    // Reduce alignment of packed struct by mapping struct types to an array of
    // i8.
    Type *ArgType =
        clspv::InferType(&Arg, F.getParent()->getContext(), &type_cache_);
    auto StructTy = dyn_cast<StructType>(ArgType);
    if (StructTy && StructTy->isPacked()) {
      const auto ArgKind = clspv::GetArgKind(Arg, Arg.getType());
      if (ArgKind == clspv::ArgKind::Buffer ||
          ArgKind == clspv::ArgKind::BufferUBO) {
        Modified = true;
        auto EquivalentStructTy = getEquivalentType(StructTy);

        // Replace the input buffer uses with a local pointer of the same type
        // at the beginning of the function so that we preserve the main type
        // uses.
        auto BeginInsertionPt = &*F.getEntryBlock().getFirstInsertionPt();
        IRBuilder<> B(BeginInsertionPt);
        auto LocalStructPtr =
            B.CreateAlloca(StructTy, Arg.getType()->getPointerAddressSpace());
        Arg.replaceAllUsesWith(LocalStructPtr);

        // Store a zeroInitializer value of the new struct type inside the
        // buffer so that opaque pointer is inferred as the new struct type.
        B.CreateStore(Constant::getNullValue(EquivalentStructTy), &Arg);

        // Extract the processed value from allocated local pointer, map them to
        // i8 type vector and add these values to the input buffer.
        auto EndInsertionPt = &*F.getEntryBlock().getTerminator();
        B.SetInsertPoint(EndInsertionPt);

        auto LocalStruct = B.CreateLoad(StructTy, LocalStructPtr);

        unsigned StructArrayIdx = 0;
        for (unsigned LocalStructIdx = 0;
             LocalStructIdx < StructTy->getStructNumElements();
             LocalStructIdx++) {
          // Extract the processed value from allocated local pointer.
          auto LocalStructValue =
              B.CreateExtractValue(LocalStruct, {LocalStructIdx});
          unsigned LocalStructTypeSize =
              DL->getTypeAllocSize(StructTy->getContainedType(LocalStructIdx));

          // Map values to i8 type vector.
          auto bitcastedValue = B.CreateBitCast(
              LocalStructValue,
              FixedVectorType::get(
                  Type::getInt8Ty(EquivalentStructTy->getContext()),
                  LocalStructTypeSize));

          // Add these values to the input buffer.
          for (unsigned VecIdx = 0; VecIdx < LocalStructTypeSize; VecIdx++) {
            auto VecValue = B.CreateExtractElement(bitcastedValue, VecIdx);
            auto InputBufferPtr = B.CreateGEP(
                EquivalentStructTy, &Arg,
                {B.getInt32(0), B.getInt32(0), B.getInt32(StructArrayIdx)});
            B.CreateStore(VecValue, InputBufferPtr);
            StructArrayIdx++;
          }
        }
      }
    }
  }

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << F << '\n');

  return Modified;
}

Function *clspv::RewritePackedStructs::convertUserDefinedFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Handling of user defined function:\n");
  LLVM_DEBUG(dbgs() << F << '\n');

  auto *FunctionTy = F.getFunctionType();
  auto *EquivalentFunctionTy =
      cast_or_null<FunctionType>(getEquivalentType(FunctionTy));

  // If no work is needed, mark it as so for future reference and bail out.
  if (EquivalentFunctionTy == nullptr) {
    LLVM_DEBUG(dbgs() << "No need of wrapper function\n");
    return nullptr;
  }

  Function *EquivalentFunction =
      createFunctionWithMappedTypes(F, EquivalentFunctionTy, DL);

  LLVM_DEBUG(dbgs() << "Wrapper function:\n" << *EquivalentFunction << "\n");

  return EquivalentFunction;
}
