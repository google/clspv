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
#include "llvm/Transforms/Utils/Local.h"

#include "ReplacePointerBitcastPass.h"

using namespace llvm;

#define DEBUG_TYPE "replacepointerbitcast"

#define DEBUG_FCT_TY_VALUES(Ty, Values)                                        \
  do {                                                                         \
    LLVM_DEBUG(fprintf(stderr, "%s: ", __func__); Ty->dump();                  \
               fprintf(stderr, "\tValues[0/%lu] = ", Values.size());           \
               Values[0]->dump());                                             \
  } while (0)
#define DEBUG_FCT_VALUES(Values)                                               \
  do {                                                                         \
    LLVM_DEBUG(                                                                \
        fprintf(stderr, "%s: Values[0/%lu] = ", __func__, Values.size());      \
        Values[0]->dump());                                                    \
  } while (0)

using WeakInstructions = SmallVector<WeakTrackingVH, 16>;

namespace {

// Returns the size in bits of 'Ty'
// In the case of a vector of 3 elements, return the size of the same vector of
// 4 elements as vec3 has padding between 2 vectors.
size_t SizeInBits(const DataLayout &DL, Type *Ty) {
  if (auto VecTy = dyn_cast<FixedVectorType>(Ty)) {
    if (VecTy->getNumElements() == 3) {
      return 4 * SizeInBits(DL, VecTy->getElementType());
    }
  }
  return DL.getTypeStoreSizeInBits(Ty);
}

// Same as above with different arguments
size_t SizeInBits(IRBuilder<> &builder, Type *Ty) {
  return SizeInBits(
      builder.GetInsertBlock()->getParent()->getParent()->getDataLayout(), Ty);
}

// Returns the element type when 'Ty' is a vector or an array, otherwise returns
// 'Ty'.
Type *GetEleType(Type *Ty) {
  if (auto VecTy = dyn_cast<VectorType>(Ty)) {
    return VecTy->getElementType();
  } else if (auto ArrTy = dyn_cast<ArrayType>(Ty)) {
    return ArrTy->getElementType();
  } else {
    return Ty;
  }
}

// Returns the number of elements when 'Ty' is a vector or an array, otherwise
// returns 1.
unsigned GetNumEle(Type *Ty) {
  if (auto VecTy = dyn_cast<FixedVectorType>(Ty)) {
    return VecTy->getNumElements();
  } else if (auto ArrTy = dyn_cast<ArrayType>(Ty)) {
    return ArrTy->getNumElements();
  } else {
    return 1;
  }
}

// Gathers the scalar values of |v| into |elements|. Generates new instructions
// to extract the values.
void GatherBaseElements(Value *v, SmallVectorImpl<Value *> *elements,
                        IRBuilder<> &builder) {
  auto *module = builder.GetInsertBlock()->getParent()->getParent();
  auto &DL = module->getDataLayout();
  auto *type = v->getType();
  if (auto *vec_type = dyn_cast<VectorType>(type)) {
    for (uint64_t i = 0; i != vec_type->getElementCount().getKnownMinValue();
         ++i) {
      elements->push_back(builder.CreateExtractElement(v, i));
    }
  } else if (auto *array_type = dyn_cast<ArrayType>(type)) {
    for (uint64_t i = 0; i != array_type->getNumElements(); ++i) {
      auto *extract = builder.CreateExtractValue(v, {static_cast<unsigned>(i)});
      GatherBaseElements(extract, elements, builder);
    }
  } else if (auto *struct_type = dyn_cast<StructType>(type)) {
    const auto *struct_layout = DL.getStructLayout(struct_type);
    if (struct_layout->hasPadding()) {
      llvm_unreachable("Unhandled conversion of padded struct");
    }
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
    const auto *struct_layout = DL.getStructLayout(dst_struct_ty);
    if (struct_layout->hasPadding()) {
      llvm_unreachable("Unhandled padded struct conversion");
      return nullptr;
    }
    for (unsigned i = 0; i != dst_struct_ty->getNumElements(); ++i) {
      auto *ele_ty = dst_struct_ty->getElementType(i);
      auto *tmp_value =
          BuildFromElements(ele_ty, src_elements, used_bits, index, builder);
      auto *prev = dst ? dst : UndefValue::get(dst_type);
      dst = builder.CreateInsertValue(prev, tmp_value, {i});
    }
  } else if (auto *dst_vec_ty = dyn_cast<VectorType>(dst_type)) {
    auto *ele_ty = dst_vec_ty->getElementType();
    for (uint64_t i = 0; i != dst_vec_ty->getElementCount().getKnownMinValue();
         ++i) {
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
      if (needed_bits < remaining_bits && needed_bits < dst_width) {
        // Ensure only the needed bits are used.
        uint64_t mask = (1ull << needed_bits) - 1;
        tmp_value =
            builder.CreateAnd(tmp_value, builder.getIntN(ele_width, mask));
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

    // Check that overall sizes make sense.
    uint64_t element_sum = 0;
    // Can only successfully convert unpadded structs.
    for (auto element : src_elements) {
      element_sum += DL.getTypeStoreSizeInBits(element->getType());
    }
    if (DL.getTypeStoreSizeInBits(dst_type) != element_sum) {
      llvm_unreachable("Elements do not sum to overall size");
      return nullptr;
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

void InsertInArray(IRBuilder<> &Builder, ArrayType *Ty,
                   SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  unsigned ArrayNumEles = Ty->getNumElements();
  assert(Values.size() % ArrayNumEles == 0);
  unsigned NumArrays = Values.size() / ArrayNumEles;
  for (unsigned i = 0; i < NumArrays; i++) {
    Value *Ret = UndefValue::get(Ty);
    for (unsigned j = 0; j < ArrayNumEles; j++) {
      Ret = Builder.CreateInsertValue(Ret, Values[i * ArrayNumEles + j], {j});
    }
    Values[i] = Ret;
  }
  Values.resize(NumArrays);
}

void ExtractFromVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  SmallVector<Value *, 8> ScalarValues;
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());
  for (unsigned i = 0; i < Values.size(); i++) {
    for (unsigned j = 0; j < cast<FixedVectorType>(ValueTy)->getNumElements();
         j++) {
      ScalarValues.push_back(Builder.CreateExtractElement(Values[i], j));
    }
  }
  Values.clear();
  Values = std::move(ScalarValues);
}

void ExtractFromArray(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  SmallVector<Value *, 8> ScalarValues;
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isArrayTy());
  for (unsigned i = 0; i < Values.size(); i++) {
    for (unsigned j = 0; j < cast<ArrayType>(ValueTy)->getNumElements(); j++) {
      ScalarValues.push_back(Builder.CreateExtractValue(Values[i], j));
    }
  }
  Values.clear();
  Values = std::move(ScalarValues);
}

// Return a scalar type of size 'N' matching the 'TargetTy' if possible.
Type *getNTy(IRBuilder<> &Builder, unsigned N, Type *TargetTy) {
  if (GetEleType(TargetTy)->isFloatTy() && N == 32) {
    return Builder.getFloatTy();
  } else if (GetEleType(TargetTy)->isHalfTy() && N == 16) {
    return Builder.getHalfTy();
  } else {
    return Builder.getIntNTy(N);
  }
}

// Convert all elements of 'Values' into 'Ty' using 'ConvertValue'.
// Expect all values to have the same type;
void BitcastValues(IRBuilder<> &Builder, Type *Ty,
                   SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(SizeInBits(Builder, ValueTy) == SizeInBits(Builder, Ty));

  if (Ty == ValueTy) {
    return;
  }

  for (unsigned i = 0; i < Values.size(); i++) {
    Values[i] = ConvertValue(Values[i], Ty, Builder);
  }
}

// Bitcast 'Values' into a vector type with 'NumElePerVec' elements, but with
// the same global size as before.
void BitcastIntoVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values,
                       unsigned NumElePerVec, Type *Ty) {
  DEBUG_FCT_VALUES(Values);
  Type *SrcTy = Values[0]->getType();
  unsigned SrcSize = SizeInBits(Builder, SrcTy);
  assert(SrcSize % NumElePerVec == 0);
  unsigned SrcEleSize = SrcSize / NumElePerVec;
  VectorType *DstTy = FixedVectorType::get(
      getNTy(Builder, SrcEleSize, GetEleType(Ty)), NumElePerVec);
  BitcastValues(Builder, DstTy, Values);
}

// 'Values' is expected to contain scalar values.
// Group those values in vector of size 'NumElePerVec'.
void GroupScalarValuesIntoVector(IRBuilder<> &Builder,
                                 SmallVector<Value *, 8> &Values,
                                 unsigned NumElePerVec) {
  DEBUG_FCT_VALUES(Values);
  Type *SrcTy = Values[0]->getType();
  assert(!SrcTy->isVectorTy() && !SrcTy->isArrayTy());
  VectorType *DstTy = FixedVectorType::get(SrcTy, NumElePerVec);
  assert(Values.size() % NumElePerVec == 0);
  unsigned int NumVector = Values.size() / NumElePerVec;
  for (unsigned i = 0; i < NumVector; i++) {
    unsigned idx = i * NumElePerVec;
    Value *Vec = UndefValue::get(DstTy);
    for (unsigned j = 0; j < NumElePerVec; j++) {
      Vec = Builder.CreateInsertElement(Vec, Values[idx + j],
                                        Builder.getInt32(j));
    }
    Values[i] = Vec;
  }
  Values.resize(NumVector);
}

// 'Values' is expected to contain an even number of vectors of 2 elements.
// Group them into vectors of 4 elements using shuffles.
void GroupVectorValuesInPair(IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  assert(Values[0]->getType()->isVectorTy() &&
         cast<FixedVectorType>(Values[0]->getType())->getNumElements() == 2);
  assert(Values.size() % 2 == 0);
  unsigned NewValuesSize = Values.size() / 2;

  for (unsigned i = 0; i < NewValuesSize; i++) {
    unsigned idx = 2 * i;
    Values[i] =
        Builder.CreateShuffleVector(Values[idx], Values[idx + 1], {0, 1, 2, 3});
  }
  Values.resize(NewValuesSize);
}

// 'Values' is expected to contain vectors of 4 elements.
// Split them into vectors of 2 elements using shuffles.
void SplitVectorValuesInPair(IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values, Type *Ty) {
  DEBUG_FCT_VALUES(Values);
  assert(Values[0]->getType()->isVectorTy());
  assert(GetNumEle(Values[0]->getType()) == 4);

  // Bitcast before splitting to have less bitcast
  BitcastIntoVector(Builder, Values, 4, Ty);

  SmallVector<Value *, 8> DstValues;
  for (unsigned i = 0; i < Values.size(); i++) {
    DstValues.push_back(Builder.CreateShuffleVector(Values[i], {0, 1}));
    DstValues.push_back(Builder.CreateShuffleVector(Values[i], {2, 3}));
  }
  Values.clear();
  Values = std::move(DstValues);
}

// Split 'Values' until the element size of the vector is equal to the size of
// 'Ty'.
// 'Values' is expected to contains vectors.
void SplitVectorUntilEleSizeEquals(Type *Ty, IRBuilder<> &Builder,
                                   SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());

  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned TySize = SizeInBits(Builder, Ty);
  while (ValueEleSize > TySize) {
    if (TySize * 4 == ValueEleSize) {
      // Ty: i8 - ValueTy: <4 x i32>
      // <4 x i32> -> i32 -> <4 x i8>
      ExtractFromVector(Builder, Values);
      BitcastIntoVector(Builder, Values, 4, Ty);
    } else if (ValueNumEle == 2) {
      // <2 x i32> -> <4 x i16>
      BitcastIntoVector(Builder, Values, 4, Ty);
    } else if (ValueNumEle == 4) {
      // <4 x i32> -> <2 x i32>
      SplitVectorValuesInPair(Builder, Values, Ty);
    } else {
      llvm_unreachable("ConvertVectorIntoVector internal error");
    }
    Type *Tmp = Values[0]->getType();
    ValueEleSize = SizeInBits(Builder, GetEleType(Tmp));
    ValueNumEle = GetNumEle(Tmp);
  }
}

// Split 'Values' until the size of the vector is equal to the size of 'Ty'.
// 'Values' is expected to contains vectors.
void SplitVectorUntilSizeEquals(Type *Ty, IRBuilder<> &Builder,
                                SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());

  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned TySize = SizeInBits(Builder, Ty);

