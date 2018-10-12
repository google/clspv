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
  // Returns the remapped version of |type| that satisfies UBO requirements.
  Type *MapType(Type *type, Module &M);

  // Returns the remapped version of |type| that satisfies UBO requirements.
  StructType *MapStructType(StructType *struct_ty, Module &M);

  // Performs type mutation on |M|. Returns true if |M| was modified.
  bool RemapTypes(Module &M);

  // Performs type mutation for functions that require it. Returns true if the
  // module is modified.
  //
  // If a function requires type mutation it will be replaced by a new
  // function. The function's basic blocks are moved into the new function and
  // all metadata is copied.
  bool RemapFunctions(SmallVectorImpl<Function *> *functions_to_modify,
                      Module &M);

  // Performs type mutation on |user|. Recursively fixes operands of |user|.
  // Returns true if the module is modified.
  bool RemapUser(User *user, Module &M);

  // Mutates the type of |value|. Returns true if the module is modified.
  bool RemapValue(Value *value, Module &M);

  // Performs final modifications on functions that were replaced. Fixes names
  // and use-def chains.
  void FixupFunctions(const ArrayRef<Function *> &functions_to_modify,
                      Module &M);

  // Maps a type to its UBO type.
  DenseMap<Type *, Type *> remapped_types_;

  // Prevents infinite recusion.
  DenseSet<Type *> deferred_types_;

  // Maps a function to it's replacement.
  DenseMap<Function *, Function *> function_replacements_;
};

char UBOTypeTransformPass::ID = 0;
static RegisterPass<UBOTypeTransformPass> X("UBOTypeTransformPass",
                                            "Transform UBO types");

} // namespace

namespace clspv {
ModulePass *createUBOTypeTransformPass() { return new UBOTypeTransformPass(); }
} // namespace clspv

namespace {

bool UBOTypeTransformPass::runOnModule(Module &M) {
  llvm::errs() << "BEFORE\n" << M << "\nBEFORE\n";

  if (!clspv::Option::ConstantArgsInUniformBuffer())
    return false;

  bool changed = false;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    for (auto &Arg : F.args()) {
      if (clspv::GetArgKindForType(Arg.getType()) ==
          clspv::ArgKind::BufferUBO) {
        // Pre-populate the type mapping for types that must change. This
        // necessary to prevent caching what would appear to be a no-op too
        // early.
        MapType(Arg.getType(), M);
      }
    }
  }

  if (!remapped_types_.empty()) {
    changed |= RemapTypes(M);
  }

  llvm::errs() << "\n\nAFTER\n" << M << "\nAFTER\n";
  return changed;
}

Type *UBOTypeTransformPass::MapType(Type *type, Module &M) {
  // Check the cache to see if we've fixed this type.
  auto iter = remapped_types_.find(type);
  if (iter != remapped_types_.end()) {
    return iter->second;
  }

  // Fix circular references.
  if (!deferred_types_.insert(type).second) {
    return type;
  }

  // Rebuild the types. Most types do not need handled here.
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
  case Type::FunctionTyID: {
    FunctionType *function = cast<FunctionType>(type);
    SmallVector<Type *, 8> arg_types;
    for (auto *param : function->params()) {
      arg_types.push_back(MapType(param, M));
    }
    remapped = FunctionType::get(MapType(function->getReturnType(), M),
                                 arg_types, function->isVarArg());
    break;
  }
  default:
    break;
  }

  deferred_types_.erase(type);

  return remapped_types_.insert(std::make_pair(type, remapped)).first->second;
}

StructType *UBOTypeTransformPass::MapStructType(StructType *struct_ty,
                                                Module &M) {
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
    } else {
      elements.push_back(MapType(element, M));
    }
    offsets.push_back(offset);
    changed |= (element != elements.back());
  }

  if (changed) {
    StructType *replacement = StructType::create(elements);

    // Record the correct offsets for use when generating the SPIR-V binary.
    NamedMDNode *offsets_md =
        M.getOrInsertNamedMetadata(clspv::RemappedTypeOffsetMetadataName());
    SmallVector<Metadata *, 8> offset_values;
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

  // TODO(alan-baker): Fix globals.
  // Functions are problematic. Need to recreate them.
  SmallVector<Function *, 16> functions_to_modify;
  changed |= RemapFunctions(&functions_to_modify, M);

  // Perform the type mutation within each function as necessary.
  for (auto &F : M) {
    for (auto &Arg : F.args()) {
      changed |= RemapValue(&Arg, M);
    }

    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *call = dyn_cast<CallInst>(&I)) {
          Function *replacement =
              function_replacements_[call->getCalledFunction()];
          call->setCalledFunction(replacement->getFunctionType(), replacement);
        }
        changed |= RemapUser(&I, M);
      }
    }
  }

  FixupFunctions(functions_to_modify, M);

  return changed;
}

bool UBOTypeTransformPass::RemapFunctions(
    SmallVectorImpl<Function *> *functions_to_modify, Module &M) {
  bool changed = false;
  for (auto &F : M) {
    auto *remapped = MapType(F.getFunctionType(), M);
    if (F.getType() != remapped) {
      changed = true;
      functions_to_modify->push_back(&F);
    }
  }

  for (auto func : *functions_to_modify) {
    // Remove the function from the module, but keep it around for the time
    // being.
    func->removeFromParent();
    auto *replacement_type =
        cast<FunctionType>(MapType(func->getFunctionType(), M));

    // Insert the replacement function. Copy the calling convention, attributes
    // and metadata of the source function.
    Constant *inserted = M.getOrInsertFunction(
        func->getName(), replacement_type, func->getAttributes());
    Function *replacement = cast<Function>(inserted);
    function_replacements_[func] = replacement;
    replacement->setCallingConv(func->getCallingConv());
    replacement->copyMetadata(func, 0);

    // Move the basic blocks into the replacement function.
    if (!func->isDeclaration()) {
      std::vector<BasicBlock *> blocks;
      for (auto &BB : *func) {
        blocks.push_back(&BB);
      }
      for (auto *BB : blocks) {
        BB->removeFromParent();
        BB->insertInto(replacement);
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
      // Keep mutating to handle constant expressions.
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

void UBOTypeTransformPass::FixupFunctions(
    const ArrayRef<Function *> &functions_to_modify, Module &M) {
  // If functions were replaced, we have some final fixup to do:
  // * Rename arguments to maintain descriptor mapping
  // * Replace argument and function uses with their replacements.
  //
  // Note: type mutations occur to satisfy RAUW requirements.
  for (auto *func : functions_to_modify) {
    Function *replacement = function_replacements_[func];
    for (auto arg_iter = func->arg_begin(),
              replace_iter = replacement->arg_begin();
         arg_iter != func->arg_end(); ++arg_iter, ++replace_iter) {
      replace_iter->takeName(&*arg_iter);
      arg_iter->mutateType(replace_iter->getType());
      arg_iter->replaceAllUsesWith(replace_iter);
    }
    func->mutateType(replacement->getType());
    func->replaceAllUsesWith(replacement);
    delete func;
  }
}
} // namespace
