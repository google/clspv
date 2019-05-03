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
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "replacepointerbitcast"

namespace {
struct ReplacePointerBitcastPass : public ModulePass {
  static char ID;
  ReplacePointerBitcastPass() : ModulePass(ID) {}

  // Returns the number of chunks of source data required to exactly
  // cover the destination data, if the source and destination types are
  // different sizes.  Otherwise returns 0.
  unsigned CalculateNumIter(unsigned SrcTyBitWidth, unsigned DstTyBitWidth);
  Value *CalculateNewGEPIdx(unsigned SrcTyBitWidth, unsigned DstTyBitWidth,
                            GetElementPtrInst *GEP);

  bool runOnModule(Module &M) override;
};
} // namespace

char ReplacePointerBitcastPass::ID = 0;
INITIALIZE_PASS(ReplacePointerBitcastPass, "ReplacePointerBitcast",
                "Replace Pointer Bitcast Pass", false, false)

namespace clspv {
ModulePass *createReplacePointerBitcastPass() {
  return new ReplacePointerBitcastPass();
}
} // namespace clspv

namespace {

// Gathers the scalar values of |v| into |elements|. Generates new instructions
// to extract the values.
void GatherBaseElements(Value *v, SmallVectorImpl<Value *> *elements,
                        IRBuilder<> &builder) {
  auto *type = v->getType();
  if (auto *vec_type = dyn_cast<VectorType>(type)) {
    for (uint64_t i = 0; i != vec_type->getNumElements(); ++i) {
      elements->push_back(builder.CreateExtractElement(v, i));
    }
  } else if (auto *array_type = dyn_cast<ArrayType>(type)) {
    for (uint64_t i = 0; i != array_type->getNumElements(); ++i) {
      auto *extract = builder.CreateExtractValue(v, {static_cast<unsigned>(i)});
      GatherBaseElements(extract, elements, builder);
    }
  } else if (auto *struct_type = dyn_cast<StructType>(type)) {
    for (unsigned i = 0; i != struct_type->getNumElements(); ++i) {
      auto *extract = builder.CreateExtractValue(v, {i});
      GatherBaseElements(extract, elements, builder);
    }
  } else {
    elements->push_back(v);
  }
}

// Returns a value of |dst_type| using the elemental members of |src_elements|.
Value *BuildFromElements(Type *dst_type, const ArrayRef<Value *> &src_elements,
                         unsigned *used_bits, unsigned *index,
                         IRBuilder<> &builder) {
  auto *module = builder.GetInsertBlock()->getParent()->getParent();
  auto &DL = module->getDataLayout();
  auto &context = dst_type->getContext();
  Value *dst = nullptr;
  // Arrays, vectors and structs are annoyingly just different enough to each
  // require their own cases.
  if (auto *dst_array_ty = dyn_cast<ArrayType>(dst_type)) {
    auto *ele_ty = dst_array_ty->getElementType();
    for (uint64_t i = 0; i != dst_array_ty->getNumElements(); ++i) {
      auto *tmp_value =
          BuildFromElements(ele_ty, src_elements, used_bits, index, builder);
      auto *prev = dst ? dst : UndefValue::get(dst_type);
      dst = builder.CreateInsertValue(prev, tmp_value,
                                      {static_cast<unsigned>(i)});
    }
  } else if (auto *dst_struct_ty = dyn_cast<StructType>(dst_type)) {
    for (unsigned i = 0; i != dst_struct_ty->getNumElements(); ++i) {
      auto *ele_ty = dst_struct_ty->getElementType(i);
      auto *tmp_value =
          BuildFromElements(ele_ty, src_elements, used_bits, index, builder);
      auto *prev = dst ? dst : UndefValue::get(dst_type);
      dst = builder.CreateInsertValue(prev, tmp_value, {i});
    }
  } else if (auto *dst_vec_ty = dyn_cast<VectorType>(dst_type)) {
    auto *ele_ty = dst_vec_ty->getElementType();
    for (uint64_t i = 0; i != dst_vec_ty->getNumElements(); ++i) {
      auto *tmp_value =
          BuildFromElements(ele_ty, src_elements, used_bits, index, builder);
      auto *prev = dst ? dst : UndefValue::get(dst_type);
      dst = builder.CreateInsertElement(prev, tmp_value, i);
    }
  } else {
    // Scalar conversion eats up elements in src_elements.
    auto dst_width = DL.getTypeStoreSizeInBits(dst_type);
    uint64_t bits = 0;
    Value *tmp_value = nullptr;
    auto prev_bits = 0;
    Value *ele_int_cast = nullptr;
    while (bits < dst_width) {
      prev_bits = bits;
      auto *ele = src_elements[*index];
      auto *ele_ty = ele->getType();
      auto ele_width = DL.getTypeStoreSizeInBits(ele_ty);
      auto remaining_bits = ele_width - *used_bits;
      auto needed_bits = dst_width - bits;
      // Create a reusable cast to an integer type for this element.
      if (!ele_int_cast || cast<User>(ele_int_cast)->getOperand(0) != ele) {
        ele_int_cast =
            builder.CreateBitCast(ele, IntegerType::get(context, ele_width));
      }
      tmp_value = ele_int_cast;
      // Some of the bits of this element were previously used, so shift the
      // value that many bits.
      if (*used_bits != 0) {
        tmp_value = builder.CreateLShr(tmp_value, *used_bits);
      }
      if (needed_bits < remaining_bits) {
        // Ensure only the needed bits are used.
        uint64_t mask = (1ull << needed_bits) - 1;
        tmp_value =
            builder.CreateAnd(tmp_value, builder.getIntN(dst_width, mask));
      }
      // Cast to tbe destination bit width, but stay as a integer type.
      if (ele_width != dst_width) {
        tmp_value = builder.CreateIntCast(
            tmp_value, IntegerType::get(context, dst_width), false);
      }

      if (remaining_bits <= needed_bits) {
        // Used the rest of the element.
        *used_bits = 0;
        ++(*index);
        bits += remaining_bits;
      } else {
        // Only need part of this element.
        *used_bits += needed_bits;
        bits += needed_bits;
      }

      if (dst) {
        // Previous iteration generated an integer of the right size. That needs
        // to be combined with the value generated this iteration.
        tmp_value = builder.CreateShl(tmp_value, prev_bits);
        dst = builder.CreateOr(dst, tmp_value);
      } else {
        dst = tmp_value;
      }
    }

    assert(bits <= dst_width);
    if (bits == dst_width && dst_type != dst->getType()) {
      // Finally, cast away from the working integer type if necessary.
      dst = builder.CreateBitCast(dst, dst_type);
    }
  }

  return dst;
}

// Returns an equivalent value of |src| as |dst_type|.
//
// This function requires |src|'s and |dst_type|'s bit widths match. Does not
// introduce new integer sizes, but generates multiple instructions to mimic a
// generic bitcast (unless a bitcast is sufficient).
Value *ConvertValue(Value *src, Type *dst_type, IRBuilder<> &builder) {
  auto *src_type = src->getType();
  auto *module = builder.GetInsertBlock()->getParent()->getParent();
  auto &DL = module->getDataLayout();
  if (!src_type->isFirstClassType() || !dst_type->isFirstClassType() ||
      src_type->isAggregateType() || dst_type->isAggregateType()) {
    SmallVector<Value *, 8> src_elements;
    if (src_type->isAggregateType()) {
      GatherBaseElements(src, &src_elements, builder);
    } else {
      src_elements.push_back(src);
    }

    unsigned used_bits = 0;
    unsigned index = 0;
    return BuildFromElements(dst_type, src_elements, &used_bits, &index,
                             builder);
  } else {
    return builder.CreateBitCast(src, dst_type);
  }

  return nullptr;
}

} // namespace