  while ((ValueEleSize * ValueNumEle) > TySize) {
    if (ValueNumEle == 2) {
      // <2 x i32> -> <4 x i16>
      BitcastIntoVector(Builder, Values, 4, Ty);
    } else if (ValueNumEle == 4) {
      // <4 x i32> -> <2 x i32>
      SplitVectorValuesInPair(Builder, Values, Ty);
    } else {
      llvm_unreachable("ConvertVectorIntoVector internal error");
    }
    Type *Tmp = Values[0]->getType();
    ValueEleSize = SizeInBits(Builder, GetEleType(Tmp));
    ValueNumEle = GetNumEle(Tmp);
  }
}

// Group 'Values' until the element size of the vector is equal to the size of
// 'Ty'.
// 'Values' is expected to contains vectors.
void GroupVectorUntilEleSizeEquals(Type *Ty, IRBuilder<> &Builder,
                                   SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());

  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned TySize = SizeInBits(Builder, Ty);
  while (ValueEleSize < TySize) {
    if (ValueNumEle == 2) {
      // <2 x i16> -> <4 x i16>
      GroupVectorValuesInPair(Builder, Values);
    } else if (ValueNumEle == 4) {
      // <4 x i16> -> <2 x i32>
      BitcastIntoVector(Builder, Values, 2, Ty);
    } else {
      llvm_unreachable("ConvertVectorIntoVector internal error");
    }
    Type *Tmp = Values[0]->getType();
    ValueEleSize = SizeInBits(Builder, GetEleType(Tmp));
    ValueNumEle = GetNumEle(Tmp);
  }
}

