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
    changed |= runOnImplicitGEP(M);
    while (runOnUpgradeableConstantCasts(M)) {
      changed = true;
    }
    changed |= runOnUnneededIndices(M);
    changed |= runOnImplicitCasts(M);
    changed |= runOnAllocaNotAliasing(M);
    changed |= runOnPHIFromGEP(M);
    changed |= runOnGEPFromGEP(M);
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
      OtherBitcast = CE->getAsInstruction();
      OtherBitcast->insertBefore(Bitcast->getIterator());
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
                           Bitcast->getType(), "", Bitcast->getIterator());

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

              auto LastTypeStruct = [](Type *Ty, SmallVector<Value *> Idxs) {
                Idxs.pop_back();
                return dyn_cast<StructType>(
                    GetElementPtrInst::getIndexedType(Ty, Idxs));
              };
              auto ConstantValue = [](Value *V) {
                if (auto CstVal = dyn_cast<ConstantInt>(V)) {
                  return CstVal->getZExtValue();
                }
                return UINT64_MAX;
              };
              auto LastTypeStructTy =
                  LastTypeStruct(OtherGEP->getSourceElementType(),
                                 SmallVector<Value *>(OtherGEP->indices()));
              if (GEP->getNumOperands() > 1 && LastTypeStructTy != nullptr &&
                  ((ConstantValue(GEP->getOperand(1)) >=
                        LastTypeStructTy->getStructNumElements() &&
                    IsArrayLike(LastTypeStructTy)) ||
                   (ConstantValue(GEP->getOperand(1)) != 0 &&
                    !IsArrayLike(LastTypeStructTy)))) {
                LLVM_DEBUG(dbgs() << "\n##runOnGEPFromGEP:\nskip (out-of-bound "
                                     "struct access): ";
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
      if (numEle > 1 || numEle == 0) {
        VecOrArraySize = numEle;
      }
    } else if (OtherGEP->getNumOperands() == 2) {
      VecOrArraySize =
          BitcastUtils::GetNumEle(OtherGEP->getSourceElementType());
    }

    SmallVector<Value *, 8> Idxs;
    if (CstSrcLastIdxOp && CstGEPIdxOp &&
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
    } else if (CstGEPIdxOp && CstGEPIdxOp->isZero()) {
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end());
    } else if (VecOrArraySize == 0) {
      Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
      if (CstSrcLastIdxOp && CstGEPIdxOp) {
        Idxs.push_back(ConstantInt::get(
            IntegerType::get(M.getContext(),
                             clspv::PointersAre64Bit(M) &&
                                     !OtherGEP->getType()->isStructTy()
                                 ? 64
                                 : 32),
            CstGEPIdxOp->getZExtValue() + CstSrcLastIdxOp->getZExtValue()));
      } else if (CstSrcLastIdxOp && CstSrcLastIdxOp->isZero()) {
        Idxs.push_back(*(GEP->op_begin() + 1));
      } else if (CstGEPIdxOp && CstGEPIdxOp->isZero()) {
        Idxs.push_back(*(OtherGEP->op_end() - 1));
      } else {
        Idxs.push_back(CreateAdd(Builder, *(GEP->op_begin() + 1),
                                 *(OtherGEP->op_end() - 1)));
      }
    } else {
      uint32_t startIndex = 0;
      SmallVector<Value *, 8> TyIdxs;
      SmallVector<Type *, 8> Types;
      for (uint32_t i = 0; i < OtherGEP->getNumOperands() - 1; i++) {
        Value *op = OtherGEP->getOperand(i + 1);
        TyIdxs.push_back(op);
        Type *idxTy = GetElementPtrInst::getIndexedType(
            OtherGEP->getSourceElementType(), TyIdxs);
        Types.push_back(idxTy);
        if (i > 0 && isa<StructType>(Types[i - 1])) {
          startIndex = i + 1;
        }
        // If an unsized type appears due to a representation of a descriptor,
        // skip the outer struct.
        if (SizeInBits(M.getDataLayout(), idxTy) == 0) {
          startIndex = 0;
        }
      }

      if (startIndex != 0) {
        // We have to assume that these geps were simply split since we
        // traversed a struct. We would not calculate an appropriate offset into
        // a particular struct.
        Idxs.append(OtherGEP->op_begin() + 1, OtherGEP->op_end() - 1);
        if (CstSrcLastIdxOp && CstSrcLastIdxOp->isZero()) {
          Idxs.push_back(GEP->getOperand(1));
        } else {
          Idxs.push_back(
              Builder.CreateAdd(GEPIdxOp, *(OtherGEP->op_end() - 1)));
        }
      } else {
        uint64_t cstVal;
        Value *dynVal;
        size_t smallerBitWidths;
        ExtractOffsetFromGEP(M.getDataLayout(), Builder, OtherGEP, cstVal,
                             dynVal, smallerBitWidths);
        if (CstGEPIdxOp) {
          cstVal += CstGEPIdxOp->getZExtValue();
        } else if (dynVal) {
          dynVal = CreateAdd(Builder, dynVal, GEPIdxOp);
        } else {
          dynVal = GEPIdxOp;
        }
        auto NewGEPIdxs = GetIdxsForTyFromOffset(
            M.getDataLayout(), Builder, OtherGEP->getSourceElementType(),
            OtherGEP->getResultElementType(), cstVal, dynVal, smallerBitWidths,
            OtherGEP->getPointerOperand());
        Idxs.append(NewGEPIdxs);
      }
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
          "", GEP->getIterator());
    } else {
      NewGEP = GetElementPtrInst::Create(OtherGEP->getSourceElementType(),
                                         OtherGEP->getPointerOperand(), Idxs,
                                         "", GEP->getIterator());
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
  SmallVector<LoadInst *> GEPBeforeLoadList;
  SmallVector<GetElementPtrInst *> GEPCastList;
  SmallVector<GetElementPtrInst *> GEPGVList;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty, true,
                             false /* do not rework unsized types */)) {
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
          if (!userCall && (gep || PerfectMatch)) {
            GEPAliasingList.push_back(
                {&I, Steps, PerfectMatch ? nullptr : gep});
          }
        } else if (isa<StoreInst>(&I) && !isa<GetElementPtrInst>(source)) {
          GEPBeforeStoreList.push_back({&I, dest_ty});
        } else if (isa<LoadInst>(&I) && isa<GetElementPtrInst>(source) &&
                   SizeInBits(DL, dest_ty) < SizeInBits(DL, source_ty)) {
          GEPBeforeLoadList.push_back(dyn_cast<LoadInst>(&I));
        } else if (auto gep = dyn_cast<GetElementPtrInst>(&I)) {
          if (IsClspvResourceOrLocal(gep->getPointerOperand())) {
            GEPCastList.push_back(dyn_cast<GetElementPtrInst>(&I));
          } else if (IsGVConstantGEP(gep)) {
            GEPGVList.push_back(dyn_cast<GetElementPtrInst>(&I));
          }
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
    auto *NewGEP = GetElementPtrInst::Create(PointerOpType, PointerOp,
                                             GEPIndices, "", I->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (aliasing):\nadding: ";
               NewGEP->dump());

    if (gep) {
      // Typical usecase here is a GEP on a struct of float, followed by a GEP
      // on a int. Replace the last GEP by a GEP on a float.
      auto *NewCastGEP = GetElementPtrInst::Create(
          NewGEP->getResultElementType(), NewGEP,
          SmallVector<Value *, 1>(gep->indices()), "", I->getIterator());
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
    auto gep = GetElementPtrInst::Create(Ty, PointerOp, {Builder.getInt32(0)},
                                         "", I->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (before store):\nadding: ";
               gep->dump());
    LLVM_DEBUG(dbgs() << "instead of operand " << PointerOperandNum << " of: ";
               I->dump());
    I->setOperand(PointerOperandNum, gep);
    changed = true;
  }

  for (auto *LoadInst : GEPBeforeLoadList) {
    IRBuilder<> Builder{LoadInst};
    auto *Ty = LoadInst->getType();
    auto initial_gep =
        dyn_cast<GetElementPtrInst>(LoadInst->getPointerOperand());
    auto Ptr = initial_gep->getPointerOperand();

    uint64_t cstVal;
    Value *dynVal;
    size_t smallerBitWidths;
    ExtractOffsetFromGEP(M.getDataLayout(), Builder, initial_gep, cstVal,
                         dynVal, smallerBitWidths);
    auto newBitWidths = SizeInBits(DL, Ty);

    assert(smallerBitWidths > newBitWidths);
    cstVal *= smallerBitWidths / newBitWidths;
    if (dynVal) {
      dynVal = CreateMul(Builder, smallerBitWidths / newBitWidths, dynVal);
    }
    auto NewGEPIdxs =
        GetIdxsForTyFromOffset(M.getDataLayout(), Builder, Ty, Ty, cstVal,
                               dynVal, SizeInBits(DL, Ty), Ptr);

    auto gep = GetElementPtrInst::Create(Ty, Ptr, NewGEPIdxs, "",
                                         LoadInst->getIterator());
    unsigned PointerOperandNum = BitcastUtils::PointerOperandNum(LoadInst);
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (before load):\nadding: ";
               gep->dump());
    LLVM_DEBUG(dbgs() << "instead of operand " << PointerOperandNum << ": ";
               LoadInst->getPointerOperand()->dump(););
    LLVM_DEBUG(dbgs() << "of: "; LoadInst->dump(););
    LoadInst->setOperand(PointerOperandNum, gep);

    if (initial_gep->getNumUses() == 0) {
      initial_gep->eraseFromParent();
    }

    changed = true;
  }

  for (auto gep : GEPCastList) {
    auto ptr = gep->getPointerOperand();
    auto ty = InferType(ptr, M.getContext(), &type_cache);
    IRBuilder<> Builder{gep};
    uint64_t cstVal;
    Value *dynVal;
    size_t smallerBitWidths;
    ExtractOffsetFromGEP(DL, Builder, gep, cstVal, dynVal, smallerBitWidths);
    auto new_gep_idxs =
        GetIdxsForTyFromOffset(DL, Builder, ty, reworkUnsizedType(DL, ty),
                               cstVal, dynVal, smallerBitWidths, ptr);
    auto new_gep = GetElementPtrInst::Create(ty, ptr, new_gep_idxs, "",
                                             gep->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (gep cast):\nreplacing: ";
               gep->dump());
    LLVM_DEBUG(dbgs() << "by: "; new_gep->dump(););
    gep->replaceAllUsesWith(new_gep);
    gep->eraseFromParent();
    changed = true;
  }
  for (auto gep : GEPGVList) {
    auto ptr = gep->getPointerOperand();
    auto ty = InferType(ptr, M.getContext(), &type_cache);
    IRBuilder<> Builder{gep};
    uint64_t cstVal;
    Value *dynVal;
    size_t smallerBitWidths;
    ExtractOffsetFromGEP(DL, Builder, gep, cstVal, dynVal, smallerBitWidths);
    auto new_gep_idxs = GetIdxsForTyFromOffset(DL, Builder, ty, nullptr, cstVal,
                                               dynVal, smallerBitWidths, ptr);
    auto new_gep = GetElementPtrInst::Create(ty, ptr, new_gep_idxs, "",
                                             gep->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnImplicitGEP (from GV):\nreplacing: ";
               gep->dump());
    LLVM_DEBUG(dbgs() << "by: "; new_gep->dump(););
    gep->replaceAllUsesWith(new_gep);
    gep->eraseFromParent();
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
          SmallerBitWidths, src_gep->getPointerOperand());
    }
    auto new_gep = GetElementPtrInst::Create(src_ty, src, Idxs, "",
                                             inst_gep->getIterator());
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

  struct UpgradeInfo {
    Instruction *inst;
    uint64_t cst;
    Value *val;
    size_t smallerBitWidth;
    Type *dest_ty;
    GetElementPtrInst *gep;
  };
  auto gepIndicesCanBeUpgradedTo = [&DL, &M](Type *ty, GetElementPtrInst *gep,
                                             uint64_t &cstVal, Value *&dynVal,
                                             size_t &smallerBitWidths) {
    if (gep->hasAllConstantIndices()) {
      // should not be used as all indices are constant
      IRBuilder<> Builder{gep};

      ExtractOffsetFromGEP(DL, Builder, gep, cstVal, dynVal, smallerBitWidths);
      assert(dynVal == nullptr);
      if (((cstVal * smallerBitWidths) % SizeInBits(DL, ty)) != 0) {
        return false;
      }
    } else {
      // if gep contains dynamic indices, only consider i8 gep width and look
      // for mul and shl composing the single indice.
      if (gep->getSourceElementType() != Type::getInt8Ty(M.getContext()) ||
          gep->getNumIndices() != 1) {
        return false;
      }
      cstVal = 0;
      smallerBitWidths = CHAR_BIT;
      dynVal = gep->getOperand(gep->getNumOperands() - 1);

      SmallVector<Value *> vector;
      vector.push_back(dynVal);
      uint32_t coef = CHAR_BIT;
      uint32_t coef_target = SizeInBits(DL, ty);
      while (!vector.empty()) {
        auto val = vector.back();
        vector.pop_back();
        if (auto cst = dyn_cast<ConstantInt>(val)) {
          coef *= cst->getZExtValue();
          continue;
        }
        auto binary_op = dyn_cast<BinaryOperator>(val);
        if (!binary_op) {
          continue;
        }
        switch (binary_op->getOpcode()) {
        case Instruction::BinaryOps::Mul:
          vector.push_back(binary_op->getOperand(0));
          vector.push_back(binary_op->getOperand(1));
          break;
        case Instruction::BinaryOps::Shl:
          vector.push_back(binary_op->getOperand(0));
          if (auto cst = dyn_cast<ConstantInt>(binary_op->getOperand(1))) {
            coef <<= cst->getZExtValue();
          }
          break;
        default:
          continue;
        }
      }
      if ((coef % coef_target) != 0) {
        return false;
      }
    }
    return true;
  };
  SmallVector<UpgradeInfo, 8> Worklist;
  SmallVector<UpgradeInfo, 8> GEPsDefiningPHIsWorklist;
  DenseSet<GetElementPtrInst *> GEPsDefiningPHISeen;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;

        auto isMemcpy = [](Instruction *I) {
          auto memcpy = dyn_cast<CallInst>(I);
          if (memcpy == nullptr)
            return false;
          return memcpy->getCalledFunction()->getIntrinsicID() ==
                 Intrinsic::memcpy;
        };
        // memcpy cannot be simplify by this function, skip them to avoid having
        // to support them in function like `BitcastUtils::PointerOperandNum`.
        if (!IsImplicitCasts(M, type_cache, I, source, source_ty, dest_ty,
                             true) ||
            isMemcpy(&I)) {
          continue;
        }

        if (auto *gep = dyn_cast<GetElementPtrInst>(source)) {
          if (SizeInBits(DL, source_ty) >= SizeInBits(DL, dest_ty) ||
              IsClspvResourceOrLocal(gep->getPointerOperand())) {
            continue;
          }
          if (IsGVConstantGEP(gep))
            continue;

          uint64_t cstVal;
          Value *dynVal;
          size_t smallerBitWidths;

          auto &context = M.getContext();
          auto findBiggerTyToUpdate = [DL, &context, gepIndicesCanBeUpgradedTo,
                                       source_ty, gep, &cstVal, &dynVal,
                                       &smallerBitWidths](Type *dest_ty) {
            if (gepIndicesCanBeUpgradedTo(dest_ty, gep, cstVal, dynVal,
                                          smallerBitWidths)) {
              return dest_ty;
            }
            if (!dest_ty->isIntegerTy()) {
              return source_ty;
            }
            size_t dest_ty_size = SizeInBits(DL, dest_ty);
            dest_ty_size /= 2;
            dest_ty = Type::getIntNTy(context, dest_ty_size);

            while (dest_ty != source_ty) {
              if (gepIndicesCanBeUpgradedTo(dest_ty, gep, cstVal, dynVal,
                                            smallerBitWidths)) {
                return dest_ty;
              }
              dest_ty_size /= 2;
              dest_ty = Type::getIntNTy(context, dest_ty_size);
            }

            return source_ty;
          };
          dest_ty = findBiggerTyToUpdate(dest_ty);
          if (dest_ty != source_ty) {

            Worklist.push_back(
                {&I, cstVal, dynVal, smallerBitWidths, dest_ty, gep});
          }
        } else if (auto *phi = dyn_cast<PHINode>(source)) {
          auto &context = M.getContext();
          auto get_geps_defining_phis_type = [phi, source_ty, dest_ty, &context,
                                              &type_cache, &GEPsDefiningPHISeen,
                                              gepIndicesCanBeUpgradedTo]() {
            SmallVector<UpgradeInfo> geps;
            SmallVector<Value *> values;
            SmallVector<PHINode *> phis;
            DenseSet<PHINode *> phis_seen;
            phis.push_back(phi);
            // phi can depend on other phis recursively, go through them to find
            // all the values that needing to be upgraded to change the phi
            // type.
            while (!phis.empty()) {
              auto current_phi = phis.back();
              phis.pop_back();
              if (phis_seen.count(current_phi) != 0) {
                continue;
              }
              phis_seen.insert(current_phi);
              for (auto &incoming_value : current_phi->incoming_values()) {
                auto val = incoming_value.get();
                if (auto phi_node = dyn_cast<PHINode>(val)) {
                  phis.push_back(phi_node);
                } else {
                  values.push_back(val);
                }
              }
              for (auto user : current_phi->users()) {
                if (auto phi_node = dyn_cast<PHINode>(user)) {
                  phis.push_back(phi_node);
                } else {
                  values.push_back(user);
                }
              }
            }
            for (auto value : values) {
              auto user_ty = clspv::InferType(value, context, &type_cache);
              if (user_ty != source_ty) {
                continue;
              }
              auto gep = dyn_cast<GetElementPtrInst>(value);
              uint64_t cstVal;
              Value *dynVal;
              size_t smallerBitWidths;
              if (gep == nullptr ||
                  !gepIndicesCanBeUpgradedTo(dest_ty, gep, cstVal, dynVal,
                                             smallerBitWidths)) {
                geps.clear();
                return geps;
              }
              if (GEPsDefiningPHISeen.count(gep) == 0) {
                GEPsDefiningPHISeen.insert(gep);
                geps.push_back(
                    {gep, cstVal, dynVal, smallerBitWidths, dest_ty, gep});
              }
            }
            return geps;
          };
          GEPsDefiningPHIsWorklist.append(get_geps_defining_phis_type());
        }
      }
    }
  }

  for (auto GEPInfo : GEPsDefiningPHIsWorklist) {
    auto gep = dyn_cast<GetElementPtrInst>(GEPInfo.inst);
    uint64_t cst = GEPInfo.cst;
    Value *val = GEPInfo.val;
    size_t smallerBitWidths = GEPInfo.smallerBitWidth;
    Type *dest_ty = GEPInfo.dest_ty;
    Value *ptr = GEPInfo.gep->getPointerOperand();
    IRBuilder Builder{gep};

    auto NewGEPIdxs =
        GetIdxsForTyFromOffset(M.getDataLayout(), Builder, dest_ty, dest_ty,
                               cst, val, smallerBitWidths, ptr);

    auto new_gep = GetElementPtrInst::Create(dest_ty, ptr, NewGEPIdxs, "",
                                             gep->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnUpgradeableConstantCasts:\nreplace gep "
                         "defining phi type: ";
               gep->dump(); dbgs() << "by: "; new_gep->dump());

    gep->replaceAllUsesWith(new_gep);
    gep->eraseFromParent();

    changed = true;
  }
  if (changed) {
    return changed;
  }

  DenseSet<Instruction *> ToBeRemoved;
  for (auto GEPInfo : Worklist) {
    Instruction *I = GEPInfo.inst;
    uint64_t cst = GEPInfo.cst;
    Value *val = GEPInfo.val;
    size_t smallerBitWidths = GEPInfo.smallerBitWidth;
    Type *dest_ty = GEPInfo.dest_ty;
    Value *ptr = GEPInfo.gep->getPointerOperand();
    IRBuilder Builder{GEPInfo.gep};

    auto NewGEPIdxs =
        GetIdxsForTyFromOffset(M.getDataLayout(), Builder, dest_ty, dest_ty,
                               cst, val, smallerBitWidths, ptr);

    auto new_gep = GetElementPtrInst::Create(dest_ty, ptr, NewGEPIdxs, "",
                                             GEPInfo.gep->getIterator());

    unsigned PointerOperandNum = BitcastUtils::PointerOperandNum(I);
    if (auto phi = dyn_cast<PHINode>(I)) {
      for (uint32_t iOp = 0; iOp < phi->getNumOperands(); iOp++) {
        if (I->getOperand(iOp) == GEPInfo.gep) {
          PointerOperandNum = iOp;
        }
      }
    }

    LLVM_DEBUG(dbgs() << "\n##runOnUpgradeableConstantCasts:\nreplace operand "
                      << PointerOperandNum << " of: ";
               I->dump(); dbgs() << "by: "; new_gep->dump());
    auto initial_inst = dyn_cast<Instruction>(I->getOperand(PointerOperandNum));
    I->setOperand(PointerOperandNum, new_gep);

    if (initial_inst != nullptr) {
      ToBeRemoved.insert(initial_inst);
      if (initial_inst->getNumUses() > 0) {
        initial_inst->replaceAllUsesWith(new_gep);
      }
    }

    changed = true;
  }

  for (auto *I : ToBeRemoved) {
    I->eraseFromParent();
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
          if (IsGVConstantGEP(gep))
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
    auto new_gep = GetElementPtrInst::Create(gep->getSourceElementType(),
                                             gep->getPointerOperand(), Indices,
                                             "", gep->getIterator());
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

  struct ImplicitGEPAliasing {
    PHINode *phi;
    int steps;
    GetElementPtrInst *gep;
  };

  DenseSet<GetElementPtrInst *> Seen;
  SmallVector<ImplicitGEPAliasing> GEPAliasingList;
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
          if (Seen.contains(gep)) {
            continue;
          }
          if (auto phi = dyn_cast<PHINode>(&I)) {

            int Steps;
            bool PerfectMatch;
            if (FindAliasingContainedType(source_ty, dest_ty, Steps,
                                          PerfectMatch, DL) &&
                PerfectMatch) {
              GEPAliasingList.push_back({phi, Steps, gep});
            } else if (!FindAliasingContainedType(dest_ty, source_ty, Steps,
                                                  PerfectMatch, DL)) {

              Worklist.emplace_back(std::make_pair(gep, dest_ty));
            }
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
    auto Idxs =
        GetIdxsForTyFromOffset(DL, Builder, Ty, nullptr, CstVal, DynVal,
                               SmallerBitWidths, gep->getPointerOperand());
    auto new_gep = GetElementPtrInst::Create(Ty, gep->getPointerOperand(), Idxs,
                                             "", gep->getIterator());
    LLVM_DEBUG(dbgs() << "\n##runOnPHIFromGEP:\nreplace: "; gep->dump();
               dbgs() << "by: "; new_gep->dump());
    gep->replaceAllUsesWith(new_gep);
    gep->eraseFromParent();
    changed = true;
  }

  for (auto GEPInfo : GEPAliasingList) {
    auto *phi = GEPInfo.phi;
    auto Steps = GEPInfo.steps;
    auto *gep = GEPInfo.gep;
    IRBuilder<> B(gep);
    SmallVector<Value *> Idxs;
    for (int i = 0; i < Steps + 1; i++) {
      Idxs.push_back(B.getInt32(0));
    }
    auto new_gep =
        GetElementPtrInst::Create(gep->getResultElementType(), gep, Idxs, "",
                                  gep->getNextNode()->getIterator());
    for (unsigned i = 0; i < phi->getNumIncomingValues(); i++) {
      if (phi->getIncomingValue(i) != gep) {
        continue;
      }
      changed = true;
      LLVM_DEBUG(dbgs() << "\n##runOnPHIFromGEPAliasing:\nreplace: ";
                 gep->dump(); dbgs() << "by: "; new_gep->dump();
                 dbgs() << "in: "; phi->dump());

      phi->setIncomingValue(i, new_gep);
    }
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
        if (!alloca || !gep || (gep && gep->getNumUses() == 0)) {
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
