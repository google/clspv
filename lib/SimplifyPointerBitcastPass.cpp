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
    changed |= runOnAllocaNotAliasing(M);
    changed |= runOnGEPFromGEP(M);
    changed |= runOnUnneededCasts(M);
    changed |= runOnImplicitGEP(M);
    changed |= runOnUpgradeableConstantCasts(M);
    changed |= runOnUnneededIndices(M);
    changed |= runOnImplicitCasts(M);
    changed |= runOnPHIFromGEP(M);
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
    LLVM_DEBUG(dbgs() << "\n##runOnTrivialBitcast:\nreplaceAllUses of :";
               Bitcast->dump(); dbgs() << "by: "; Source->dump());
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
    LLVM_DEBUG(dbgs() << "\n##runOnBitcastFromBitcast:\nremove:";
               Bitcast->dump());

    if (OtherBitcast->getType() == Bitcast->getType()) {
      Bitcast->replaceAllUsesWith(OtherBitcast);
      LLVM_DEBUG(dbgs() << "in favor of: "; OtherBitcast->dump());
    } else {
      // Create a new bitcast from the other bitcasts argument to our type.
      auto NewBitcast =
          CastInst::Create(Instruction::BitCast, OtherBitcast->getOperand(0),
                           Bitcast->getType(), "", Bitcast);

      // And replace the original bitcast with our replacement bitcast.
      Bitcast->replaceAllUsesWith(NewBitcast);
      LLVM_DEBUG(dbgs() << "in favor of: "; NewBitcast->dump());
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
          if (auto OtherGEP =
                  dyn_cast<GetElementPtrInst>(GEP->getPointerOperand())) {
            // ... with no implicit cast between them...
            if (OtherGEP->getResultElementType() ==
                GEP->getSourceElementType()) {

              auto LastTypeIsStruct = [](Type *Ty, SmallVector<Value *> Idxs) {
                Idxs.pop_back();
                return isa<StructType>(
                    GetElementPtrInst::getIndexedType(Ty, Idxs));
              };
              auto NotZero = [](Value *V) {
                if (auto CstVal = dyn_cast<ConstantInt>(V)) {
                  if (CstVal->getZExtValue() == 0)
                    return false;
                }
                return true;
              };
              if (GEP->getNumOperands() > 1 && NotZero(GEP->getOperand(1)) &&
                  LastTypeIsStruct(OtherGEP->getSourceElementType(),
                                   SmallVector<Value *>(OtherGEP->indices()))) {
                LLVM_DEBUG(dbgs() << "\n##runOnGEPFromGEP:\nskip (struct "
                                     "follow by not zero): ";
                           OtherGEP->dump(); GEP->dump());
                continue;
              }
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
    LLVM_DEBUG(dbgs() << "\n##runOnGEPFromGEP:\nreplace: "; OtherGEP->dump();
               GEP->dump());

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
    LLVM_DEBUG(dbgs() << "by: "; NewGEP->dump());

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

bool clspv::SimplifyPointerBitcastPass::runOnUnneededCasts(Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;
  SmallVector<GetElementPtrInst *, 8> Worklist;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        if (auto *gep = dyn_cast<GetElementPtrInst>(&I)) {
          if (source_ty == gep->getResultElementType()) {
            Worklist.push_back(gep);
          }
        }
      }
    }
  }

  for (auto *GEP : Worklist) {
    IRBuilder<> Builder(GEP);
    LLVM_DEBUG(dbgs() << "\n##runOnUnneededCasts:\nreplace: "; GEP->dump());
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
    LLVM_DEBUG(dbgs() << "by: "; NewGEP->dump());
    GEP->replaceAllUsesWith(NewGEP);
    GEP->eraseFromParent();

    changed = true;
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnImplicitGEP(Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;

  struct ImplicitGEPAliasing {
    Instruction *inst;
    int steps;
    GetElementPtrInst *gep;
  };
  struct ImplicitGEPBeforeStore {
    Instruction *inst;
    Type *ty;
  };

  SmallVector<ImplicitGEPAliasing> GEPAliasingList;
  SmallVector<ImplicitGEPBeforeStore> GEPBeforeStoreList;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        int Steps = 0;
        bool PerfectMatch;
        if (FindAliasingContainedType(source_ty, dest_ty, Steps, PerfectMatch,
                                      DL)) {
          // PHI Node are handle in runOnPHIFromGEP if it is really needed
          if (isa<PHINode>(&I)) {
            continue;
          }

          // Single level GEP is ok to transform, but beyond
          // that the address math must be divided among other
          // entries.
          auto *gep = dyn_cast<GetElementPtrInst>(&I);
          auto *call = dyn_cast_or_null<CallInst>(&I);
          bool userCall = call && !call->getCalledFunction()->isDeclaration();
          if ((Steps > 0 && !gep) || (Steps == 1)) {
            if (!userCall && (gep || PerfectMatch)) {
              GEPAliasingList.push_back(
                  {&I, Steps, PerfectMatch ? nullptr : gep});
            }
          }
        } else if (isa<StoreInst>(&I) && !isa<GetElementPtrInst>(source)) {
          GEPBeforeStoreList.push_back({&I, dest_ty});
        }
      }
    }
  }

  // Implicit GEPs (i.e. GEPs that are elided because all indices are zero) are
  // handled by explcitly inserting the GEP.
  for (auto GEPInfo : GEPAliasingList) {
    auto *I = GEPInfo.inst;
    auto Steps = GEPInfo.steps;
    auto *gep = GEPInfo.gep;
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
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (aliasing):\nadding: ";
               NewGEP->dump());

    if (gep) {
      // Typical usecase here is a GEP on a struct of float, followed by a GEP
      // on a int. Replace the last GEP by a GEP on a float.
      auto *NewCastGEP = GetElementPtrInst::Create(
          NewGEP->getResultElementType(), NewGEP,
          SmallVector<Value *, 1>(gep->indices()), "", I);
      LLVM_DEBUG(dbgs() << "instead of: "; I->dump());
      I->replaceAllUsesWith(NewCastGEP);
      I->eraseFromParent();
    } else {
      LLVM_DEBUG(dbgs() << "instead of operand " << PointerOperandNum
                        << " of: ";
                 I->dump());
      I->setOperand(PointerOperandNum, NewGEP);
    }
    changed = true;
  }

  for (auto GEPInfo : GEPBeforeStoreList) {
    auto *I = GEPInfo.inst;
    auto *Ty = GEPInfo.ty;
    IRBuilder<> Builder{I};
    unsigned PointerOperandNum = BitcastUtils::PointerOperandNum(I);
    Value *PointerOp = I->getOperand(PointerOperandNum);
    auto gep =
        GetElementPtrInst::Create(Ty, PointerOp, {Builder.getInt32(0)}, "", I);
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (before store):\nadding: ";
               gep->dump());
    LLVM_DEBUG(dbgs() << "instead of operand " << PointerOperandNum << " of: ";
               I->dump());
    I->setOperand(PointerOperandNum, gep);
    changed = true;
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnImplicitCasts(Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;

  SmallVector<GetElementPtrInst *, 8> Worklist;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;

        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        if (isa<GetElementPtrInst>(source)) {
          if (auto *inst_gep = dyn_cast<GetElementPtrInst>(&I)) {
            auto VecSrcTy = dyn_cast<FixedVectorType>(source_ty);
            auto VecDstTy = dyn_cast<FixedVectorType>(dest_ty);

            // Do not lower implicit cast containing vec3, this would revert
            // ThreeElementVectorLoweringPass and ReplacePointerBitcastPass
            // should be able to deal with it without issues.
            if (!(VecSrcTy && VecDstTy &&
                  (VecSrcTy->getNumElements() == 3 ||
                   VecDstTy->getNumElements() == 3))) {
              Worklist.emplace_back(inst_gep);
            }
          }
        }
      }
    }
  }

  for (auto inst_gep : Worklist) {
    GetElementPtrInst *src_gep =
        cast<GetElementPtrInst>(inst_gep->getPointerOperand());

    IRBuilder<> Builder{inst_gep};
    SmallVector<Value *> Idxs;
    Value *src;
    Type *src_ty;
    if (src_gep->hasAllZeroIndices()) {
      src_ty = inst_gep->getSourceElementType();
      src = src_gep->getPointerOperand();
      Idxs = SmallVector<Value *>(inst_gep->indices());
    } else {
      src_ty = src_gep->getResultElementType();
      src = src_gep;
      uint64_t CstVal;
      Value *DynVal;
      size_t SmallerBitWidths;
      ExtractOffsetFromGEP(DL, Builder, inst_gep, CstVal, DynVal,
                           SmallerBitWidths);

      if (DynVal == nullptr &&
          GoThroughTypeAtOffset(DL, Builder, src_ty, nullptr,
                                CstVal * SmallerBitWidths, nullptr) != 0) {
        src = src_gep->getPointerOperand();
        src_ty = inst_gep->getSourceElementType();
        uint64_t srcCstVal;
        Value *srcDynVal;
        size_t srcSmallerBitWidths;
        ExtractOffsetFromGEP(DL, Builder, src_gep, srcCstVal, srcDynVal,
                             srcSmallerBitWidths);
        if (SmallerBitWidths < srcSmallerBitWidths) {
          srcCstVal *= srcSmallerBitWidths / SmallerBitWidths;
          if (srcDynVal) {
            srcDynVal = CreateMul(
                Builder, srcSmallerBitWidths / SmallerBitWidths, srcDynVal);
          }
        } else if (SmallerBitWidths > srcSmallerBitWidths) {
          CstVal *= SmallerBitWidths / srcSmallerBitWidths;
          if (DynVal) {
            DynVal = CreateMul(Builder, SmallerBitWidths / srcSmallerBitWidths,
                               DynVal);
          }
        }
        CstVal += srcCstVal;
        if (DynVal && srcDynVal) {
          DynVal = Builder.CreateAdd(DynVal, srcDynVal);
        } else if (srcDynVal) {
          DynVal = srcDynVal;
        }
      }
      Idxs = GetIdxsForTyFromOffset(
          DL, Builder, src_ty, inst_gep->getResultElementType(), CstVal, DynVal,
          SmallerBitWidths,
          (clspv::AddressSpace::Type)inst_gep->getPointerOperand()
              ->getType()
              ->getPointerAddressSpace());
    }
    auto new_gep = GetElementPtrInst::Create(src_ty, src, Idxs, "", inst_gep);
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitCasts:\nreplace: "; inst_gep->dump();
               dbgs() << "by: "; new_gep->dump());
    inst_gep->replaceAllUsesWith(new_gep);
    inst_gep->eraseFromParent();
    changed = true;
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnUpgradeableConstantCasts(
    Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;

  DenseSet<GetElementPtrInst *> seen;
  struct UpgradeInfo {
    GetElementPtrInst *gep;
    Instruction *inst;
    ConstantInt *constant;
    Type *source_ty;
    Type *dest_ty;
  };
  SmallVector<UpgradeInfo, 8> Worklist;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        if (auto *gep = dyn_cast<GetElementPtrInst>(source)) {
          if (!seen.insert(gep).second) {
            continue;
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
              Worklist.push_back({gep, &I, cst, source_ty, dest_ty});
            }
          }
        }
      }
    }
  }

  for (auto GEPInfo : Worklist) {
    auto *GEP = GEPInfo.gep;
    Instruction *I = GEPInfo.inst;
    ConstantInt *cst = GEPInfo.constant;
    Type *source_ty = GEPInfo.source_ty;
    Type *dest_ty = GEPInfo.dest_ty;
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

      LLVM_DEBUG(
          dbgs() << "\n##runOnUpgradeableConstantCasts:\nreplace operand "
                 << PointerOperandNum << " of: ";
          I->dump(); dbgs() << "by: "; new_gep->dump());
      I->setOperand(PointerOperandNum, new_gep);

      if (GEP->getNumUses() == 0) {
        GEP->eraseFromParent();
      }

      changed = true;
    }
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnUnneededIndices(Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;

  SmallVector<std::pair<GetElementPtrInst *, Instruction *>> Worklist;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }
        if (auto gep = dyn_cast<GetElementPtrInst>(source)) {
          if (gep->getNumIndices() <= 1)
            continue;
          if (SizeInBits(DL, source_ty) < SizeInBits(DL, dest_ty)) {
            if (auto cst = dyn_cast<ConstantInt>(
                    gep->getOperand(gep->getNumOperands() - 1))) {
              if (cst->getZExtValue() == 0) {
                Worklist.push_back(std::make_pair(gep, &I));
              }
            }
          }
        }
      }
    }
  }

  for (auto pair : Worklist) {
    GetElementPtrInst *gep = pair.first;
    Instruction *I = pair.second;
    SmallVector<Value *> Indices(gep->indices());
    while (Indices.size() > 1) {
      auto lastIndice = Indices.back();
      if (auto cst = dyn_cast<ConstantInt>(lastIndice)) {
        if (cst->getZExtValue() == 0) {
          Indices.pop_back();
        } else {
          break;
        }
      } else {
        break;
      }
    }
    IRBuilder<> Builder{gep};
    auto new_gep =
        GetElementPtrInst::Create(gep->getSourceElementType(),
                                  gep->getPointerOperand(), Indices, "", gep);
    LLVM_DEBUG(dbgs() << "\nrunOnUnneededIndices:\nreplace: "; gep->dump();
               dbgs() << "by: "; new_gep->dump(); dbgs() << "in: "; I->dump());
    I->replaceUsesOfWith(gep, new_gep);
    if (gep->getNumUses() == 0) {
      gep->eraseFromParent();
    }
    changed = true;
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnPHIFromGEP(Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  bool changed = false;
  DenseMap<Value *, Type *> type_cache;

  DenseSet<GetElementPtrInst *> Seen;
  SmallVector<std::pair<GetElementPtrInst *, Type *>> Worklist;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;

        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        if (auto gep = dyn_cast<GetElementPtrInst>(source)) {
          if (isa<PHINode>(&I) && !Seen.contains(gep)) {
            Worklist.emplace_back(std::make_pair(gep, dest_ty));
            Seen.insert(gep);
          }
        }
      }
    }
  }

  for (auto pair : Worklist) {
    GetElementPtrInst *gep = pair.first;
    Type *Ty = pair.second;

    IRBuilder<> Builder{gep};
    uint64_t CstVal;
    Value *DynVal;
    size_t SmallerBitWidths;
    ExtractOffsetFromGEP(DL, Builder, gep, CstVal, DynVal, SmallerBitWidths);
    auto Idxs = GetIdxsForTyFromOffset(
        DL, Builder, Ty, Ty, CstVal, DynVal, SmallerBitWidths,
        (clspv::AddressSpace::Type)gep->getPointerOperand()
            ->getType()
            ->getPointerAddressSpace());
    auto new_gep =
        GetElementPtrInst::Create(Ty, gep->getPointerOperand(), Idxs, "", gep);
    LLVM_DEBUG(dbgs() << "\n##runOnPHIFromGEP:\nreplace: "; gep->dump();
               dbgs() << "by: "; new_gep->dump());
    gep->replaceAllUsesWith(new_gep);
    gep->eraseFromParent();
    changed = true;
  }

  return changed;
}

