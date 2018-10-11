// Copyright 2018 The Clspv Authors. All rights reserved.
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

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "ArgKind.h"
#include "Constants.h"
#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"

using namespace llvm;

namespace {

class UBOTypeTransformPass final : public ModulePass {
 public:
  static char ID;
  UBOTypeTransformPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;
 private:
  Type *MapType(Type* type, Module &M);
  StructType *MapStructType(StructType *struct_ty, Module &M);
  bool RemapTypes(Module &M);
  bool RemapUser(User *user, Module &M);
  bool RemapValue(Value *value, Module &M);

  DenseMap<Type*,Type*> remapped_types_;
  DenseSet<Type*> deferred_types_;
  DenseSet<Type*> processing_types_;
};

char UBOTypeTransformPass::ID = 0;
static RegisterPass<UBOTypeTransformPass>
  X("UBOTypeTransformPass", "Transform UBO types");

}

namespace clspv {
ModulePass *createUBOTypeTransformPass() {
  return new UBOTypeTransformPass();
}
} // namespace clspv

namespace {

bool UBOTypeTransformPass::runOnModule(Module &M) {
  //llvm::errs() << M << "\n";

  if (!clspv::Option::ConstantArgsInUniformBuffer())
    return false;

  bool changed = false;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    for (auto &Arg : F.args()) {
      if (clspv::GetArgKindForType(Arg.getType()) == clspv::ArgKind::BufferUBO) {
        // Pre-populate the type mapping for types that must change.
        Type *remapped = MapType(Arg.getType(), M);
        llvm::errs() << "Remapping " << *Arg.getType()->getPointerElementType() << " to:\n " << *remapped->getPointerElementType() << "\n";
      }
    }
  }

  if (!remapped_types_.empty()) {
    changed |= RemapTypes(M);
  }

  llvm::errs() << M << "\n";
  llvm_unreachable("intentional");
  return changed;
}

Type *UBOTypeTransformPass::MapType(Type *type, Module &M) {
  auto iter = remapped_types_.find(type);
  if (iter != remapped_types_.end()) {
    return iter->second;
  }

  // Fix circular references.
  if (!processing_types_.insert(type).second) {
    deferred_types_.insert(type);
    return type;
  }

  Type *remapped = type;
  switch (type->getTypeID()) {
    case Type::PointerTyID: {
      PointerType *pointer = cast<PointerType>(type);
      Type *pointee = MapType(pointer->getElementType(), M);
      remapped = PointerType::get(pointee, pointer->getAddressSpace());
      break;
    }
    case Type::StructTyID:
      remapped = MapStructType(cast<StructType>(type), M);
      break;
    case Type::ArrayTyID: {
      ArrayType *array = cast<ArrayType>(type);
      Type *element = MapType(array->getElementType(), M);
      remapped = ArrayType::get(element, array->getNumElements());
      break;
    }
    default:
      break;
  }

  deferred_types_.erase(type);

  return remapped_types_.insert(std::make_pair(type, remapped)).first->second;
}

StructType *UBOTypeTransformPass::MapStructType(StructType *struct_ty, Module &M) {
  bool changed = false;
  SmallVector<Type *, 8> elements;
  SmallVector<uint64_t, 8> offsets;
  const auto *layout = M.getDataLayout().getStructLayout(struct_ty);
  for (unsigned i = 0; i != struct_ty->getNumElements(); ++i) {
    Type *element = struct_ty->getElementType(i);
    uint64_t offset = layout->getElementOffset(i);
    const auto *array = dyn_cast<ArrayType>(element);
    if (array && array->getElementType()->isIntegerTy(8) && offset % 16 != 0) {
      // This is a padding element.
      elements.push_back(Type::getInt32Ty(M.getContext()));
      changed = true;
    } else {
      elements.push_back(MapType(element, M));
    }
    offsets.push_back(offset);
  }

  if (changed) {
    StructType *replacement = StructType::create(elements);

    // Record the correct offsets.
    NamedMDNode *offsets_md =
        M.getOrInsertNamedMetadata(clspv::RemappedTypeOffsetMetadataName());
    SmallVector<Metadata*, 8> offset_values;
    for (auto offset : offsets) {
      offset_values.push_back(ConstantAsMetadata::get(
          ConstantInt::get(Type::getInt32Ty(M.getContext()), offset)));
    }
    MDTuple *values_md = MDTuple::get(M.getContext(), offset_values);
    MDTuple *entry = MDTuple::get(
        M.getContext(),
        {ConstantAsMetadata::get(Constant::getNullValue(replacement)),
         values_md});
    offsets_md->addOperand(entry);

    return replacement;
  } else {
    return struct_ty;
  }
}

bool UBOTypeTransformPass::RemapTypes(Module &M) {
  bool changed = false;

  // Fix globals.
  // Functions are problematic. Need to recreate them.

  for (auto &F : M) {
    for (auto &Arg : F.args()) {
      changed |= RemapValue(&Arg, M);
    }

    for (auto &BB : F) {
      for (auto &I : BB) {
        changed |= RemapUser(&I, M);
      }
    }
  }

  return changed;
}

bool UBOTypeTransformPass::RemapUser(User *user, Module &M) {
  bool changed = RemapValue(user, M);

  for (Use &use : user->operands()) {
    User *operand_user = use.getUser();
    if (!operand_user)
      changed |= RemapValue(use.get(), M);
    else if (!isa<Instruction>(operand_user) &&
             !isa<GlobalValue>(operand_user) && !isa<Argument>(operand_user))
      changed |= RemapUser(operand_user, M);
  }

  return changed;
}

bool UBOTypeTransformPass::RemapValue(Value *value, Module &M) {
  Type *remapped = MapType(value->getType(), M);
  if (remapped == value->getType())
    return false;

  value->mutateType(remapped);
  return true;
}

}