unsigned ReplacePointerBitcastPass::CalculateNumIter(unsigned SrcTyBitWidth,
                                                     unsigned DstTyBitWidth) {
  unsigned NumIter = 0;
  if (SrcTyBitWidth > DstTyBitWidth) {
    if (SrcTyBitWidth % DstTyBitWidth) {
      llvm_unreachable(
          "Src type bitwidth should be multiple of Dest type bitwidth");
    }
    NumIter = 1;
  } else if (SrcTyBitWidth < DstTyBitWidth) {
    if (DstTyBitWidth % SrcTyBitWidth) {
      llvm_unreachable(
          "Dest type bitwidth should be multiple of Src type bitwidth");
    }
    NumIter = DstTyBitWidth / SrcTyBitWidth;
  } else {
    NumIter = 0;
  }

  return NumIter;
}

Value *ReplacePointerBitcastPass::CalculateNewGEPIdx(unsigned SrcTyBitWidth,
                                                     unsigned DstTyBitWidth,
                                                     GetElementPtrInst *GEP) {
  Value *NewGEPIdx = GEP->getOperand(1);
  IRBuilder<> Builder(GEP);

  if (SrcTyBitWidth > DstTyBitWidth) {
    if (GEP->getNumOperands() > 2) {
      GEP->print(errs());
      llvm_unreachable("Support above GEP on PointerBitcastPass");
    }

    NewGEPIdx = Builder.CreateLShr(
        NewGEPIdx, Builder.getInt32(std::log2(SrcTyBitWidth / DstTyBitWidth)));
  } else if (DstTyBitWidth > SrcTyBitWidth) {
    if (GEP->getNumOperands() > 2) {
      GEP->print(errs());
      llvm_unreachable("Support above GEP on PointerBitcastPass");
    }

    NewGEPIdx = Builder.CreateShl(
        NewGEPIdx, Builder.getInt32(std::log2(DstTyBitWidth / SrcTyBitWidth)));
  }

  return NewGEPIdx;
}

