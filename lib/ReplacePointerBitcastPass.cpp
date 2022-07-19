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

#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

#include "ReplacePointerBitcastPass.h"
#include "BitcastUtils.h"
#include "Types.h"

using namespace llvm;
using namespace BitcastUtils;

#define DEBUG_TYPE "replacepointerbitcast"

using WeakInstructions = SmallVector<WeakTrackingVH, 16>;

namespace {

bool IsPowerOfTwo(unsigned x) { return (x & (x - 1)) == 0; }

Value *CreateDiv(IRBuilder<> &Builder, unsigned div, Value *Val) {
  if (div == 1) {
    return Val;
  }
  if (IsPowerOfTwo(div)) {
    return Builder.CreateLShr(Val, Builder.getInt32(std::log2(div)));
  } else {
    return Builder.CreateUDiv(Val, Builder.getInt32(div));
  }
}

Value *CreateMul(IRBuilder<> &Builder, unsigned mul, Value *Val) {
  if (mul == 1) {
    return Val;
  }
  if (IsPowerOfTwo(mul)) {
    return Builder.CreateShl(Val, Builder.getInt32(std::log2(mul)));
  } else {
    return Builder.CreateMul(Val, Builder.getInt32(mul));
  }
}

Value *CreateRem(IRBuilder<> &Builder, unsigned rem, Value *Val) {
  if (rem == 1) {
    return Builder.getInt32(0);
  }
  if (IsPowerOfTwo(rem)) {
    return Builder.CreateAnd(Val, Builder.getInt32(rem - 1));
  } else {
    return Builder.CreateURem(Val, Builder.getInt32(rem));
  }
}

// 'Val' is expected to be a vector.
// 'Idx' is the index where to extract the subvector, but in the casted type
// coordinate. If null, just extract from the origin of the vector.
// At the end of the function, 'Idx' has been updated with the potential
// remainder of the index to get to the expected element.
Value *ExtractSubVector(IRBuilder<> &Builder, Value *&Idx, Value *Val,
                        unsigned DstSize) {
  LLVM_DEBUG(
      fprintf(stderr, "%s: ", __func__); Val->dump();
      fprintf(stderr, "\tIdx: ");
      if (Idx != NULL) { Idx->dump(); } else { fprintf(stderr, "nullptr\n"); });

  Type *ValueTy = Val->getType();
  assert(ValueTy->isVectorTy() && GetNumEle(ValueTy) == 4);

  if (Idx == NULL) {
    Val = Builder.CreateShuffleVector(Val, {0, 1});
  } else {
    // Compute with subvector to keep ({0, 1} or {2, 3}) and update Idx.
    unsigned SrcSize = SizeInBits(Builder, ValueTy);
    assert((SrcSize / 2) % DstSize == 0);
    unsigned NumDstInHalfSrc = SrcSize / (2 * DstSize);
    auto ValIdx = CreateDiv(Builder, NumDstInHalfSrc, Idx);
    Idx = CreateRem(Builder, NumDstInHalfSrc, Idx);

    // Select the appropriate subvector
    Value *Val0 = Builder.CreateShuffleVector(Val, {0, 1});
    Value *Val1 = Builder.CreateShuffleVector(Val, {2, 3});
    Value *Cmp = Builder.CreateICmpEQ(ValIdx, Builder.getInt32(0));
    Val = Builder.CreateSelect(Cmp, Val0, Val1);
  }
  return Val;
}

// 'Values' is expected to contain either vectors or scalars.
// At the end of the function, 'Idx' has been updated with the potential
// remainder of the index to get to the expected element.
// Return the sub element into the first element of 'Values'.
void ExtractSubElementUntilEleSizeLE(Type *Ty, IRBuilder<> &Builder,
                                     SmallVector<Value *, 8> &Values,
                                     Value *&Idx) {
  Type *ValueTy = Values[0]->getType();

  unsigned SrcSize = SizeInBits(Builder, ValueTy);
  unsigned SrcEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned SrcNumEle = GetNumEle(ValueTy);

  unsigned DstSize = SizeInBits(Builder, Ty);
  unsigned DstEleSize = SizeInBits(Builder, GetEleType(Ty));

  while (SrcEleSize > DstSize) {
    if (!ValueTy->isVectorTy()) {
      // ValueTy: i32 - Ty: i8
      // i32 -> <4 x i8>
      assert(SrcSize % DstSize == 0);
      BitcastIntoVector(Builder, Values,
                        std::min(SrcSize / DstEleSize, (unsigned)4), Ty);
    } else {
      // ValueTy->isVectorTy()
      if (SrcNumEle == 2) {
        // <2 x i32> -> <4 x i16>
        BitcastIntoVector(Builder, Values, 4, Ty);
      } else if (SrcNumEle == 4) {
        // <4 x i32> -> {<2 x i32>, <2 x i32>}[Idx] -> <2 x i32>
        Values[0] = ExtractSubVector(Builder, Idx, Values[0], DstSize);
      } else {
        llvm_unreachable("ExtractSubElement internal error");
      }
    }
    ValueTy = Values[0]->getType();
    SrcNumEle = GetNumEle(ValueTy);
    SrcEleSize = SizeInBits(Builder, GetEleType(ValueTy));
    SrcSize = SizeInBits(Builder, ValueTy);
  }
}

// 'Val' is expected to be a vector.
// At the end of the function, 'Idx' has been updated with the potential
// remainder of the index to get to the expected element.
Value *ExtractElementOrSubVector(Type *Ty, IRBuilder<> &Builder, Value *Val,
                                 Value *&Idx) {
  Type *ValueTy = Val->getType();
  unsigned DstSize = SizeInBits(Builder, Ty);
  unsigned SrcEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  assert(DstSize % SrcEleSize == 0);
  unsigned NumElements = DstSize / SrcEleSize;
  assert(NumElements <= 4);
  if (NumElements == 1) {
    // ValueTy: <4 x i32> - Ty: <2 x i16>
    // <4 x i32> -> <4 x i32>[Idx] -> i32
    assert(SrcEleSize == DstSize);
    return Builder.CreateExtractElement(Val, Idx);
  } else if (NumElements == 2) {
    // ValueTy: <4 x i32> - Ty: <4 x i16>
    // <4 x i32> -> {<2 x i32>, <2 x i32>}[Idx] -> <2 x i32>
    return ExtractSubVector(Builder, Idx, Val, DstSize);
  }
  return Val;
}

// 'Values' is expected to contain only 1 element.
// This element should either be a vector or a scalar.
// Return the sub element of type 'Ty' into the first element of 'Values'.
void ExtractSubElement(Type *Ty, IRBuilder<> &Builder, Value *Idx,
                       SmallVector<Value *, 8> &Values) {
  LLVM_DEBUG(
      fprintf(stderr, "%s:", __func__); Ty->dump(); fprintf(stderr, "\tSrc: ");
      Values[0]->dump(); fprintf(stderr, "\tIdx: ");
      if (Idx != NULL) { Idx->dump(); } else { fprintf(stderr, "nullptr\n"); });
  assert(Values.size() == 1);
  Type *ValueTy = Values[0]->getType();

  if (Ty == ValueTy) {
    return;
  }

  // Consider only the index for the size that has been loaded (the rest have
  // already been considered during the load).
  if (Idx != NULL) {
    unsigned SrcSize = SizeInBits(Builder, ValueTy);
    unsigned DstSize = SizeInBits(Builder, Ty);
    assert(SrcSize % DstSize == 0);
    Idx = CreateRem(Builder, SrcSize / DstSize, Idx);
  }

  // Reduce Src until SrcEleSize is smaller or equal to Ty.
  ExtractSubElementUntilEleSizeLE(Ty, Builder, Values, Idx);
  assert(Values[0]->getType()->isVectorTy());

  // extract proper element(s)
  Values[0] = ExtractElementOrSubVector(Ty, Builder, Values[0], Idx);
  assert(SizeInBits(Builder, Values[0]->getType()) == SizeInBits(Builder, Ty));

  // Convert into 'Ty'
  ConvertInto(Ty, Builder, Values);
}

// Reduce SrcTy to do as few load/store operations as possible while not loading
// unneeded data.
// Return the appropriate AddIdxs that will need to be used in 'OutAddrIdxs'.
void ReduceType(IRBuilder<> &Builder, bool IsGEPUser, Value *OrgGEPIdx,
                Type *&SrcTy, unsigned DstTyBitWidth,
                SmallVector<Value *, 4> &InAddrIdxs,
                SmallVector<Value *, 4> &OutAddrIdxs,
                WeakInstructions &ToBeDeleted) {
  Type *SrcEleTy = GetEleType(SrcTy);
  unsigned SrcTyBitWidth = SizeInBits(Builder, SrcTy);
  unsigned SrcEleTyBitWidth = SizeInBits(Builder, SrcEleTy);

  unsigned InIdx = 0;
  if (!IsGEPUser) {
    while (true) {
      OutAddrIdxs.push_back(Builder.getInt32(0));
      if ((SrcTy->isArrayTy() || SrcTy->isVectorTy()) &&
          SrcTyBitWidth > DstTyBitWidth && SrcEleTyBitWidth >= DstTyBitWidth) {
        SrcTy = GetEleType(SrcTy);
        SrcTyBitWidth = SrcEleTyBitWidth;
        SrcEleTy = GetEleType(SrcTy);
        SrcEleTyBitWidth = SizeInBits(Builder, SrcEleTy);
      } else {
        break;
      }
    }
  } else {
    if (SrcTyBitWidth == DstTyBitWidth) {
      OutAddrIdxs.push_back(OrgGEPIdx);
    } else {
      OutAddrIdxs.push_back(InAddrIdxs[InIdx++]);
      while ((SrcTy->isVectorTy() || SrcTy->isArrayTy()) &&
             SrcTyBitWidth > DstTyBitWidth) {
        SrcTy = GetEleType(SrcTy);
        SrcTyBitWidth = SrcEleTyBitWidth;
        SrcEleTy = GetEleType(SrcTy);
        SrcEleTyBitWidth = SizeInBits(Builder, SrcEleTy);
        OutAddrIdxs.push_back(InAddrIdxs[InIdx++]);
      }
    }
  }
  // Make sure we will delete all unused addridxs.
  for (; InIdx < InAddrIdxs.size(); InIdx++) {
    ToBeDeleted.push_back(InAddrIdxs[InIdx]);
  }
}

unsigned CalculateNumIter(unsigned SrcTyBitWidth, unsigned DstTyBitWidth) {
  unsigned NumIter = 1;
  if (SrcTyBitWidth < DstTyBitWidth) {
    NumIter = (SrcTyBitWidth - 1 + DstTyBitWidth) / SrcTyBitWidth;
  }

  return NumIter;
}

Value *ComputeLoad(IRBuilder<> &Builder, Value *OrgGEPIdx, bool IsGEPUser,
                   Value *Src, Type *SrcTy, Type *DstTy,
                   SmallVector<Value *, 4> &NewAddrIdxs,
                   WeakInstructions &ToBeDeleted) {
  Type *DstEleTy = GetEleType(DstTy);
  unsigned DstTyBitWidth = SizeInBits(Builder, DstTy);
  unsigned DstEleTyBitWidth = SizeInBits(Builder, DstEleTy);

  Type *OrigSrcTy = SrcTy;
  SmallVector<Value *, 4> AddrIdxs;
  ReduceType(Builder, IsGEPUser, OrgGEPIdx, SrcTy, DstTyBitWidth, NewAddrIdxs,
             AddrIdxs, ToBeDeleted);

  Type *SrcEleTy = GetEleType(SrcTy);
  unsigned SrcTyBitWidth = SizeInBits(Builder, SrcTy);
  unsigned SrcEleTyBitWidth = SizeInBits(Builder, SrcEleTy);

  // Load the values
  SmallVector<Value *, 8> LDValues;
  for (unsigned i = 0; i < CalculateNumIter(SrcTyBitWidth, DstTyBitWidth);
       i++) {
    if (i > 0) {
      Value *LastAddrIdx = AddrIdxs.pop_back_val();
      LastAddrIdx = Builder.CreateAdd(LastAddrIdx, Builder.getInt32(1));
      AddrIdxs.push_back(LastAddrIdx);
    }
    auto *SrcAddr = Builder.CreateGEP(OrigSrcTy, Src, AddrIdxs);
    LoadInst *SrcVal = Builder.CreateLoad(
        cast<GEPOperator>(SrcAddr)->getResultElementType(), SrcAddr);
    LDValues.push_back(SrcVal);
  }

  // If load values are array, extract scalar elements from them.
  if (SrcTy->isArrayTy()) {
    ExtractFromArray(Builder, LDValues);
    SrcTy = SrcEleTy;
    SrcTyBitWidth = SrcEleTyBitWidth;
  }

  // If the output is a vec3 let's consider that the output is a vec4.
  bool IsVec3 = DstTy->isVectorTy() && GetNumEle(DstTy) == 3;

  // Because the vec3 lowering pass is run before this one, we should not have a
  // vec3 src; however, it seems that some llvm passes after vec3 lowering can
  // produce a new vec3. At the moment the only case known is to produce a vec3
  // that will be bitcast to another vec3 whose elements have the same size as
  // the src vec3. In that particular case, just keep the vec3 as we only need
  // to bitcast them, which will be handled correctly by this pass.
  IsVec3 &= !(SrcTy->isVectorTy() && GetNumEle(SrcTy) == 3 &&
              SrcEleTyBitWidth == DstEleTyBitWidth);

  if (IsVec3) {
    DstTy = FixedVectorType::get(DstEleTy, 4);
  }

  if (SrcTyBitWidth > DstTyBitWidth) {
    assert(LDValues.size() == 1);
    ExtractSubElement(DstTy, Builder, OrgGEPIdx, LDValues);
  } else {
    ConvertInto(DstTy, Builder, LDValues);
  }

  // recreate the vec3 from the vec4
  if (IsVec3) {
    assert(LDValues.size() == 1);
    LDValues[0] = Builder.CreateShuffleVector(LDValues[0], {0, 1, 2});
  }

  return LDValues[0];
}

void ComputeStore(IRBuilder<> &Builder, StoreInst *ST, Value *OrgGEPIdx,
                  bool IsGEPUser, Value *Src, Type *SrcTy, Type *DstTy,
                  SmallVector<Value *, 4> &NewAddrIdxs,
                  WeakInstructions &ToBeDeleted) {
  // Careful with srcty and dstty concept in store.
  // The usual pattern is:
  //
  // %bt = bitcast srcty* %src to dsty*
  // %gep = gep dstty*, dstty* %bt, %i
  // store dstty %stval, dstty* %gep
  //
  // Which convert to:
  //
  // %stval_converted = convert dstty %stval into srcty, at f(%i)
  // %gep = gep srcty*, srcty* %src, g(%i)
  // store srcty %stval_converted, srcty* %gep
  //
  // Which means that what we need to do is to convert stval from dstty to
  // srcty. Thus, while srcty is the source of the bitcast, it is the
  // destination/target type of stval.
  Type *DstEleTy = GetEleType(DstTy);
  unsigned DstTyBitWidth = SizeInBits(Builder, DstTy);
  unsigned DstEleTyBitWidth = SizeInBits(Builder, DstEleTy);

  Type *OrigSrcTy = SrcTy;
  SmallVector<Value *, 4> AddrIdxs;
  ReduceType(Builder, IsGEPUser, OrgGEPIdx, SrcTy, DstTyBitWidth, NewAddrIdxs,
             AddrIdxs, ToBeDeleted);

  Type *SrcEleTy = GetEleType(SrcTy);
  unsigned SrcTyBitWidth = SizeInBits(Builder, SrcTy);
  unsigned SrcEleTyBitWidth = SizeInBits(Builder, SrcEleTy);

  SmallVector<Value *, 8> STValues;
  Value *STVal = ST->getValueOperand();
  STValues.push_back(STVal);

  // If the output is a vec3, let's extract those 3 elements.
  bool IsVec3 = DstTy->isVectorTy() && GetNumEle(DstTy) == 3;

  // Because the vec3 to vec4 pass is before this one, we should not have a vec3
  // src. But it seems that some llvm passes after vec3 to vec4 can produce new
  // vec3. At the moment the only case known is to produce vec3 that will be
  // bitcast to another vec3 which element has the same time as the src vec3. In
  // that particular case, just keep the vec3 as we only need to bitcast them,
  // which will be handled correctly by this pass.
  IsVec3 &= !(SrcTy->isVectorTy() && GetNumEle(SrcTy) == 3 &&
              SrcEleTyBitWidth == DstEleTyBitWidth);
  if (IsVec3) {
    ExtractFromVector(Builder, STValues);
    DstTy = DstEleTy;
    DstTyBitWidth = DstEleTyBitWidth;
  }

  if (SrcTyBitWidth > DstTyBitWidth) {
    if (SrcEleTyBitWidth > DstTyBitWidth) {
      // float -> <2 x i8>
      // In this example, we cannot store 2 bytes into a object only accessible
      // by group of 4.
      SrcTy->print(errs());
      DstTy->print(errs());
      llvm_unreachable("Cannot handle above src/dst types.");
    }
    // SrcTy: <N x s> - DstTy: <M x d>
    // we have: N*s > M*d && s <= M*d
    // thus: N > 1, which means that source is either a vector or an array.
    assert(SrcTy->isVectorTy() || SrcTy->isArrayTy());

    // SrcTy: <4 x i32> - DstTy: i64
    // Let's convert i64 into the element type (i32) as we could not store a
    // <2 x i32> into SrcTy.
    ConvertInto(SrcEleTy, Builder, STValues);

    // Reduce should have given the Idxs to access the vector (or array).
    // Because we know we want to access the element here, let's add the
    // appropriate Idx to 'AddrIdxs'.
    if (IsGEPUser) {
      AddrIdxs.push_back(NewAddrIdxs[AddrIdxs.size()]);
    } else {
      AddrIdxs.push_back(Builder.getInt32(0));
    }
  } else {
    if (DstTy->isArrayTy()) {
      ExtractFromArray(Builder, STValues);
    }

    ConvertInto(SrcTy, Builder, STValues);
  }

  // Generate stores.
  unsigned NumSTElement = STValues.size();
  for (unsigned i = 0; i < NumSTElement; i++) {
    if (i > 0) {
      // Calculate next store address
      Value *LastAddrIdx = AddrIdxs.pop_back_val();
      LastAddrIdx = Builder.CreateAdd(LastAddrIdx, Builder.getInt32(1));
      AddrIdxs.push_back(LastAddrIdx);
    }

    Value *DstAddr = Builder.CreateGEP(OrigSrcTy, Src, AddrIdxs);

    Builder.CreateStore(STValues[i], DstAddr);
  }
}

} // namespace