// Group 'Values' until the size of the vector is equal to the size of 'Ty'.
// 'Values' is expected to contains vectors.
void GroupVectorUntilSizeEquals(Type *Ty, IRBuilder<> &Builder,
                                SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());

  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned TySize = SizeInBits(Builder, Ty);
  while ((ValueEleSize * ValueNumEle) < TySize) {
    if (ValueNumEle == 2) {
      // <2 x i16> -> <4 x i16>
      GroupVectorValuesInPair(Builder, Values);
    } else if (ValueNumEle == 4) {
      // <4 x i16> -> <2 x i32>
      BitcastIntoVector(Builder, Values, 2, Ty);
    } else {
      llvm_unreachable("ConvertVectorIntoVector internal error");
    }
    Type *Tmp = Values[0]->getType();
    ValueEleSize = SizeInBits(Builder, GetEleType(Tmp));
    ValueNumEle = GetNumEle(Tmp);
  }
}

void ConvertVectorIntoVector(FixedVectorType *Ty, IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());
  if (Ty == ValueTy) {
    return;
  }

  Type *TyEle = GetEleType(Ty);

  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned TyEleSize = SizeInBits(Builder, GetEleType(Ty));

  // Adjust the size of the vector element
  if (ValueEleSize < TyEleSize) {
    GroupVectorUntilEleSizeEquals(TyEle, Builder, Values);
  } else if (ValueEleSize > TyEleSize) {
    SplitVectorUntilEleSizeEquals(TyEle, Builder, Values);
  }

  ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());

  // Adjust the number of element per vector
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned TyNumEle = GetNumEle(Ty);
  if (ValueNumEle > TyNumEle) {
    assert(ValueNumEle == 4 && TyNumEle == 2);
    SplitVectorValuesInPair(Builder, Values, TyEle);
  } else if (ValueNumEle < TyNumEle) {
    assert(ValueNumEle == 2 && TyNumEle == 4);
    GroupVectorValuesInPair(Builder, Values);
  }

  BitcastValues(Builder, Ty, Values);
}

