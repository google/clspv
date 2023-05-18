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

#include <tuple>

#include "BitcastUtils.h"
#include "SimplifyPointerBitcastPass.h"
#include "Types.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

using namespace llvm;
using namespace BitcastUtils;

#define DEBUG_TYPE "SimplifyPointerBitcast"

PreservedAnalyses
clspv::SimplifyPointerBitcastPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  // Start by removing all Constant Expressions. Do it only once as all the
  // functions below will not generate new Constant Expression.
  runOnInstFromCstExpr(M);

  // Loop through our individual simplification passes until they stop changing
  // things.
  bool changed = true;
  while (changed) {
    changed = false;

    changed |= runOnTrivialBitcast(M);
    changed |= runOnBitcastFromBitcast(M);
    changed |= runOnGEPFromGEP(M);
    changed |= runOnGEPImplicitCasts(M);
  }

  return PA;
}

void clspv::SimplifyPointerBitcastPass::runOnInstFromCstExpr(Module &M) const {
  for (Function &F : M) {
    BitcastUtils::RemoveCstExprFromFunction(&F);
  }
}

bool clspv::SimplifyPointerBitcastPass::runOnTrivialBitcast(Module &M) const {
  // Remove things like:
  //  bitcast i32 addrspace(1)* %ptr to i32 addrspace(1)*

  SmallVector<BitCastInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a bitcast instruction...
        if (auto Bitcast = dyn_cast<BitCastInst>(&I)) {
          // ... whose source type is the same as the destination type.
          auto Source = Bitcast->getOperand(0);
          if (Source->getType() == Bitcast->getType()) {
            // ... record the bitcast as something we need to process.
            WorkList.push_back(Bitcast);
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (auto Bitcast : WorkList) {
    auto Source = Bitcast->getOperand(0);
    Bitcast->replaceAllUsesWith(Source);

    // Remove the bitcast as it has no users now.
    Bitcast->eraseFromParent();

    // Check if the source value is an instruction and had no other users...
    if (auto SourceInst = dyn_cast<Instruction>(Source)) {
      if (0 == SourceInst->getNumUses()) {
        // ... and remove it if we were its only user.
        SourceInst->eraseFromParent();
      }
    }
  }

  return Changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnBitcastFromBitcast(
    Module &M) const {
  SmallVector<BitCastInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a bitcast instruction...
        if (auto Bitcast = dyn_cast<BitCastInst>(&I)) {
          // ... whose source is a bitcast instruction...
          if (isa<BitCastInst>(Bitcast->getOperand(0))) {
            // ... record the bitcast as something we need to process.
            WorkList.push_back(Bitcast);
          }
          // ... whose source is a bitcast constant expression
          if (const auto CE = dyn_cast<ConstantExpr>(Bitcast->getOperand(0))) {
            if (CE->getOpcode() == Instruction::BitCast) {
              // ... record the bitcast as something we need to process.
              WorkList.push_back(Bitcast);
            }
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (auto Bitcast : WorkList) {
    Instruction *OtherBitcast = dyn_cast<BitCastInst>(Bitcast->getOperand(0));
    if (!OtherBitcast) {
      auto CE = dyn_cast<ConstantExpr>(Bitcast->getOperand(0));
      assert(CE && CE->getOpcode() == Instruction::BitCast);
      OtherBitcast = CE->getAsInstruction(Bitcast);
    }

    if (OtherBitcast->getType() == Bitcast->getType()) {
      Bitcast->replaceAllUsesWith(OtherBitcast);
    } else {
      // Create a new bitcast from the other bitcasts argument to our type.
      auto NewBitcast =
          CastInst::Create(Instruction::BitCast, OtherBitcast->getOperand(0),
                           Bitcast->getType(), "", Bitcast);

      // And replace the original bitcast with our replacement bitcast.
      Bitcast->replaceAllUsesWith(NewBitcast);
    }

    // Remove the bitcast as it has no users now.
    Bitcast->eraseFromParent();

    // Check if the other bitcast had no other users...
    if (0 == OtherBitcast->getNumUses()) {
      // ... and remove it if we were its only user.
      OtherBitcast->eraseFromParent();
    }
  }

  return Changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnGEPFromGEP(Module &M) const {
  SmallVector<GetElementPtrInst *, 16> WorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // If we have a GEP instruction...
        if (auto GEP = dyn_cast<GetElementPtrInst>(&I)) {
          // ... whose operand is also a GEP instruction...
          if (isa<GetElementPtrInst>(GEP->getPointerOperand())) {
            // ... with no implicit cast between them...
            auto OtherGEP = cast<GetElementPtrInst>(GEP->getPointerOperand());
            if (OtherGEP->getResultElementType() ==
                GEP->getSourceElementType()) {
              // ... record the GEP as something we need to process.
              WorkList.push_back(GEP);
            }
          }
        }
      }
    }
  }

  const bool Changed = !WorkList.empty();

  for (GetElementPtrInst *GEP : WorkList) {
    IRBuilder<> Builder(GEP);

    auto OtherGEP = cast<GetElementPtrInst>(GEP->getPointerOperand());

    Value *SrcLastIdxOp = OtherGEP->getOperand(OtherGEP->getNumOperands() - 1);
    Value *GEPIdxOp = GEP->getOperand(1);

    // Add the indices together, if the last one from before is not zero.
    auto *CstSrcLastIdxOp = dyn_cast<ConstantInt>(SrcLastIdxOp);
    auto CstGEPIdxOp = dyn_cast<ConstantInt>(GEPIdxOp);

    // We need to know the number of element of the commun type between GEP and
    // OtherGEP to avoid generating a constant index greater than this size for
    // private pointer
    uint32_t VecOrArraySize = UINT32_MAX;
    if (OtherGEP->getNumOperands() > 2) {
      SmallVector<Value *, 8> Idxs;
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
      unsigned numEle =
          BitcastUtils::GetNumEle(GetElementPtrInst::getIndexedType(
              OtherGEP->getSourceElementType(), Idxs));
      if (numEle > 1) {
        VecOrArraySize = numEle;
      }
    }

    SmallVector<Value *, 8> Idxs;
    if (CstGEPIdxOp && CstGEPIdxOp->isZero()) {
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end());
    } else if (CstSrcLastIdxOp && CstGEPIdxOp &&
               (CstSrcLastIdxOp->getZExtValue() + CstGEPIdxOp->getZExtValue() <
                VecOrArraySize)) {
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
      if (CstGEPIdxOp->isZero()) {
        Idxs.push_back(SrcLastIdxOp);
      } else if (CstSrcLastIdxOp->isZero()) {
        Idxs.push_back(GEPIdxOp);
      } else {
        Idxs.push_back(ConstantInt::get(
            IntegerType::get(M.getContext(),
                             clspv::PointersAre64Bit(M) &&
                                     !OtherGEP->getType()->isStructTy()
                                 ? 64
                                 : 32),
            CstGEPIdxOp->getZExtValue() + CstSrcLastIdxOp->getZExtValue()));
      }
    } else if (cast<PointerType>(OtherGEP->getPointerOperand()->getType())
                       ->getAddressSpace() == clspv::AddressSpace::Private &&
               (OtherGEP->getSourceElementType()->isArrayTy() ||
                OtherGEP->getSourceElementType()->isStructTy() ||
                OtherGEP->getSourceElementType()->isVectorTy())) {
      uint64_t cstVal;
      Value *dynVal;
      size_t smallerBitWidths;
      ExtractOffsetFromGEP(M.getDataLayout(), Builder, OtherGEP, cstVal, dynVal,
                           smallerBitWidths);
      if (CstGEPIdxOp) {
        cstVal += CstGEPIdxOp->getZExtValue();
      } else if (dynVal) {
        dynVal = Builder.CreateAdd(dynVal, GEPIdxOp);
      } else {
        dynVal = GEPIdxOp;
      }
      auto NewGEPIdxs = GetIdxsForTyFromOffset(
          M.getDataLayout(), Builder, OtherGEP->getSourceElementType(),
          OtherGEP->getResultElementType(), cstVal, dynVal, smallerBitWidths,
          clspv::AddressSpace::Private);
      Idxs.append(NewGEPIdxs);
    } else {
      if (!CstSrcLastIdxOp || !CstSrcLastIdxOp->isZero()) {
        if (clspv::PointersAre64Bit(M) && !OtherGEP->getType()->isStructTy()) {
          if (GEPIdxOp->getType()->isIntegerTy(32)) {
            GEPIdxOp = Builder.CreateZExt(GEPIdxOp,
                                          IntegerType::get(M.getContext(), 64));
          }
          if (SrcLastIdxOp->getType()->isIntegerTy(32)) {
            SrcLastIdxOp = Builder.CreateZExt(
                SrcLastIdxOp, IntegerType::get(M.getContext(), 64));
          }
        }
        GEPIdxOp = Builder.CreateAdd(SrcLastIdxOp, GEPIdxOp);
      }
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
      Idxs.push_back(GEPIdxOp);
    }

    Idxs.append(GEP->op_begin() + 2, GEP->op_end());

    // Struct types require i32 indexes, so fix up any constant i64s
    // that are safe to change
    if (clspv::PointersAre64Bit(M) &&
        OtherGEP->getSourceElementType()->isStructTy()) {
      SmallVector<Value *, 8> NewIdxs;
      for (auto *Idx : Idxs) {
        if (auto ConstIdx = dyn_cast<ConstantInt>(Idx)) {
          uint64_t C = ConstIdx->getZExtValue();
          if (C < std::numeric_limits<uint32_t>::max()) {
            NewIdxs.push_back(
                ConstantInt::get(IntegerType::get(M.getContext(), 32), C));
          } else {
            NewIdxs.push_back(Idx);
          }
        } else {
          NewIdxs.push_back(Idx);
        }
      }

      Idxs = NewIdxs;
    }

    Value *NewGEP = nullptr;
    // Create the new GEP.  If we used the Builder it will do some folding
    // that we don't want.  In particular, if the first GEP is to an LLVM
    // constant then the combined GEP will become a ConstantExpr and it
    // will hide the pointer from subsequent passes.  So bypass the Builder
    // and create the GEP instruction directly.
    if (GEP->isInBounds() && OtherGEP->isInBounds()) {
      NewGEP = GetElementPtrInst::CreateInBounds(
          OtherGEP->getSourceElementType(), OtherGEP->getPointerOperand(), Idxs,
          "", GEP);
    } else {
      NewGEP = GetElementPtrInst::Create(OtherGEP->getSourceElementType(),
                                         OtherGEP->getPointerOperand(), Idxs,
                                         "", GEP);
    }

    // And replace the original GEP with our replacement GEP.
    GEP->replaceAllUsesWith(NewGEP);

    // Remove the GEP as it has no users now.
    GEP->eraseFromParent();

    // Check if the other GEP had no other users...
    if (0 == OtherGEP->getNumUses()) {
      // ... and remove it if we were its only user.
      OtherGEP->eraseFromParent();
    }
  }

  return Changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnGEPImplicitCasts(Module &M) const {
  const DataLayout &DL = M.getDataLayout();

  DenseSet<GetElementPtrInst *> UnneededCasts;
  DenseMap<GetElementPtrInst *,
           std::tuple<Instruction *, ConstantInt *, Type *, Type *>>
      UpgradeCstCasts;
  DenseMap<Instruction *, std::pair<int, GetElementPtrInst *>> ImplicitGEPs;
  DenseMap<Value *, Type *> type_cache;
  DenseMap<GetElementPtrInst *, GetElementPtrInst *> ImplicitCasts;

  bool changed = false;

  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true))
          continue;

        if (auto *gep = dyn_cast<GetElementPtrInst>(&I)) {
          if (source_ty == gep->getResultElementType()) {
            UnneededCasts.insert(gep);
            continue;
          }
        }

        int Steps = 0;
        bool PerfectMatch;
        if (FindAliasingContainedType(source_ty, dest_ty, Steps, PerfectMatch,
                                      DL)) {
          // Single level GEP is ok to transform, but beyond
          // that the address math must be divided among other
          // entries.
          auto *gep = dyn_cast<GetElementPtrInst>(&I);
          auto *call = dyn_cast_or_null<CallInst>(&I);
          bool userCall = call && !call->getCalledFunction()->isDeclaration();
          if ((Steps > 0 && !gep) || (Steps == 1)) {
            if (!userCall && (gep || PerfectMatch)) {
              ImplicitGEPs.insert(
                  {&I, std::make_pair(Steps, PerfectMatch ? nullptr : gep)});
              continue;
            }
          }
        }

        if (auto *gep = dyn_cast<GetElementPtrInst>(source)) {

          if (UnneededCasts.count(gep) != 0 ||
              UpgradeCstCasts.count(gep) != 0 || ImplicitGEPs.count(gep) != 0) {
            continue;
          }

          if (auto *inst_gep = dyn_cast<GetElementPtrInst>(&I)) {
            auto VecSrcTy = dyn_cast<FixedVectorType>(source_ty);
            auto VecDstTy = dyn_cast<FixedVectorType>(dest_ty);

            // Do not lower implicit cast containing vec3, this would revert
            // ThreeElementVectorLoweringPass and ReplacePointerBitcastPass
            // should be able to deal with it without issues.
            if (!(VecSrcTy && VecDstTy &&
                  (VecSrcTy->getNumElements() == 3 ||
                   VecDstTy->getNumElements() == 3))) {
              ImplicitCasts.insert({gep, inst_gep});
              continue;
            }
          }

          // For some reason, with opaque pointer, LLVM tends to transform
          // memcpy/memset into a series of gep and load/store. But while the
          // load/store are on i32 for example, it keeps the gep on i8 but
          // with index multiples of sizeof(i32). To avoid such bitcast which
          // leads to trying to store an i8 into a i32 element (which is not
          // supported), upgrade those gep into gep on i32 with the
          // appropriate indexes.
          SmallVector<Value *, 2> Indices(gep->indices());
          if (Indices.size() == 1) {
            if (auto cst = dyn_cast<ConstantInt>(Indices[0])) {
              UpgradeCstCasts.insert(
                  {gep, std::make_tuple(&I, cst, source_ty, dest_ty)});
              continue;
            }
          }
        }
      }
    }
  }

  for (auto GEPs : ImplicitCasts) {
    GetElementPtrInst *src_gep = GEPs.first;
    GetElementPtrInst *inst_gep = GEPs.second;

    IRBuilder<> Builder{inst_gep};
    uint64_t CstVal;
    Value *DynVal;
    size_t SmallerBitWidths;
    ExtractOffsetFromGEP(DL, Builder, inst_gep, CstVal, DynVal,
                         SmallerBitWidths);
    auto Idxs = GetIdxsForTyFromOffset(
        DL, Builder, src_gep->getResultElementType(),
        inst_gep->getResultElementType(), CstVal, DynVal, SmallerBitWidths,
        (clspv::AddressSpace::Type)inst_gep->getPointerOperand()
            ->getType()
            ->getPointerAddressSpace());
    auto new_gep = GetElementPtrInst::Create(src_gep->getResultElementType(),
                                             src_gep, Idxs, "", inst_gep);
    inst_gep->replaceAllUsesWith(new_gep);
    inst_gep->eraseFromParent();
    changed = true;
  }

  for (auto *GEP : UnneededCasts) {
    IRBuilder<> Builder(GEP);
    Type *Ty = GEP->getResultElementType();
    uint64_t CstVal;
    Value *DynVal;
    size_t SmallerBitWidths;
    ExtractOffsetFromGEP(DL, Builder, GEP, CstVal, DynVal, SmallerBitWidths);
    auto Indices = GetIdxsForTyFromOffset(
        DL, Builder, Ty, Ty, CstVal, DynVal, SmallerBitWidths,
        (clspv::AddressSpace::Type)GEP->getPointerOperand()
            ->getType()
            ->getPointerAddressSpace());

    auto *NewGEP = GetElementPtrInst::Create(Ty, GEP->getPointerOperand(),
                                             Indices, "", GEP);
    GEP->replaceAllUsesWith(NewGEP);
    GEP->eraseFromParent();

    changed = true;
  }

  for (auto GEPInfo : UpgradeCstCasts) {
    auto *GEP = GEPInfo.first;
    Instruction *I = std::get<0>(GEPInfo.second);
    ConstantInt *cst = std::get<1>(GEPInfo.second);
    Type *source_ty = std::get<2>(GEPInfo.second);
    Type *dest_ty = std::get<3>(GEPInfo.second);
    auto source_ty_size = SizeInBits(DL, source_ty);
    auto dest_ty_size = SizeInBits(DL, dest_ty);
    auto value = cst->getZExtValue();
    unsigned new_source_ty_size = source_ty_size;
    while (dest_ty_size > source_ty_size &&
           dest_ty_size % source_ty_size == 0 && value > 0 && value % 2 == 0 &&
           new_source_ty_size < 32) {
      value /= 2;
      new_source_ty_size *= 2;
    }
    if (source_ty_size != new_source_ty_size) {
      SmallVector<Value *, 2> Indices;
      Indices.clear();
      Indices.push_back(
          ConstantInt::get(Type::getInt32Ty(M.getContext()), value));
      auto new_type = Type::getIntNTy(M.getContext(), new_source_ty_size);
      auto new_gep = GetElementPtrInst::Create(
          new_type, GEP->getPointerOperand(), Indices, "", I);

      unsigned PointerOperandNum = BitcastUtils::PointerOperandNum(I);
      I->setOperand(PointerOperandNum, new_gep);

      if (GEP->getNumUses() == 0) {
        GEP->eraseFromParent();
      }

      changed = true;
    }
  }

  // Implicit GEPs (i.e. GEPs that are elided because all indices are zero) are
  // handled by explcitly inserting the GEP.
  for (auto GEPInfo : ImplicitGEPs) {
    auto *I = GEPInfo.first;
    auto Steps = GEPInfo.second.first;
    auto *gep = GEPInfo.second.second;
    IRBuilder<> Builder{I};
    SmallVector<Value *, 8> GEPIndices{};
    unsigned PointerOperandNum = BitcastUtils::PointerOperandNum(I);

    for (int i = 0; i < Steps + 1; i++) {
      GEPIndices.push_back(Builder.getInt32(0));
    }

    Value *PointerOp = I->getOperand(PointerOperandNum);
    auto *PointerOpType =
        clspv::InferType(PointerOp, M.getContext(), &type_cache);
    auto *NewGEP =
        GetElementPtrInst::Create(PointerOpType, PointerOp, GEPIndices, "", I);

    if (gep) {
      // Typical usecase here is a GEP on a struct of float, followed by a GEP
      // on a int. Replace the last GEP by a GEP on a float.
      auto *NewCastGEP = GetElementPtrInst::Create(
          NewGEP->getResultElementType(), NewGEP,
          SmallVector<Value *, 1>(gep->indices()), "", I);
      I->replaceAllUsesWith(NewCastGEP);
      I->eraseFromParent();
    } else {
      I->setOperand(PointerOperandNum, NewGEP);
    }
    changed = true;
  }

  return changed;
}