PreservedAnalyses
clspv::ReplacePointerBitcastPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  WeakInstructions ToBeDeleted;
  SmallVector<Instruction *, 16> WorkList;
  SmallVector<User *, 16> UserWorkList;
  DenseMap<Value *, Type *> type_cache;
  DenseSet<Value *> ImplicitCasts;
  for (auto &F : M) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        Value *source = nullptr;
        Type *source_ty = nullptr;
        Type *dest_ty = nullptr;
        // The following checks use InferType to distinguish when a pointer's
        // interpretation changes between instructions. This requires the input
        // to be an instruction whose result provides a clear type for a
        // pointer (e.g. gep, alloca, or global variable).
        if (auto *gep = dyn_cast<GetElementPtrInst>(&I)) {
          source = gep->getPointerOperand();
          source_ty = clspv::InferType(gep->getPointerOperand(), M.getContext(), &type_cache);
          dest_ty = gep->getSourceElementType();
        } else if (auto *ld = dyn_cast<LoadInst>(&I)) {
          source = ld->getPointerOperand();
          source_ty = clspv::InferType(ld->getPointerOperand(), M.getContext(), &type_cache);
          dest_ty = ld->getType();
        } else if (auto *st = dyn_cast<StoreInst>(&I)) {
          source = st->getPointerOperand();
          source_ty = clspv::InferType(st->getPointerOperand(), M.getContext(), &type_cache);
          dest_ty = st->getValueOperand()->getType();
        }

        if (source_ty && dest_ty && source_ty != dest_ty) {
          bool ok = true;
          UserWorkList.push_back(&I);
          while (!UserWorkList.empty()) {
            auto *user = UserWorkList.back();
            UserWorkList.pop_back();

            if (isa<GetElementPtrInst>(user)) {
              for (auto *U : user->users())
                UserWorkList.push_back(U);
            } else if (!isa<StoreInst>(user) && !isa<LoadInst>(user)) {
              ok = false;
              break;
            }
          }
          if (!ok)
            continue;

          ImplicitCasts.insert(source);
          WorkList.push_back(&I);
        }
      }
    }
  }

  const DataLayout &DL = M.getDataLayout();

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // Find pointer bitcast instruction.
        if (isa<BitCastInst>(&I) && isa<PointerType>(I.getType())) {
          Value *Src = I.getOperand(0);
          if (isa<PointerType>(Src->getType())) {
            // Check if this bitcast is one that can be handled during this run
            // of the pass. If not, just skip it and don't make changes to the
            // module. These checks are coarse level checks that only the right
            // instructions appear. Rejected bitcasts might be able to be
            // handled later in the flow after further optimization.
            UserWorkList.clear();
            for (auto User : I.users()) {
              UserWorkList.push_back(User);
            }
            bool ok = true;
            while (!UserWorkList.empty()) {
              auto User = UserWorkList.back();
              UserWorkList.pop_back();

              if (isa<GetElementPtrInst>(User)) {
                for (auto GEPUser : User->users()) {
                  UserWorkList.push_back(GEPUser);
                }
              } else if (!isa<StoreInst>(User) && !isa<LoadInst>(User)) {
                // Cannot handle this bitcast.
                ok = false;
                break;
              }
            }
            if (!ok) {
              continue;
            }

            auto inst = &I;
            if (inst->use_empty()) {
              ToBeDeleted.push_back(inst);
              continue;
            }

            WorkList.push_back(inst);

          } else {
            llvm_unreachable("Unsupported bitcast");
          }
        }
      }
    }
  }


  for (Instruction *Inst : WorkList) {
    LLVM_DEBUG(dbgs() << "## Inst: "; Inst->dump());
    Value *Src = nullptr;
    Type *SrcTy = nullptr;
    Type *DstTy = nullptr;
    // TODO(#816): remove after final transition.
    if (isa<BitCastInst>(Inst)) {
      Src = Inst->getOperand(0);
      SrcTy = Src->getType()->getNonOpaquePointerElementType();
      DstTy = Inst->getType()->getNonOpaquePointerElementType();
    } else {
      if (auto *gep = dyn_cast<GetElementPtrInst>(Inst)) {
        Src = gep->getPointerOperand();
        DstTy = gep->getSourceElementType();
      } else if (auto *ld = dyn_cast<LoadInst>(Inst)) {
        Src = ld->getPointerOperand();
        DstTy = ld->getType();
      } else if (auto *st = dyn_cast<StoreInst>(Inst)) {
        Src = st->getPointerOperand();
        DstTy = st->getValueOperand()->getType();
      } else {
        llvm_unreachable("unsupported opaque pointer cast");
      }
      SrcTy = clspv::InferType(Src, M.getContext(), &type_cache);
    }

    SmallVector<size_t, 4> SrcTyBitWidths;
    Type *TmpTy = SrcTy;
    SrcTyBitWidths.push_back(SizeInBits(DL, TmpTy));
    while (TmpTy->isArrayTy() || TmpTy->isVectorTy()) {
      TmpTy = GetEleType(TmpTy);
      SrcTyBitWidths.push_back(SizeInBits(DL, TmpTy));
    }

    // If we detect a private memory, the first index of the GEP will need to be
    // zero (meaning that we are not explicitly trying to access private memory
    // out-of-bounds).
    // spirv-val is not yet capable of detecting it, but such access would fail
    // at runtime (see https://github.com/KhronosGroup/SPIRV-Tools/issues/1585).
    bool isPrivateMemory = isa<AllocaInst>(Src);

    // Investigate pointer bitcast's users.
    // TODO(#816): remove after final transition.
    Value *start = isa<BitCastInst>(Inst) ? Inst : Src;
    for (User *BitCastUser : start->users()) {
      if (ImplicitCasts.count(BitCastUser)) {
        // If this user was queued on the worklist as an implicit cast
        // separately, don't handle it now.
        continue;
      }

      LLVM_DEBUG(dbgs() << "#### BitCastUser: "; BitCastUser->dump());
      SmallVector<Value *, 4> NewAddrIdxs;

      // It consist of User* and bool whether user is gep or not.
      SmallVector<std::pair<User *, bool>, 32> Users;

      Value *OrgGEPIdx = nullptr;
      if (auto GEP = dyn_cast<GetElementPtrInst>(BitCastUser)) {
        IRBuilder<> Builder(GEP);
        unsigned DstTyBitWidth = SizeInBits(DL, DstTy);

        // Build new src/dst address.
        Value *GEPIdx = OrgGEPIdx = GEP->getOperand(1);
        unsigned SmallerSrcBitWidth = SrcTyBitWidths[SrcTyBitWidths.size() - 1];
        if (SmallerSrcBitWidth > DstTyBitWidth) {
          GEPIdx =
              CreateDiv(Builder, SmallerSrcBitWidth / DstTyBitWidth, GEPIdx);
        } else if (SmallerSrcBitWidth < DstTyBitWidth) {
          GEPIdx =
              CreateMul(Builder, DstTyBitWidth / SmallerSrcBitWidth, GEPIdx);
        }
        for (unsigned i = 0; i < SrcTyBitWidths.size(); i++) {
          if (isPrivateMemory && i == 0) {
            NewAddrIdxs.push_back(Builder.getInt32(0));
            continue;
          }
          Value *Idx;
          unsigned div = SrcTyBitWidths[i] / SmallerSrcBitWidth;
          if (div <= 1) {
            Idx = GEPIdx;
          } else {
            Idx = CreateDiv(Builder, div, GEPIdx);
            GEPIdx = CreateRem(Builder, div, GEPIdx);
          }
          NewAddrIdxs.push_back(Idx);
        }

        // If bitcast's user is gep, investigate gep's users too.
        for (User *GEPUser : GEP->users()) {
          Users.push_back(std::make_pair(GEPUser, true));
        }
        if (!GEP->users().empty()) {
          ToBeDeleted.push_back(GEP);
        }
      } else {
        Users.push_back(std::make_pair(BitCastUser, false));
      }

      // Handle users.
      bool IsGEPUser = false;
      for (auto UserIter : Users) {
        User *U = UserIter.first;
        IsGEPUser = UserIter.second;
        LLVM_DEBUG(dbgs() << "###### User (isGEP: " << IsGEPUser << ") : ";
                   U->dump());

        IRBuilder<> Builder(cast<Instruction>(U));

        if (StoreInst *ST = dyn_cast<StoreInst>(U)) {
          ComputeStore(Builder, ST, OrgGEPIdx, IsGEPUser, Src, SrcTy, DstTy,
                       NewAddrIdxs, ToBeDeleted);
        } else if (LoadInst *LD = dyn_cast<LoadInst>(U)) {
          Value *DstVal = ComputeLoad(Builder, OrgGEPIdx, IsGEPUser, Src, SrcTy,
                                      DstTy, NewAddrIdxs, ToBeDeleted);
          // Update LD's users with DstVal.
          LD->replaceAllUsesWith(DstVal);
        } else {
          U->print(errs());
          llvm_unreachable(
              "Handle above user of gep on ReplacePointerBitcastPass");
        }

        ToBeDeleted.push_back(cast<Instruction>(U));
      }
    }

    // Schedule for removal only if Inst has no users. If all its users are
    // later also replaced in the module, Inst will be remove by transitivity.
    if (Inst->user_empty()) {
      ToBeDeleted.push_back(Inst);
    }
  }

  // Remove all dead instructions, including their dead operands. Proceed with a
  // fixed-point algorithm to handle dependencies.
  for (bool Progress = true; Progress;) {
    std::size_t PreviousSize = ToBeDeleted.size();

    WeakInstructions Deads;
    WeakInstructions NextBatch;
    for (WeakTrackingVH Handle : ToBeDeleted) {
      if (!Handle.pointsToAliveValue() || !isa<Instruction>(Handle))
        continue;

      auto *Inst = cast<Instruction>(Handle);

      // We need to remove stores manually given they are never trivially dead.
      if (auto *Store = dyn_cast<StoreInst>(Inst)) {
        Store->eraseFromParent();
        continue;
      }

      if (isInstructionTriviallyDead(Inst)) {
        Deads.push_back(Handle);
      } else {
        NextBatch.push_back(Handle);
      }
    }

    RecursivelyDeleteTriviallyDeadInstructions(Deads);

    ToBeDeleted = std::move(NextBatch);
    Progress = (ToBeDeleted.size() < PreviousSize);
  }

  return PA;
}
