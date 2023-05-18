// Copyright 2019 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "Constants.h"

#include "NormalizeGlobalVariable.h"

using namespace llvm;

namespace {

// Returns the sole non-array, non-struct type contained in |type|. Returns
// nullptr if there is no such type.
Type *SoleContainedType(Type *type) {
  if (auto *array_ty = dyn_cast<ArrayType>(type)) {
    return SoleContainedType(array_ty->getArrayElementType());
  } else if (auto *struct_ty = dyn_cast<StructType>(type)) {
    Type *unique_ty = nullptr;
    for (auto ele_ty : struct_ty->elements()) {
      if (unique_ty == nullptr) {
        unique_ty = SoleContainedType(ele_ty);
        if (!unique_ty)
          return nullptr;
      } else if (unique_ty != SoleContainedType(ele_ty)) {
        return nullptr;
      }
    }
    return unique_ty;
  }

  return type;
}

// Returns the number of subtypes in |type|.
uint64_t GetNumElements(Type *type) {
  if (type->isStructTy()) {
    return type->getStructNumElements();
  } else if (type->isArrayTy()) {
    return type->getArrayNumElements();
  } else {
    return 0;
  }
}

// Flattens |constant| into |flattened|. |flattened| is populated with all
// arrays and structs broken down into constituent constants.
void FlattenConstant(Constant *constant, std::vector<Constant *> *flattened) {
  uint64_t num_elements = GetNumElements(constant->getType());
  for (uint64_t i = 0; i != num_elements; ++i) {
    auto *const_element = constant->getAggregateElement(i);
    auto *element_ty = const_element->getType();
    // Special cases for constant aggregate zero and constant data sequential
    // to populate the right number of constant elements into |flattened|.
    if (auto caz = dyn_cast<ConstantAggregateZero>(const_element)) {
      for (size_t i = 0; i != GetNumElements(element_ty); ++i) {
        if (element_ty->isStructTy()) {
          flattened->push_back(caz->getStructElement(i));
        } else {
          flattened->push_back(caz->getSequentialElement());
        }
      }
    } else if (auto cds = dyn_cast<ConstantDataSequential>(const_element)) {
      for (uint64_t i = 0; i != GetNumElements(element_ty); ++i) {
        auto *element = cds->getElementAsConstant(i);
        flattened->push_back(element);
      }
    } else if (element_ty->isArrayTy() || element_ty->isStructTy()) {
      FlattenConstant(const_element, flattened);
    } else {
      flattened->push_back(const_element);
    }
  }
}

// Returns a constant for |new_type| out |elements|. |ele_index| is used to
// index correctly into the full array of elements.
Constant *BuildConstant(Type *new_type, const std::vector<Constant *> elements,
                        uint64_t *ele_index) {
  auto GetSubType = [](Type *type, uint64_t element) {
    if (type->isStructTy()) {
      return type->getContainedType(element);
    } else if (type->isArrayTy()) {
      return type->getArrayElementType();
    }
    return type;
  };

  std::vector<Constant *> constants;
  uint64_t num_eles = GetNumElements(new_type);
  for (uint64_t i = 0; i != num_eles; ++i) {
    auto *subtype = GetSubType(new_type, i);
    if (subtype->isArrayTy() || subtype->isStructTy()) {
      constants.push_back(BuildConstant(subtype, elements, ele_index));
    } else {
      constants.push_back(elements[*ele_index]);
      ++(*ele_index);
    }
  }

  // Generate the new constant.
  if (auto struct_ty = dyn_cast<StructType>(new_type)) {
    return ConstantStruct::get(struct_ty, constants);
  } else {
    return ConstantArray::get(cast<ArrayType>(new_type), constants);
  }
}

// Returns |init| represented as |new_type|.
Constant *TranslateConstant(Constant *init, Type *new_type) {
  assert(init->getType()->isStructTy() || init->getType()->isArrayTy());

  std::vector<Constant *> flattened;
  FlattenConstant(init, &flattened);
  uint64_t ele_index = 0;
  auto *new_constant = BuildConstant(new_type, flattened, &ele_index);
  return new_constant;
}

// Returns true if |GV| can be normalized to |to_type|. |gv_contained_ty| is
// the sole contained type in |GV|.
bool VariableNeedsNormalized(GlobalVariable *GV, Type *gv_contained_ty,
                             Type *to_type) {
  auto gv_pointee = GV->getValueType();
  if (gv_pointee == to_type)
    return false;

  if (!gv_pointee->isStructTy() && !gv_pointee->isArrayTy())
    return false;

  if (!to_type->isStructTy() && !to_type->isArrayTy())
    return false;

  const auto &DL = GV->getParent()->getDataLayout();
  if (DL.getTypeStoreSize(gv_pointee) != DL.getTypeStoreSize(to_type))
    return false;

  auto *ce_contained_ty = SoleContainedType(to_type);
  if (gv_contained_ty == ce_contained_ty)
    return true;

  return false;
}

// Normalize the user |user| of |GV|. Generates a global variable with
// appropriate initializer and replaces uses of |user| with the new variable.
GlobalVariable *NormalizeVariable(GlobalVariable *GV, User *user, Type *to_type) {
  Constant *new_initializer = nullptr;
  if (GV->hasInitializer()) {
    auto *initializer = GV->getInitializer();
    new_initializer = TranslateConstant(initializer, to_type);
  }

  GlobalVariable *new_gv = new GlobalVariable(
      *GV->getParent(), to_type, GV->isConstant(), GV->getLinkage(),
      new_initializer, "", nullptr, GV->getThreadLocalMode(),
      GV->getType()->getPointerAddressSpace(), GV->isExternallyInitialized());
  new_gv->takeName(GV);
  user->replaceUsesOfWith(GV, new_gv);

  return new_gv;
}

// Normalize the users of |GV|.
void NormalizeVariableUsers(GlobalVariable *GV) {
  for (auto *user : GV->users()) {
    auto *gep = dyn_cast<GEPOperator>(user);
    if (!gep)
      continue;

    Type *gv_contained_ty = SoleContainedType(GV->getValueType());
    if (!gv_contained_ty)
      continue;

    Type *to_type = gep->getSourceElementType();
    if (!VariableNeedsNormalized(GV, gv_contained_ty, to_type))
      continue;

    if (to_type)
      NormalizeVariable(GV, user, to_type);
  }

  GV->removeDeadConstantUsers();
  if (GV->use_empty() &&
      GV->getName() != clspv::ClusteredConstantsVariableName()) {
    GV->eraseFromParent();
  }
}

} // namespace

namespace clspv {

void NormalizeGlobalVariables(Module &M) {
  SmallVector<GlobalVariable *, 8> globals;
  for (auto &GV : M.globals()) {
    if (GV.hasInitializer() && GV.getType()->getPointerAddressSpace() ==
                                   clspv::AddressSpace::Constant) {
      globals.push_back(&GV);
    }
  }

  for (auto *GV : globals) {
    NormalizeVariableUsers(GV);
  }
}
} // namespace clspv