void ConvertVectorIntoScalar(Type *Ty, IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(!Ty->isVectorTy() && !Ty->isArrayTy() && ValueTy->isVectorTy());

  if (Ty == ValueTy) {
    return;
  }

  unsigned TySize = SizeInBits(Builder, Ty);
  unsigned ValueEleSize = SizeInBits(Builder, GetEleType(ValueTy));
  unsigned ValueNumEle = GetNumEle(ValueTy);
  unsigned ValueSize = SizeInBits(Builder, ValueTy);

  if (ValueEleSize > TySize) {
    SplitVectorUntilEleSizeEquals(Ty, Builder, Values);
    BitcastIntoVector(Builder, Values, GetNumEle(Values[0]->getType()), Ty);
    ExtractFromVector(Builder, Values);
  } else if (ValueEleSize == TySize) {
    BitcastIntoVector(Builder, Values, ValueNumEle, Ty);
    ExtractFromVector(Builder, Values);
  } else {
    // ValueEleSize < TySize
    if (ValueSize > TySize) {
      assert(ValueNumEle == 4 && ValueEleSize * 2 == TySize);
      SplitVectorValuesInPair(Builder, Values, Ty);
    } else if (ValueSize < TySize) {
      GroupVectorUntilSizeEquals(Ty, Builder, Values);
    }
  }

  BitcastValues(Builder, Ty, Values);
}

