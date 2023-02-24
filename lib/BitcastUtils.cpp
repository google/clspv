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

#include <llvm/Support/Debug.h>
#include "BitcastUtils.h"

#define DEBUG_TYPE "bitcastutils"

#define DEBUG_FCT_TY_VALUES(Ty, Values)                                 \
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

namespace BitcastUtils {

// Returns the size in bits of 'Ty'
size_t SizeInBits(const DataLayout &DL, Type *Ty) {
  return DL.getTypeAllocSizeInBits(Ty);
}

// Same as above with different arguments
size_t SizeInBits(IRBuilder<> &builder, Type *Ty) {
  return SizeInBits(
      builder.GetInsertBlock()->getParent()->getParent()->getDataLayout(), Ty);
}

// Returns the element type when 'Ty' is a vector, an array, or a packed struct
// with only one type, otherwise returns 'Ty'.
Type *GetEleType(Type *Ty) {
  if (auto VecTy = dyn_cast<VectorType>(Ty)) {
    return VecTy->getElementType();
  } else if (auto ArrTy = dyn_cast<ArrayType>(Ty)) {
    return ArrTy->getElementType();
  } else if (auto StructTy = dyn_cast<StructType>(Ty)) {
    if (!StructTy->isOpaque() && StructTy->isPacked() &&
        StructTy->getNumElements() == 1) {
      return StructTy->getContainedType(0);
    }
    return Ty;
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
      auto *prev = dst ? dst : PoisonValue::get(dst_type);
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
      auto *prev = dst ? dst : PoisonValue::get(dst_type);
      dst = builder.CreateInsertValue(prev, tmp_value, {i});
    }
  } else if (auto *dst_vec_ty = dyn_cast<VectorType>(dst_type)) {
    auto *ele_ty = dst_vec_ty->getElementType();
    for (uint64_t i = 0; i != dst_vec_ty->getElementCount().getKnownMinValue();
         ++i) {
      auto *tmp_value =
          BuildFromElements(ele_ty, src_elements, used_bits, index, builder);
      auto *prev = dst ? dst : PoisonValue::get(dst_type);
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

// 'Values' is expected to contain elements that will compose arrays of type
// 'Ty'.
// 'Values' is also the output of this function, containing arrays of type 'Ty'.
void InsertInArray(IRBuilder<> &Builder, ArrayType *Ty,
                   SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_TY_VALUES(Ty, Values);
  unsigned ArrayNumEles = Ty->getNumElements();
  assert(Ty->getElementType() == Values[0]->getType());
  assert(Values.size() % ArrayNumEles == 0);
  unsigned NumArrays = Values.size() / ArrayNumEles;
  for (unsigned i = 0; i < NumArrays; i++) {
    Value *Ret = PoisonValue::get(Ty);
    for (unsigned j = 0; j < ArrayNumEles; j++) {
      Ret = Builder.CreateInsertValue(Ret, Values[i * ArrayNumEles + j], {j});
    }
    Values[i] = Ret;
  }
  Values.resize(NumArrays);
}

// 'Values' is expected to contain vectors.
// 'Values is also the output of this function, containing all the elements of
// the input vectors.
void ExtractFromVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  SmallVector<Value *, 8> ScalarValues;
  Type *ValueTy = Values[0]->getType();
  assert(ValueTy->isVectorTy());
  for (unsigned i = 0; i < Values.size(); i++) {
    for (unsigned j = 0; j < GetNumEle(ValueTy); j++) {
      ScalarValues.push_back(Builder.CreateExtractElement(Values[i], j));
    }
  }
  Values.clear();
  Values = std::move(ScalarValues);
}

// 'Values' is expected to contain arrays.
// 'Values is also the output of this function, containing all the elements of
// the input arrays.
void ExtractFromArray(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values,
                      bool isPackedStructSrc, unsigned DstTySize) {
  DEBUG_FCT_VALUES(Values);
  SmallVector<Value *, 8> ScalarValues;
  Type *ValueTy = Values[0]->getType();
  unsigned CharSize = 8;
  unsigned NumElements =
      isPackedStructSrc ? DstTySize / CharSize : GetNumEle(ValueTy);
  assert(NumElements != 0);
  assert(ValueTy->isArrayTy());
  for (unsigned i = 0; i < Values.size(); i++) {
    for (unsigned j = 0; j < NumElements; j++) {
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
// 'Values' is also the output of this function, containing all bitcasted
// values.
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
// 'Values' is also the output of this function, containing all bitcasted
// values.
void BitcastIntoVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values,
                       unsigned NumElePerVec, Type *Ty) {
  DEBUG_FCT_VALUES(Values);
  Type *SrcTy = Values[0]->getType();
  unsigned SrcSize = SizeInBits(Builder, SrcTy);
  assert(SrcSize % NumElePerVec == 0);
  unsigned SrcEleSize = SrcSize / NumElePerVec;
  VectorType *DstTy =
      FixedVectorType::get(getNTy(Builder, SrcEleSize, Ty), NumElePerVec);
  BitcastValues(Builder, DstTy, Values);
}

// 'Values' is expected to contain scalar values.
// Group those values in vector of size 'NumElePerVec'.
// Return the vectors into 'Values'.
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
    Value *Vec = PoisonValue::get(DstTy);
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
// Return the vectors into 'Values'.
void GroupVectorValuesInPair(IRBuilder<> &Builder,
                             SmallVector<Value *, 8> &Values) {
  DEBUG_FCT_VALUES(Values);
  assert(Values[0]->getType()->isVectorTy() &&
         GetNumEle(Values[0]->getType()) == 2);
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
// Return the splitted values into 'Values'.
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
// 'Values' is expected to contain vectors.
// Return the splitted values into 'Values'.
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
// 'Values' is expected to contain vectors.
// Return the splitted values into 'Values'.
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
// 'Values' is expected to contain vectors.
// Return the grouped values into 'Values'.
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
// 'Values' is expected to contain vectors.
// Return the grouped values into 'Values'.
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

// 'Values' is expected to contain vectors.
// Return the converted vectors of type 'Ty' into 'Values'.
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

// 'Values' is expected to contain vectors.
// Return the scalar values of type 'Ty' into 'Values'.
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
    // Bitcasting before the extraction reduces the number of bitcast
    BitcastIntoVector(Builder, Values, GetNumEle(Values[0]->getType()), Ty);
    ExtractFromVector(Builder, Values);
  } else if (ValueEleSize == TySize) {
    // Bitcasting before the extraction reduces the number of bitcast
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

// 'Values' is expected to contain scalar elements.
// Return the vectors values of type 'Ty' into 'Values'.
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
    // Bitcasting before splitting reduces the number of bitcast
    BitcastIntoVector(Builder, Values, NumElements, Ty);
    SplitVectorUntilSizeEquals(Ty, Builder, Values);
  }

  BitcastValues(Builder, Ty, Values);
}

// 'Values' is expected to contain scalar elements.
// Return the scalar values of type 'Ty' into 'Values'.
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

// Convert values contained in 'Values' into values of type 'Ty'.
// Input values are expected to be either vectors or scalars.
// 'Ty' is expected to be either a vector, an array, a struct or a scalar type.
// Return the converted values into 'Values'.
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
  } else if (auto StructTy = dyn_cast<StructType>(Ty)) {
    ConvertScalarIntoScalar(StructTy, Builder, Values);
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

bool RemoveCstExprFromFunction(Function *F) {
  SmallVector<std::pair<Instruction *, unsigned>, 16> WorkList;

  auto CheckInstruction = [&WorkList](Instruction *I) {
    for (unsigned OperandId = 0; OperandId < I->getNumOperands(); OperandId++) {
      if (auto CE = dyn_cast<ConstantExpr>(I->getOperand(OperandId))) {

        // TODO(#816): remove after final transition.
        // This case happen in some particular scenario, where it is not
        // needed to simplify it. Mostly when using global array
        // variables. In the end llvm managed to deal with it without us
        // having to simplify it. Trying to simplify would make it very
        // complicated for the ReplacePointerBitcast pass.
        if (CE->getOpcode() == Instruction::BitCast &&
            CE->getOperand(0)->getType()->isPointerTy() &&
            !CE->getOperand(0)->getType()->isOpaquePointerTy() &&
            CE->getOperand(0)
                ->getType()
                ->getNonOpaquePointerElementType()
                ->isStructTy())
          continue;

        WorkList.push_back(std::make_pair(I, OperandId));
      }
    }
  };

  for (BasicBlock &BB : *F) {
    for (Instruction &I : BB) {
      CheckInstruction(&I);
    }
  }

  bool Changed = !WorkList.empty();

  while (!WorkList.empty()) {
    auto *I = WorkList.back().first;
    auto OperandId = WorkList.back().second;
    WorkList.pop_back();

    auto Operand =
        dyn_cast<ConstantExpr>(I->getOperand(OperandId))->getAsInstruction(I);
    CheckInstruction(Operand);
    I->setOperand(OperandId, Operand);
  }

  return Changed;
}

} // namespace BitcastUtils
