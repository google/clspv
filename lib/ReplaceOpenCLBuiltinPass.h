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

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#include "spirv/unified1/spirv.hpp"

#include "clspv/AddressSpace.h"

#include "Builtins.h"

#include <set>

#ifndef _CLSPV_LIB_REPLACE_OPENCL_BUILTIN_PASS_H
#define _CLSPV_LIB_REPLACE_OPENCL_BUILTIN_PASS_H

namespace clspv {
struct ReplaceOpenCLBuiltinPass
    : llvm::PassInfoMixin<ReplaceOpenCLBuiltinPass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  bool runOnFunction(llvm::Function &F);
  void removeUnusedSamplers(llvm::Module &M);
  bool replaceAbs(llvm::Function &F);
  bool replaceAbsDiff(llvm::Function &F, bool is_signed);
  bool replaceCopysign(llvm::Function &F);
  bool replaceNativeRecip(llvm::Function &F);
  bool replaceDivide(llvm::Function &F);
  bool replaceDot(llvm::Function &F);
  bool replaceFmod(llvm::Function &F);
  bool replaceExp10(llvm::Function &F, const std::string &basename);
  bool replaceLog10(llvm::Function &F, const std::string &basename);
  bool replaceLog1p(llvm::Function &F);
  bool replaceBarrier(llvm::Function &F, bool subgroup = false);
  bool replaceMemFence(llvm::Function &F, spv::MemorySemanticsMask semantics);
  bool replacePrefetch(llvm::Function &F);
  bool replaceRelational(llvm::Function &F, llvm::CmpInst::Predicate P);
  bool replaceIsInfAndIsNan(llvm::Function &F, spv::Op SPIRVOp, int32_t isvec);
  bool replaceIsFinite(llvm::Function &F);
  bool replaceAllAndAny(llvm::Function &F, spv::Op SPIRVOp);
  bool replaceUpsample(llvm::Function &F);
  bool replaceRotate(llvm::Function &F);
  bool replaceConvert(llvm::Function &F, bool SrcIsSigned, bool DstIsSigned);
  bool replaceMulHi(llvm::Function &F, bool is_signed, bool is_mad = false);
  bool replaceSelect(llvm::Function &F);
  bool replaceBitSelect(llvm::Function &F);
  bool replaceStep(llvm::Function &F, bool is_smooth);
  bool replaceSignbit(llvm::Function &F, bool is_vec);
  bool replaceMul(llvm::Function &F, bool is_float, bool is_mad);
  llvm::Value *createVloadHalf(llvm::Module &M, llvm::CallInst *CI,
                               llvm::Value *index, llvm::Value *ptr);
  bool replaceVloadHalf(llvm::Function &F, const std::string &name,
                        int vec_size, bool aligned);
  bool replaceVloadHalf(llvm::Function &F);
  bool replaceVloadHalf2(llvm::Function &F);
  bool replaceVloadHalf3(llvm::Function &F);
  bool replaceVloadaHalf3(llvm::Function &F);
  bool replaceVloadHalf4(llvm::Function &F);
  bool replaceVloadHalf8(llvm::Function &F);
  bool replaceVloadHalf16(llvm::Function &F);
  bool replaceClspvVloadaHalf2(llvm::Function &F);
  bool replaceClspvVloadaHalf4(llvm::Function &F);
  llvm::Value *createVstoreHalf(llvm::Module &M, llvm::CallInst *CI,
                                llvm::Value *value, llvm::Value *index,
                                llvm::Value *ptr);
  bool replaceVstoreHalf(llvm::Function &F, int vec_size, bool aligned);
  bool replaceVstoreHalf(llvm::Function &F);
  bool replaceVstoreHalf2(llvm::Function &F);
  bool replaceVstoreHalf3(llvm::Function &F);
  bool replaceVstoreaHalf3(llvm::Function &F);
  bool replaceVstoreHalf4(llvm::Function &F);
  bool replaceVstoreHalf8(llvm::Function &F);
  bool replaceVstoreHalf16(llvm::Function &F);
  bool replaceHalfReadImage(llvm::Function &F);
  bool replaceHalfWriteImage(llvm::Function &F);
  bool replaceSampledReadImage(llvm::Function &F);
  bool replaceAtomics(llvm::Function &F, spv::Op Op);
  bool replaceAtomics(llvm::Function &F, llvm::AtomicRMWInst::BinOp Op);
  bool replaceAtomicLoad(llvm::Function &F);
  bool replaceGetFence(llvm::Function &F);
  bool replaceAddressSpaceQualifiers(llvm::Function &F,
                                     clspv::AddressSpace::Type addrspace);
  bool replaceExplicitAtomics(llvm::Function &F, spv::Op Op,
                              spv::MemorySemanticsMask semantics =
                                  spv::MemorySemanticsAcquireReleaseMask);
  bool replaceAtomicCompareExchange(llvm::Function &);
  bool replaceAtomicFlagTestAndSet(llvm::Function &F);
  bool replaceAtomicFlagClear(llvm::Function &F);
  bool replaceCross(llvm::Function &F);
  bool replaceFract(llvm::Function &F, int vec_size);
  bool replaceVload(llvm::Function &F);
  bool replaceVstore(llvm::Function &F);
  bool replaceAddSubSat(llvm::Function &F, bool is_signed, bool is_add);
  bool replaceHadd(llvm::Function &F, bool is_signed,
                   llvm::Instruction::BinaryOps join_opcode);
  bool replaceCountZeroes(llvm::Function &F, bool leading);
  bool replaceMadSat(llvm::Function &F, bool is_signed);
  bool replaceOrdered(llvm::Function &F, bool is_ordered);
  bool replaceIsNormal(llvm::Function &F);
  bool replaceFDim(llvm::Function &F);
  bool replaceRound(llvm::Function &F);
  bool replaceTrigPi(llvm::Function &F, Builtins::BuiltinType type);
  bool replaceSincos(llvm::Function &F);
  bool replaceExpm1(llvm::Function &F);
  bool replacePown(llvm::Function &F);

  bool replaceWaitGroupEvents(llvm::Function &F);
  llvm::GlobalVariable *
  getOrCreateGlobalVariable(llvm::Module &M, std::string VariableName,
                            AddressSpace::Type VariableAddressSpace);
  llvm::Value *replaceAsyncWorkGroupCopies(llvm::Module &M, llvm::CallInst *CI,
                                           llvm::Value *Dst, llvm::Value *Src,
                                           llvm::Type *GenType,
                                           llvm::Value *NumGentypes,
                                           llvm::Value *Stride,
                                           llvm::Value *Event);
  bool replaceAsyncWorkGroupCopy(llvm::Function &F, llvm::Type *ty);
  bool replaceAsyncWorkGroupStridedCopy(llvm::Function &F, llvm::Type *ty);

  // Caches struct types for { |type|, |type| }. This prevents
  // getOrInsertllvm::Function from introducing a bitcasts between structs
  // with identical contents.
  llvm::Type *GetPairStruct(llvm::Type *type);

  llvm::Value *InsertOpMulExtended(llvm::Instruction *InsertPoint,
                                   llvm::Value *a, llvm::Value *b,
                                   bool IsSigned, bool Int64 = false);

  llvm::DenseMap<llvm::Type *, llvm::Type *> PairStructMap;

  llvm::DenseMap<llvm::Value *, llvm::Type *> InferredTypeCache;

public:
  // Set containing every builtin this pass is capable of replacing.
  static std::set<Builtins::BuiltinType> ReplaceableBuiltins;
};

} // namespace clspv

#endif // _CLSPV_LIB_REPLACE_OPENCL_BUILTIN_PASS_H