void ConvertScalarIntoVector(FixedVectorType *Ty, IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(!ValueTy->isVectorTy() && !ValueTy->isArrayTy());

  if (Ty == ValueTy) {
    return;
  }

  unsigned TySize = SizeInBits(Builder, Ty);
  unsigned ValueSize = SizeInBits(Builder, ValueTy);
  if (TySize > ValueSize) {
    assert(TySize % ValueSize == 0);
    unsigned NumElements = std::min(TySize / ValueSize, (unsigned)4);
    GroupScalarValuesIntoVector(Builder, Values, NumElements);
    GroupVectorUntilSizeEquals(Ty, Builder, Values);
  } else if (TySize < ValueSize) {
    assert(ValueSize % TySize == 0);
    unsigned NumElements = std::min(ValueSize / TySize, (unsigned)4);
    BitcastIntoVector(Builder, Values, NumElements, Ty);
    SplitVectorUntilSizeEquals(Ty, Builder, Values);
  }

  BitcastValues(Builder, Ty, Values);
}

void ConvertScalarIntoScalar(Type *Ty, IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();
  assert(!Ty->isVectorTy() && !Ty->isArrayTy() && !ValueTy->isVectorTy() &&
         !ValueTy->isArrayTy());

  if (Ty == ValueTy) {
    return;
  }

  unsigned ValueSize = SizeInBits(Builder, ValueTy);
  unsigned TySize = SizeInBits(Builder, Ty);
  if (ValueSize > TySize) {
    assert(ValueSize % TySize == 0);
    unsigned NumElements = std::min(ValueSize / TySize, (unsigned)4);
    BitcastIntoVector(Builder, Values, NumElements, Ty);
    SplitVectorUntilEleSizeEquals(Ty, Builder, Values);
    ExtractFromVector(Builder, Values);
  } else if (ValueSize < TySize) {
    assert(TySize % ValueSize == 0);
    unsigned NumElements = std::min(TySize / ValueSize, (unsigned)4);
    GroupScalarValuesIntoVector(Builder, Values, NumElements);
    GroupVectorUntilSizeEquals(Ty, Builder, Values);
  }

  BitcastValues(Builder, Ty, Values);
}

void ConvertInto(Type *Ty, IRBuilder<> &Builder,
                 SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  Type *ValueTy = Values[0]->getType();

  if (Ty == ValueTy) {
    return;
  }
  if (auto VecTy = dyn_cast<FixedVectorType>(Ty)) {
    if (ValueTy->isVectorTy()) {
      ConvertVectorIntoVector(VecTy, Builder, Values);
    } else {
      ConvertScalarIntoVector(VecTy, Builder, Values);
    }
  } else {
    Type *EleTy = GetEleType(Ty);
    if (ValueTy->isVectorTy()) {
      ConvertVectorIntoScalar(EleTy, Builder, Values);
    } else {
      ConvertScalarIntoScalar(EleTy, Builder, Values);
    }
    if (auto DstArrTy = dyn_cast<ArrayType>(Ty)) {
      InsertInArray(Builder, DstArrTy, Values);
    }
  }
}

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
  if (mul == 1){
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

  // Consider only the index for the size that has been loaded (the rest has
  // already been consider during the load).
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

// Reduce SrcTy to do as less load/store operation as possible while not loading
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
    Value *SrcAddr = Builder.CreateGEP(
        GetEleType(Src->getType())->getNonOpaquePointerElementType(), Src,
        AddrIdxs);
    LoadInst *SrcVal = Builder.CreateLoad(
        SrcAddr->getType()->getNonOpaquePointerElementType(), SrcAddr);
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

  // Because the vec3 to vec4 pass is before this one, we should not have a vec3
  // src. But it seems that some llvm passes after vec3 to vec4 can produce new
  // vec3. At the moment the only case known is to produce vec3 that will be
  // bitcast to another vec3 which element has the same time as the src vec3. In
  // that particular case, just keep the vec3 as we only need to bitcast them,
  // which will be handled correctly by this pass.
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

    Value *DstAddr = Builder.CreateGEP(
        GetEleType(Src->getType())->getNonOpaquePointerElementType(), Src,
        AddrIdxs);

    Builder.CreateStore(STValues[i], DstAddr);
  }
}

} // namespace

PreservedAnalyses
clspv::ReplacePointerBitcastPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  const DataLayout &DL = M.getDataLayout();

  WeakInstructions ToBeDeleted;
  SmallVector<Instruction *, 16> WorkList;
  SmallVector<User *, 16> UserWorkList;
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
    Value *Src = Inst->getOperand(0);
    Type *SrcTy = Src->getType()->getNonOpaquePointerElementType();
    Type *DstTy = Inst->getType()->getNonOpaquePointerElementType();

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
    for (User *BitCastUser : Inst->users()) {
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