bool ReplacePointerBitcastPass::runOnModule(Module &M) {
  bool Changed = false;

  const DataLayout &DL = M.getDataLayout();

  SmallVector<Instruction *, 16> VectorWorkList;
  SmallVector<Instruction *, 16> ScalarWorkList;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // Find pointer bitcast instruction.
        if (isa<BitCastInst>(&I) && isa<PointerType>(I.getType())) {
          Value *Src = I.getOperand(0);
          if (isa<PointerType>(Src->getType())) {
            Type *SrcEleTy =
                I.getOperand(0)->getType()->getPointerElementType();
            Type *DstEleTy = I.getType()->getPointerElementType();
            if (SrcEleTy->isVectorTy() || DstEleTy->isVectorTy()) {
              // Handle case either operand is vector type like char4* -> int4*.
              VectorWorkList.push_back(&I);
            } else {
              // Handle case all operands are scalar type like char* -> int*.
              ScalarWorkList.push_back(&I);
            }

            Changed = true;
          } else {
            llvm_unreachable("Unsupported bitcast");
          }
        }
      }
    }
  }

  SmallVector<Instruction *, 16> ToBeDeleted;
  for (Instruction *Inst : VectorWorkList) {
    Value *Src = Inst->getOperand(0);
    Type *SrcTy = Src->getType()->getPointerElementType();
    Type *DstTy = Inst->getType()->getPointerElementType();
    Type *SrcEleTy =
        SrcTy->isVectorTy() ? SrcTy->getSequentialElementType() : SrcTy;
    Type *DstEleTy =
        DstTy->isVectorTy() ? DstTy->getSequentialElementType() : DstTy;
    // These are bit widths of the source and destination types, even
    // if they are vector types.  E.g. bit width of float4 is 64.
    unsigned SrcTyBitWidth = DL.getTypeStoreSizeInBits(SrcTy);
    unsigned DstTyBitWidth = DL.getTypeStoreSizeInBits(DstTy);
    unsigned SrcEleTyBitWidth = DL.getTypeStoreSizeInBits(SrcEleTy);
    unsigned DstEleTyBitWidth = DL.getTypeStoreSizeInBits(DstEleTy);
    unsigned NumIter = CalculateNumIter(SrcTyBitWidth, DstTyBitWidth);

    // Investigate pointer bitcast's users.
    for (User *BitCastUser : Inst->users()) {
      Value *BitCastSrc = Inst->getOperand(0);
      Value *NewAddrIdx = ConstantInt::get(Type::getInt32Ty(M.getContext()), 0);

      // It consist of User* and bool whether user is gep or not.
      SmallVector<std::pair<User *, bool>, 32> Users;

      GetElementPtrInst *GEP = nullptr;
      Value *OrgGEPIdx = nullptr;
      if ((GEP = dyn_cast<GetElementPtrInst>(BitCastUser))) {
        OrgGEPIdx = GEP->getOperand(1);

        // Build new src/dst address index.
        NewAddrIdx = CalculateNewGEPIdx(SrcTyBitWidth, DstTyBitWidth, GEP);

        // Record gep's users.
        for (User *GEPUser : GEP->users()) {
          Users.push_back(std::make_pair(GEPUser, true));
        }
      } else {
        // Record bitcast's users.
        Users.push_back(std::make_pair(BitCastUser, false));
      }

      // Handle users.
      bool IsGEPUser = false;
      for (auto UserIter : Users) {
        User *U = UserIter.first;
        IsGEPUser = UserIter.second;

        IRBuilder<> Builder(cast<Instruction>(U));

        if (StoreInst *ST = dyn_cast<StoreInst>(U)) {
          if (SrcTyBitWidth < DstTyBitWidth) {
            //
            // Consider below case.
            //
            // Original IR (float2* --> float4*)
            // 1. val = load (float4*) src_addr
            // 2. dst_addr = bitcast float2*, float4*
            // 3. dst_addr = gep (float4*) dst_addr, idx
            // 4. store (float4*) dst_addr
            //
            // Transformed IR
            // 1. val(float4) = load (float4*) src_addr
            // 2. val1(float2) = shufflevector (float4)val, (float4)undef,
            //                                 (float2)<0, 1>
            // 3. val2(float2) = shufflevector (float4)val, (float4)undef,
            //                                 (float2)<2, 3>
            // 4. dst_addr1(float2*) = gep (float2*)dst_addr, idx * 2
            // 5. dst_addr2(float2*) = gep (float2*)dst_addr, idx * 2 + 1
            // 6. store (float2)val1, (float2*)dst_addr1
            // 7. store (float2)val2, (float2*)dst_addr2
            //

            unsigned NumElement = DstTyBitWidth / SrcTyBitWidth;
            unsigned NumVector = 1;
            // Vulkan SPIR-V does not support over 4 components for
            // TypeVector.
            if (NumElement > 4) {
              NumVector = NumElement >> 2;
              NumElement = 4;
            }

            // Create store values.
            Type *TmpValTy = SrcTy;
            if (DstTy->isVectorTy()) {
              if (SrcEleTyBitWidth == DstEleTyBitWidth) {
                TmpValTy =
                    VectorType::get(SrcEleTy, DstTy->getVectorNumElements());
              } else {
                TmpValTy = VectorType::get(SrcEleTy, NumElement);
              }
            }

            Value *STVal = ST->getValueOperand();
            for (unsigned VIdx = 0; VIdx < NumVector; VIdx++) {
              Value *TmpSTVal = nullptr;
              if (NumVector == 1) {
                TmpSTVal = Builder.CreateBitCast(STVal, TmpValTy);
              } else {
                unsigned DstVecTyNumElement =
                    DstTy->getVectorNumElements() / NumVector;
                SmallVector<uint32_t, 4> Idxs;
                for (unsigned i = 0; i < DstVecTyNumElement; i++) {
                  Idxs.push_back(i + (DstVecTyNumElement * VIdx));
                }
                Value *UndefVal = UndefValue::get(DstTy);
                TmpSTVal = Builder.CreateShuffleVector(STVal, UndefVal, Idxs);
                TmpSTVal = Builder.CreateBitCast(TmpSTVal, TmpValTy);
              }

              SmallVector<Value *, 8> STValues;
              if (!SrcTy->isVectorTy()) {
                // Handle scalar type.
                for (unsigned i = 0; i < NumElement; i++) {
                  Value *TmpVal = Builder.CreateExtractElement(
                      TmpSTVal, Builder.getInt32(i));
                  STValues.push_back(TmpVal);
                }
              } else {
                // Handle vector type.
                unsigned SrcNumElement = SrcTy->getVectorNumElements();
                unsigned DstNumElement = DstTy->getVectorNumElements();
                for (unsigned i = 0; i < NumElement; i++) {
                  SmallVector<uint32_t, 4> Idxs;
                  for (unsigned j = 0; j < SrcNumElement; j++) {
                    Idxs.push_back(i * SrcNumElement + j);
                  }

                  VectorType *TmpVecTy =
                      VectorType::get(SrcEleTy, DstNumElement);
                  Value *UndefVal = UndefValue::get(TmpVecTy);
                  Value *TmpVal =
                      Builder.CreateShuffleVector(TmpSTVal, UndefVal, Idxs);
                  STValues.push_back(TmpVal);
                }
              }

              // Generate stores.
              Value *SrcAddrIdx = NewAddrIdx;
              Value *BaseAddr = BitCastSrc;
              for (unsigned i = 0; i < NumElement; i++) {
                // Calculate store address.
                Value *DstAddr = Builder.CreateGEP(BaseAddr, SrcAddrIdx);
                Builder.CreateStore(STValues[i], DstAddr);

                if (i + 1 < NumElement) {
                  // Calculate next store address
                  SrcAddrIdx =
                      Builder.CreateAdd(SrcAddrIdx, Builder.getInt32(1));
                }
              }
            }
          } else if (SrcTyBitWidth > DstTyBitWidth) {
            //
            // Consider below case.
            //
            // Original IR (float4* --> float2*)
            // 1. val = load (float2*) src_addr
            // 2. dst_addr = bitcast float4*, float2*
            // 3. dst_addr = gep (float2*) dst_addr, idx
            // 4. store (float2) val, (float2*) dst_addr
            //
            // Transformed IR: Decompose the source vector into elements, then
            // write them one at a time.
            // 1. val = load (float2*) src_addr
            // 2. val1 = (float)extract_element val, 0
            // 3. val2 = (float)extract_element val, 1
            // // Source component k maps to destination component k * idxscale
            // 3a. idxscale = sizeof(float4)/sizeof(float2)
            // 3b. idxbase = idx / idxscale
            // 3c. newarrayidx = idxbase * idxscale
            // 4. dst_addr1 = gep (float4*) dst, newarrayidx
            // 5. dst_addr2 = gep (float4*) dst, newarrayidx + 1
            // 6. store (float)val1, (float*) dst_addr1
            // 7. store (float)val2, (float*) dst_addr2
            //

            if (SrcTyBitWidth <= DstEleTyBitWidth) {
              SrcTy->print(errs());
              DstTy->print(errs());
              llvm_unreachable("Handle above src/dst type.");
            }

            // Create store values.
            Value *STVal = ST->getValueOperand();

            if (DstTy->isVectorTy() && (SrcEleTyBitWidth != DstTyBitWidth)) {
              VectorType *TmpVecTy =
                  VectorType::get(SrcEleTy, DstTyBitWidth / SrcEleTyBitWidth);
              STVal = Builder.CreateBitCast(STVal, TmpVecTy);
            }

            SmallVector<Value *, 8> STValues;
            // How many destination writes are required?
            unsigned DstNumElement = 1;
            if (!DstTy->isVectorTy() || SrcEleTyBitWidth == DstTyBitWidth) {
              // Handle scalar type.
              STValues.push_back(STVal);
            } else {
              // Handle vector type.
              DstNumElement = DstTy->getVectorNumElements();
              for (unsigned i = 0; i < DstNumElement; i++) {
                Value *Idx = Builder.getInt32(i);
                Value *TmpVal = Builder.CreateExtractElement(STVal, Idx);
                STValues.push_back(TmpVal);
              }
            }

            // Generate stores.
            Value *BaseAddr = BitCastSrc;
            Value *SubEleIdx = Builder.getInt32(0);
            if (IsGEPUser) {
              // Compute SubNumElement = idxscale
              unsigned SubNumElement = SrcTy->getVectorNumElements();
              if (DstTy->isVectorTy() && (SrcEleTyBitWidth != DstTyBitWidth)) {
                // Same condition under which DstNumElements > 1
                SubNumElement = SrcTy->getVectorNumElements() /
                                DstTy->getVectorNumElements();
              }

              // Compute SubEleIdx = idxbase * idxscale
              SubEleIdx = Builder.CreateAnd(
                  OrgGEPIdx, Builder.getInt32(SubNumElement - 1));
              if (DstTy->isVectorTy() && (SrcEleTyBitWidth != DstTyBitWidth)) {
                SubEleIdx = Builder.CreateShl(
                    SubEleIdx, Builder.getInt32(std::log2(SubNumElement)));
              }
            }

            for (unsigned i = 0; i < DstNumElement; i++) {
              // Calculate address.
              if (i > 0) {
                SubEleIdx = Builder.CreateAdd(SubEleIdx, Builder.getInt32(i));
              }

              Value *Idxs[] = {NewAddrIdx, SubEleIdx};
              Value *DstAddr = Builder.CreateGEP(BaseAddr, Idxs);
              Type *TmpSrcTy = SrcEleTy;
              if (TmpSrcTy->isVectorTy()) {
                TmpSrcTy = TmpSrcTy->getVectorElementType();
              }
              Value *TmpVal = Builder.CreateBitCast(STValues[i], TmpSrcTy);

              Builder.CreateStore(TmpVal, DstAddr);
            }
          } else {
            // if SrcTyBitWidth == DstTyBitWidth
            Type *TmpSrcTy = SrcTy;
            Value *DstAddr = Src;

            if (IsGEPUser) {
              SmallVector<Value *, 4> Idxs;
              for (unsigned i = 1; i < GEP->getNumOperands(); i++) {
                Idxs.push_back(GEP->getOperand(i));
              }
              DstAddr = Builder.CreateGEP(BitCastSrc, Idxs);

              if (GEP->getNumOperands() > 2) {
                TmpSrcTy = SrcEleTy;
              }
            }

            Value *TmpVal =
                Builder.CreateBitCast(ST->getValueOperand(), TmpSrcTy);
            Builder.CreateStore(TmpVal, DstAddr);
          }
        } else if (LoadInst *LD = dyn_cast<LoadInst>(U)) {
          Value *SrcAddrIdx = Builder.getInt32(0);
          if (IsGEPUser) {
            SrcAddrIdx = NewAddrIdx;
          }

          // Load value from src.
          SmallVector<Value *, 8> LDValues;

          for (unsigned i = 1; i <= NumIter; i++) {
            Value *SrcAddr = Builder.CreateGEP(Src, SrcAddrIdx);
            LoadInst *SrcVal = Builder.CreateLoad(SrcAddr, "src_val");
            LDValues.push_back(SrcVal);

            if (i + 1 <= NumIter) {
              // Calculate next SrcAddrIdx.
              SrcAddrIdx = Builder.CreateAdd(SrcAddrIdx, Builder.getInt32(1));
            }
          }

          Value *DstVal = nullptr;
          if (SrcTyBitWidth > DstTyBitWidth) {
            unsigned NumElement = SrcTyBitWidth / DstTyBitWidth;

            if (SrcEleTyBitWidth == DstTyBitWidth) {
              //
              // Consider below case.
              //
              // Original IR (int4* --> char4*)
              // 1. src_addr = bitcast int4*, char4*
              // 2. element_addr = gep (char4*) src_addr, idx
              // 3. load (char4*) element_addr
              //
              // Transformed IR
              // 1. src_addr = gep (int4*) src, idx / 4
              // 2. src_val(int4) = load (int4*) src_addr
              // 3. tmp_val(int4) = extractelement src_val, idx % 4
              // 4. dst_val(char4) = bitcast tmp_val, (char4)
              //
              Value *EleIdx = Builder.getInt32(0);
              if (IsGEPUser) {
                EleIdx = Builder.CreateAnd(OrgGEPIdx,
                                           Builder.getInt32(NumElement - 1));
              }
              Value *TmpVal =
                  Builder.CreateExtractElement(LDValues[0], EleIdx, "tmp_val");
              DstVal = Builder.CreateBitCast(TmpVal, DstTy);
            } else if (SrcEleTyBitWidth < DstTyBitWidth) {
              if (IsGEPUser) {
                //
                // Consider below case.
                //
                // Original IR (float4* --> float2*)
                // 1. src_addr = bitcast float4*, float2*
                // 2. element_addr = gep (float2*) src_addr, idx
                // 3. load (float2*) element_addr
                //
                // Transformed IR
                // 1. src_addr = gep (float4*) src, idx / 2
                // 2. src_val(float4) = load (float4*) src_addr
                // 3. tmp_val1(float) = extractelement (idx % 2) * 2
                // 4. tmp_val2(float) = extractelement (idx % 2) * 2 + 1
                // 5. dst_val(float2) = insertelement undef(float2), tmp_val1, 0
                // 6. dst_val(float2) = insertelement undef(float2), tmp_val2, 1
                // 7. dst_val(float2) = bitcast dst_val, (float2)
                // ==> if types are same between src and dst, it will be
                // igonored
                //
                VectorType *TmpVecTy =
                    VectorType::get(SrcEleTy, DstTyBitWidth / SrcEleTyBitWidth);
                DstVal = UndefValue::get(TmpVecTy);
                Value *EleIdx = Builder.CreateAnd(
                    OrgGEPIdx, Builder.getInt32(NumElement - 1));
                EleIdx = Builder.CreateShl(
                    EleIdx, Builder.getInt32(
                                std::log2(DstTyBitWidth / SrcEleTyBitWidth)));
                Value *TmpOrgGEPIdx = EleIdx;
                for (unsigned i = 0; i < NumElement; i++) {
                  Value *TmpVal = Builder.CreateExtractElement(
                      LDValues[0], TmpOrgGEPIdx, "tmp_val");
                  DstVal = Builder.CreateInsertElement(DstVal, TmpVal,
                                                       Builder.getInt32(i));

                  if (i + 1 < NumElement) {
                    TmpOrgGEPIdx =
                        Builder.CreateAdd(TmpOrgGEPIdx, Builder.getInt32(1));
                  }
                }
              } else {
                //
                // Consider below case.
                //
                // Original IR (float4* --> int2*)
                // 1. src_addr = bitcast float4*, int2*
                // 2. load (int2*) src_addr
                //
                // Transformed IR
                // 1. src_val(float4) = load (float4*) src_addr
                // 2. tmp_val(float2) = shufflevector (float4)src_val,
                //                                    (float4)undef,
                //                                    (float2)<0, 1>
                // 3. dst_val(int2) = bitcast (float2)tmp_val, (int2)
                //
                unsigned NumElement = DstTyBitWidth / SrcEleTyBitWidth;
                Value *Undef = UndefValue::get(SrcTy);

                SmallVector<uint32_t, 4> Idxs;
                for (unsigned i = 0; i < NumElement; i++) {
                  Idxs.push_back(i);
                }
                DstVal = Builder.CreateShuffleVector(LDValues[0], Undef, Idxs);

                DstVal = Builder.CreateBitCast(DstVal, DstTy);
              }

              DstVal = Builder.CreateBitCast(DstVal, DstTy);
            } else {
              if (IsGEPUser) {
                //
                // Consider below case.
                //
                // Original IR (int4* --> char2*)
                // 1. src_addr = bitcast int4*, char2*
                // 2. element_addr = gep (char2*) src_addr, idx
                // 3. load (char2*) element_addr
                //
                // Transformed IR
                // 1. src_addr = gep (int4*) src, idx / 8
                // 2. src_val(int4) = load (int4*) src_addr
                // 3. tmp_val(int) = extractelement idx / 2
                // 4. tmp_val(<i16 x 2>) = bitcast tmp_val(int), (<i16 x 2>)
                // 5. tmp_val(i16) = extractelement idx % 2
                // 6. dst_val(char2) = bitcast tmp_val, (char2)
                // ==> if types are same between src and dst, it will be
                // igonored
                //
                unsigned NumElement = SrcTyBitWidth / DstTyBitWidth;
                unsigned SubNumElement = SrcEleTyBitWidth / DstTyBitWidth;
                if (SubNumElement != 2 && SubNumElement != 4) {
                  llvm_unreachable("Unsupported SubNumElement");
                }

                Value *TmpOrgGEPIdx = Builder.CreateLShr(
                    OrgGEPIdx, Builder.getInt32(std::log2(SubNumElement)));
                Value *TmpVal = Builder.CreateExtractElement(
                    LDValues[0], TmpOrgGEPIdx, "tmp_val");
                TmpVal = Builder.CreateBitCast(
                    TmpVal,
                    VectorType::get(
                        IntegerType::get(DstTy->getContext(), DstTyBitWidth),
                        SubNumElement));
                TmpOrgGEPIdx = Builder.CreateAnd(
                    OrgGEPIdx, Builder.getInt32(SubNumElement - 1));
                TmpVal = Builder.CreateExtractElement(TmpVal, TmpOrgGEPIdx,
                                                      "tmp_val");
                DstVal = Builder.CreateBitCast(TmpVal, DstTy);
              } else {
                Inst->print(errs());
                llvm_unreachable("Handle this bitcast");
              }
            }
          } else if (SrcTyBitWidth < DstTyBitWidth) {
            //
            // Consider below case.
            //
            // Original IR (float2* --> float4*)
            // 1. src_addr = bitcast float2*, float4*
            // 2. element_addr = gep (float4*) src_addr, idx
            // 3. load (float4*) element_addr
            //
            // Transformed IR
            // 1. src_addr = gep (float2*) src, idx * 2
            // 2. src_val1(float2) = load (float2*) src_addr
            // 3. src_addr2 = gep (float2*) src_addr, 1
            // 4. src_val2(float2) = load (float2*) src_addr2
            // 5. dst_val(float4) = shufflevector src_val1, src_val2, <0, 1>
            // 6. dst_val(float4) = bitcast dst_val, (float4)
            // ==> if types are same between src and dst, it will be igonored
            //
            unsigned NumElement = 1;
            if (SrcTy->isVectorTy()) {
              NumElement = SrcTy->getVectorNumElements() * 2;
            }

            // Handle scalar type.
            if (NumElement == 1) {
              if (SrcTyBitWidth * 4 <= DstTyBitWidth) {
                unsigned NumVecElement = DstTyBitWidth / SrcTyBitWidth;
                unsigned NumVector = 1;
                if (NumVecElement > 4) {
                  NumVector = NumVecElement >> 2;
                  NumVecElement = 4;
                }

                SmallVector<Value *, 4> Values;
                for (unsigned VIdx = 0; VIdx < NumVector; VIdx++) {
                  // In this case, generate only insert element. It generates
                  // less instructions than using shuffle vector.
                  VectorType *TmpVecTy = VectorType::get(SrcTy, NumVecElement);
                  Value *TmpVal = UndefValue::get(TmpVecTy);
                  for (unsigned i = 0; i < NumVecElement; i++) {
                    TmpVal = Builder.CreateInsertElement(
                        TmpVal, LDValues[i + (VIdx * 4)], Builder.getInt32(i));
                  }
                  Values.push_back(TmpVal);
                }

                if (Values.size() > 2) {
                  Inst->print(errs());
                  llvm_unreachable("Support above bitcast");
                }

                if (Values.size() > 1) {
                  Type *TmpEleTy =
                      Type::getIntNTy(M.getContext(), SrcEleTyBitWidth * 2);
                  VectorType *TmpVecTy = VectorType::get(TmpEleTy, NumVector);
                  for (unsigned i = 0; i < Values.size(); i++) {
                    Values[i] = Builder.CreateBitCast(Values[i], TmpVecTy);
                  }
                  SmallVector<uint32_t, 4> Idxs;
                  for (unsigned i = 0; i < (NumVector * 2); i++) {
                    Idxs.push_back(i);
                  }
                  for (unsigned i = 0; i < Values.size(); i = i + 2) {
                    Values[i] = Builder.CreateShuffleVector(
                        Values[i], Values[i + 1], Idxs);
                  }
                }

                LDValues.clear();
                LDValues.push_back(Values[0]);
              } else {
                SmallVector<Value *, 4> TmpLDValues;
                for (unsigned i = 0; i < LDValues.size(); i = i + 2) {
                  VectorType *TmpVecTy = VectorType::get(SrcTy, 2);
                  Value *TmpVal = UndefValue::get(TmpVecTy);
                  TmpVal = Builder.CreateInsertElement(TmpVal, LDValues[i],
                                                       Builder.getInt32(0));
                  TmpVal = Builder.CreateInsertElement(TmpVal, LDValues[i + 1],
                                                       Builder.getInt32(1));
                  TmpLDValues.push_back(TmpVal);
                }
                LDValues.clear();
                LDValues = std::move(TmpLDValues);
                NumElement = 4;
              }
            }

            // Handle vector type.
            while (LDValues.size() != 1) {
              SmallVector<Value *, 4> TmpLDValues;
              for (unsigned i = 0; i < LDValues.size(); i = i + 2) {
                SmallVector<uint32_t, 4> Idxs;
                for (unsigned j = 0; j < NumElement; j++) {
                  Idxs.push_back(j);
                }
                Value *TmpVal = Builder.CreateShuffleVector(
                    LDValues[i], LDValues[i + 1], Idxs);
                TmpLDValues.push_back(TmpVal);
              }
              LDValues.clear();
              LDValues = std::move(TmpLDValues);
              NumElement *= 2;
            }

            DstVal = Builder.CreateBitCast(LDValues[0], DstTy);
          } else {
            //
            // Consider below case.
            //
            // Original IR (float4* --> int4*)
            // 1. src_addr = bitcast float4*, int4*
            // 2. element_addr = gep (int4*) src_addr, idx, 0
            // 3. load (int) element_addr
            //
            // Transformed IR
            // 1. element_addr = gep (float4*) src_addr, idx, 0
            // 2. src_val = load (float*) element_addr
            // 3. val = bitcast (float) src_val to (int)
            //
            Value *SrcAddr = Src;
            if (IsGEPUser) {
              SmallVector<Value *, 4> Idxs;
              for (unsigned i = 1; i < GEP->getNumOperands(); i++) {
                Idxs.push_back(GEP->getOperand(i));
              }
              SrcAddr = Builder.CreateGEP(Src, Idxs);
            }
            LoadInst *SrcVal = Builder.CreateLoad(SrcAddr, "src_val");

            Type *TmpDstTy = DstTy;
            if (IsGEPUser) {
              if (GEP->getNumOperands() > 2) {
                TmpDstTy = DstEleTy;
              }
            }
            DstVal = Builder.CreateBitCast(SrcVal, TmpDstTy);
          }

          // Update LD's users with DstVal.
          LD->replaceAllUsesWith(DstVal);
        } else {
          U->print(errs());
          llvm_unreachable(
              "Handle above user of gep on ReplacePointerBitcastPass");
        }

        ToBeDeleted.push_back(cast<Instruction>(U));
      }

      if (IsGEPUser) {
        ToBeDeleted.push_back(GEP);
      }
    }

    ToBeDeleted.push_back(Inst);
  }

  for (Instruction *Inst : ScalarWorkList) {
    // Some tests have a stray bitcast from pointer-to-array to
    // pointer to i8*, but the bitcast has no uses.  Exit early
    // but be sure to delete it later.
    //
    // Example:
    //   %1 = bitcast [25 x float]* %dst to i8*

    // errs () << " Scalar bitcast is " << *Inst << "\n";

    if (!Inst->hasNUsesOrMore(1)) {
      ToBeDeleted.push_back(Inst);
      continue;
    }

    Value *Src = Inst->getOperand(0);
    Type *SrcTy; // Original type
    Type *DstTy; // Type that SrcTy is cast to.
    unsigned SrcTyBitWidth;
    unsigned DstTyBitWidth;

    SrcTy = Src->getType()->getPointerElementType();
    DstTy = Inst->getType()->getPointerElementType();
    int iter_count = 0;
    while (++iter_count) {
      SrcTyBitWidth = unsigned(DL.getTypeStoreSizeInBits(SrcTy));
      DstTyBitWidth = unsigned(DL.getTypeStoreSizeInBits(DstTy));
#if 0
      errs() << "  Try Src " << *Src << "\n";
      errs() << "  SrcTy elem " << *SrcTy << " bit width " << SrcTyBitWidth
             << "\n";
      errs() << "  DstTy elem " << *DstTy << " bit width " << DstTyBitWidth
             << "\n";
#endif

      // The normal case that we can handle is source type is smaller than
      // the dest type.
      if (SrcTyBitWidth <= DstTyBitWidth)
        break;

      // The Source type is bigger than the destination type.
      // Walk into the source type to break it down.
      if (SrcTy->isArrayTy()) {
        // If it's an array, consider only the first element.
        Value *Zero = ConstantInt::get(Type::getInt32Ty(M.getContext()), 0);
        Instruction *NewSrc =
            GetElementPtrInst::CreateInBounds(Src, {Zero, Zero});
        // errs() << "NewSrc is " << *NewSrc << "\n";
        if (auto *SrcInst = dyn_cast<Instruction>(Src)) {
          // errs() << " instruction case\n";
          NewSrc->insertAfter(SrcInst);
        } else {
          // Could be a parameter.
          auto where = Inst->getParent()
                           ->getParent()
                           ->getEntryBlock()
                           .getFirstInsertionPt();
          Instruction &whereInst = *where;
          // errs() << "insert " << *NewSrc << " before " << whereInst << "\n";
          NewSrc->insertBefore(&whereInst);
        }
        Src = NewSrc;
        SrcTy = Src->getType()->getPointerElementType();
      } else {
        errs() << "Replace pointer bitcasts: unhandled case: non-array "
                  "non-vector source type "
               << *SrcTy << " is wider than dest type " << *DstTy << "\n";
        llvm_unreachable("ReplacePointerBitcastPass: non-array non-vector "
                         "source type is wider than dest type");
      }
      if (iter_count > 1000) {
        llvm_unreachable("ReplacePointerBitcastPass: Too many iterations!");
      }
    };
#if 0
    errs() << " Src is " << *Src << "\n";
    errs() << " Dst is " << *Inst << "\n";
    errs() << "  SrcTy elem " << *SrcTy << " bit width " << SrcTyBitWidth
           << "\n";
    errs() << "  DstTy elem " << *DstTy << " bit width " << DstTyBitWidth
           << "\n";
#endif

    for (User *BitCastUser : Inst->users()) {
      Value *NewAddrIdx = ConstantInt::get(Type::getInt32Ty(M.getContext()), 0);
      // It consist of User* and bool whether user is gep or not.
      SmallVector<std::pair<User *, bool>, 32> Users;

      GetElementPtrInst *GEP = nullptr;
      Value *OrgGEPIdx = nullptr;
      if ((GEP = dyn_cast<GetElementPtrInst>(BitCastUser))) {
        IRBuilder<> Builder(GEP);

        // Build new src/dst address.
        OrgGEPIdx = GEP->getOperand(1);
        NewAddrIdx = CalculateNewGEPIdx(SrcTyBitWidth, DstTyBitWidth, GEP);

        // If bitcast's user is gep, investigate gep's users too.
        for (User *GEPUser : GEP->users()) {
          Users.push_back(std::make_pair(GEPUser, true));
        }
      } else {
        Users.push_back(std::make_pair(BitCastUser, false));
      }

      // Handle users.
      bool IsGEPUser = false;
      for (auto UserIter : Users) {
        User *U = UserIter.first;
        IsGEPUser = UserIter.second;

        IRBuilder<> Builder(cast<Instruction>(U));

        // Handle store instruction with gep.
        if (StoreInst *ST = dyn_cast<StoreInst>(U)) {
          // errs() << " store is " << *ST << "\n";
          if (SrcTyBitWidth == DstTyBitWidth) {
            auto STVal = ConvertValue(ST->getValueOperand(), SrcTy, Builder);
            Value *DstAddr = Builder.CreateGEP(Src, NewAddrIdx);
            Builder.CreateStore(STVal, DstAddr);
          } else if (SrcTyBitWidth < DstTyBitWidth) {
            unsigned NumElement = DstTyBitWidth / SrcTyBitWidth;

            // Create Mask.
            Constant *Mask = nullptr;
            if (NumElement == 1) {
              Mask = Builder.getInt32(0xFF);
            } else if (NumElement == 2) {
              Mask = Builder.getInt32(0xFFFF);
            } else if (NumElement == 4) {
              Mask = Builder.getInt32(0xFFFFFFFF);
            } else {
              llvm_unreachable("strange type on bitcast");
            }

            // Create store values.
            Value *STVal = ST->getValueOperand();
            SmallVector<Value *, 8> STValues;
            for (unsigned i = 0; i < NumElement; i++) {
              Type *TmpTy = Type::getIntNTy(M.getContext(), DstTyBitWidth);
              Value *TmpVal = Builder.CreateBitCast(STVal, TmpTy);
              TmpVal = Builder.CreateLShr(TmpVal,
                                          Builder.getInt32(i * SrcTyBitWidth));
              TmpVal = Builder.CreateAnd(TmpVal, Mask);
              TmpVal = Builder.CreateTrunc(TmpVal, SrcTy);
              STValues.push_back(TmpVal);
            }

            // Generate stores.
            Value *SrcAddrIdx = NewAddrIdx;
            Value *BaseAddr = Src;
            for (unsigned i = 0; i < NumElement; i++) {
              // Calculate store address.
              Value *DstAddr = Builder.CreateGEP(BaseAddr, SrcAddrIdx);
              Builder.CreateStore(STValues[i], DstAddr);

              if (i + 1 < NumElement) {
                // Calculate next store address
                SrcAddrIdx = Builder.CreateAdd(SrcAddrIdx, Builder.getInt32(1));
              }
            }

          } else {
            Inst->print(errs());
            llvm_unreachable("Handle different size store with scalar "
                             "bitcast on ReplacePointerBitcastPass");
          }
        } else if (LoadInst *LD = dyn_cast<LoadInst>(U)) {
          if (SrcTyBitWidth == DstTyBitWidth) {
            Value *SrcAddr = Builder.CreateGEP(Src, NewAddrIdx);
            LoadInst *SrcVal = Builder.CreateLoad(SrcAddr, "src_val");
            LD->replaceAllUsesWith(ConvertValue(SrcVal, DstTy, Builder));
          } else if (SrcTyBitWidth < DstTyBitWidth) {
            Value *SrcAddrIdx = NewAddrIdx;

            // Load value from src.
            unsigned NumIter = CalculateNumIter(SrcTyBitWidth, DstTyBitWidth);
            SmallVector<Value *, 8> LDValues;
            for (unsigned i = 1; i <= NumIter; i++) {
              Value *SrcAddr = Builder.CreateGEP(Src, SrcAddrIdx);
              LoadInst *SrcVal = Builder.CreateLoad(SrcAddr, "src_val");
              LDValues.push_back(SrcVal);

              if (i + 1 <= NumIter) {
                // Calculate next SrcAddrIdx.
                SrcAddrIdx = Builder.CreateAdd(SrcAddrIdx, Builder.getInt32(1));
              }
            }

            // Merge Load.
            Type *TmpSrcTy = Type::getIntNTy(M.getContext(), SrcTyBitWidth);
            Value *DstVal = Builder.CreateBitCast(LDValues[0], TmpSrcTy);
            Type *TmpDstTy = Type::getIntNTy(M.getContext(), DstTyBitWidth);
            DstVal = Builder.CreateZExt(DstVal, TmpDstTy);
            for (unsigned i = 1; i < LDValues.size(); i++) {
              Value *TmpVal = Builder.CreateBitCast(LDValues[i], TmpSrcTy);
              TmpVal = Builder.CreateZExt(TmpVal, TmpDstTy);
              TmpVal = Builder.CreateShl(TmpVal,
                                         Builder.getInt32(i * SrcTyBitWidth));
              DstVal = Builder.CreateOr(DstVal, TmpVal);
            }

            DstVal = Builder.CreateBitCast(DstVal, DstTy);
            LD->replaceAllUsesWith(DstVal);

          } else {
            Inst->print(errs());
            llvm_unreachable("Handle different size load with scalar "
                             "bitcast on ReplacePointerBitcastPass");
          }
        } else {
          Inst->print(errs());
          llvm_unreachable("Handle above user of scalar bitcast with gep on "
                           "ReplacePointerBitcastPass");
        }

        ToBeDeleted.push_back(cast<Instruction>(U));
      }

      if (IsGEPUser) {
        ToBeDeleted.push_back(GEP);
      }
    }

    ToBeDeleted.push_back(Inst);
  }

  for (Instruction *Inst : ToBeDeleted) {
    Inst->eraseFromParent();
  }

  return Changed;
}