bool clspv::SimplifyPointerBitcastPass::runOnAllocaNotAliasing(
    Module &M) const {
  const DataLayout &DL = M.getDataLayout();
  DenseMap<Value *, Type *> type_cache;

  DenseMap<AllocaInst *, Type *> Allocas;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;

        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true)) {
          continue;
        }

        auto alloca = dyn_cast<AllocaInst>(source);
        auto gep = dyn_cast<GetElementPtrInst>(&I);
        if (!alloca || !gep) {
          continue;
        }
        int Steps;
        bool PerfectMatch;
        dest_ty = gep->getResultElementType();
        Type *source_ele_ty = GetEleType(source_ty);
        while (source_ele_ty != source_ty) {
          source_ty = source_ele_ty;
          source_ele_ty = GetEleType(source_ty);
        }
        if (FindAliasingContainedType(source_ty, dest_ty, Steps, PerfectMatch,
                                      DL) ||
            SizeInBits(DL, dest_ty) >= SizeInBits(DL, source_ty)) {
          continue;
        }
        if (Allocas.count(alloca) == 0) {
          Allocas.insert(std::make_pair(cast<AllocaInst>(source), dest_ty));
        } else if (SizeInBits(DL, dest_ty) < SizeInBits(DL, Allocas[alloca])) {
          Allocas[alloca] = dest_ty;
        }
      }
    }
  }

  for (auto &pair : Allocas) {
    auto *alloca = pair.first;
    auto *Ty = pair.second;

    IRBuilder<> B(alloca);
    auto nb_elem =
        alloca->getAllocationSizeInBits(DL).value() / SizeInBits(DL, Ty);
    if (nb_elem > 1) {
      Ty = ArrayType::get(Ty, nb_elem);
    }
    auto new_alloca = B.CreateAlloca(Ty, alloca->getAddressSpace());

    LLVM_DEBUG(dbgs() << "\n##runOnAllocaNotAliasing:\nreplace: ";
               alloca->dump(); dbgs() << "by: "; new_alloca->dump());

    alloca->replaceAllUsesWith(new_alloca);
    alloca->eraseFromParent();
  }

  return Allocas.size() != 0;
}
