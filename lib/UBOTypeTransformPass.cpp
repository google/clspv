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

// This pass performs type mutation to create types that satisfy the standard
// Uniform buffer layout rules of Vulkan section 14.5.4.
//
// Assumes the following passes have run:
// UndoGetElementPtrConstantExprPass

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "ArgKind.h"
#include "Constants.h"
#include "UBOTypeTransformPass.h"

using namespace llvm;

PreservedAnalyses clspv::UBOTypeTransformPass::run(Module &M,
                                                   ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  // Record whether char arrays are supported.
  support_int8_array_ = clspv::Option::Int8Support() &&
                        clspv::Option::Std430UniformBufferLayout();

  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    auto pod_arg_impl = clspv::GetPodArgsImpl(F);
    for (auto &Arg : F.args()) {
      if ((clspv::Option::ConstantArgsInUniformBuffer() &&
           clspv::GetArgKind(Arg) == clspv::ArgKind::BufferUBO) ||
          (!Arg.getType()->isPointerTy() &&
           pod_arg_impl == clspv::PodArgImpl::kUBO)) {
        // Pre-populate the type mapping for types that must change. This
        // necessary to prevent caching what would appear to be a no-op too
        // early.
        MapType(Arg.getType(), M, /* rewrite = */ true);
      }
    }
  }

  if (!remapped_types_.empty()) {
    RemapTypes(M);
  }

  return PA;
}

Type *clspv::UBOTypeTransformPass::MapType(Type *type, Module &M,
                                           bool rewrite) {
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
    Type *pointee =
        MapType(pointer->getNonOpaquePointerElementType(), M, rewrite);
    remapped = PointerType::get(pointee, pointer->getAddressSpace());
    break;
  }
  case Type::StructTyID:
    remapped = MapStructType(cast<StructType>(type), M, rewrite);
    break;
  case Type::ArrayTyID: {
    ArrayType *array = cast<ArrayType>(type);
    Type *element = MapType(array->getElementType(), M, rewrite);
    remapped = ArrayType::get(element, array->getNumElements());
    break;
  }
  case Type::FunctionTyID: {
    FunctionType *function = cast<FunctionType>(type);
    SmallVector<Type *, 8> arg_types;
    for (auto *param : function->params()) {
      arg_types.push_back(MapType(param, M, rewrite));
    }
    remapped = FunctionType::get(MapType(function->getReturnType(), M, rewrite),
                                 arg_types, function->isVarArg());
    break;
  }
  default:
    break;
  }

  deferred_types_.erase(type);

  auto result = remapped_types_.insert(std::make_pair(type, remapped));
  if (remapped != type && result.second && !remapped->isFunctionTy()) {
    // Record the type sizes from data layout to generate correct SPIRV-V
    // information later.
    const auto &DL = M.getDataLayout();
    NamedMDNode *type_sizes_md =
        M.getOrInsertNamedMetadata(clspv::RemappedTypeSizesMetadataName());
    auto *i64 = Type::getInt32Ty(M.getContext());
    Metadata *size_values[3];
    size_values[0] = ConstantAsMetadata::get(
        ConstantInt::get(i64, DL.getTypeSizeInBits(type)));
    size_values[1] = ConstantAsMetadata::get(
        ConstantInt::get(i64, DL.getTypeStoreSize(type)));
    size_values[2] = ConstantAsMetadata::get(
        ConstantInt::get(i64, DL.getTypeAllocSize(type)));
    MDTuple *values_md = MDTuple::get(M.getContext(), size_values);
    MDTuple *entry = MDTuple::get(
        M.getContext(),
        {ConstantAsMetadata::get(Constant::getNullValue(remapped)), values_md});
    type_sizes_md->addOperand(entry);
  }

  return remapped;
}

StructType *clspv::UBOTypeTransformPass::MapStructType(StructType *struct_ty,
                                                       Module &M,
                                                       bool rewrite) {
  // We'll never have to remap an opaque struct.
  if (struct_ty->isOpaque())
    return struct_ty;

  bool changed = false;
  SmallVector<Type *, 8> elements;
  SmallVector<uint64_t, 8> offsets;
  const auto *layout = M.getDataLayout().getStructLayout(struct_ty);
  for (unsigned i = 0; i != struct_ty->getNumElements(); ++i) {
    Type *element = struct_ty->getElementType(i);
    uint64_t offset = layout->getElementOffset(i);
    const auto *array = dyn_cast<ArrayType>(element);
    // Do not modify the element unless |rewrite| is true.
    if (rewrite && array && array->getElementType()->isIntegerTy(8) &&
        !support_int8_array_) {
      // Unless char arrays in UBOs are supported, replace all instances with an
      // i32.
      // This is a padding element. If chars are supported, replace the array
      // with a single char, otherwise use an int replacement.
      if (clspv::Option::Int8Support()) {
        elements.push_back(Type::getInt8Ty(M.getContext()));
      } else {
        assert((array->getNumElements() % 4 == 0) &&
               "Non-integer sized padding!");
        elements.push_back(Type::getInt32Ty(M.getContext()));
      }
    } else {
      elements.push_back(MapType(element, M, rewrite));
    }
    offsets.push_back(offset);
    changed |= (element != elements.back());
  }

  if (changed) {
    StructType *replacement =
        StructType::create(elements, "", struct_ty->isPacked());

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

bool clspv::UBOTypeTransformPass::RemapTypes(Module &M) {
  bool changed = false;

  // Functions with transformed types require rebuilding.
  SmallVector<Function *, 16> functions_to_modify;
  changed |= RemapFunctions(&functions_to_modify, M);

  // Global variables with transformed types require rebuilding.
  SmallVector<GlobalVariable *, 16> variables_to_modify;
  changed |= RemapGlobalVariables(&variables_to_modify, M);

  // Perform the type mutation within each function as necessary.
  for (auto &F : M) {
    for (auto &Arg : F.args()) {
      changed |= RemapValue(&Arg, M);
    }

    for (auto &BB : F) {
      for (auto &I : BB) {
        changed |= RemapUser(&I, M);
        if (auto *call = dyn_cast<CallInst>(&I)) {
          // Update the called function if we rewrote it.
          auto iter = function_replacements_.find(call->getCalledFunction());
          if (iter != function_replacements_.end()) {
            call->setCalledFunction(iter->second->getFunctionType(),
                                    iter->second);
          }
        } else if (auto *gep = dyn_cast<GetElementPtrInst>(&I)) {
          // Fix the extra type in the GEP
          Type *source_ty = gep->getSourceElementType();
          Type *remapped = RebuildType(source_ty, M);
          if (remapped != source_ty) {
            gep->setSourceElementType(remapped);
          }
        }
      }
    }
  }

  FixupFunctions(functions_to_modify, M);
  FixupGlobalVariables(variables_to_modify);

  return changed;
}

bool clspv::UBOTypeTransformPass::RemapFunctions(
    SmallVectorImpl<Function *> *functions_to_modify, Module &M) {
  bool changed = false;
  for (auto &F : M) {
    auto *remapped = RebuildType(F.getFunctionType(), M);
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
        cast<FunctionType>(RebuildType(func->getFunctionType(), M));

    // Insert the replacement function. Copy the calling convention, attributes
    // and metadata of the source function.
    auto inserted = M.getOrInsertFunction(func->getName(), replacement_type,
                                          func->getAttributes());
    Function *replacement = cast<Function>(inserted.getCallee());
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

bool clspv::UBOTypeTransformPass::RemapGlobalVariables(
    SmallVectorImpl<GlobalVariable *> *variables_to_modify, Module &M) {
  bool changed = false;
  for (auto &GV : M.globals()) {
    auto *remapped = RebuildType(GV.getValueType(), M);
    if (remapped != GV.getValueType()) {
      changed = true;
      variables_to_modify->push_back(&GV);
    }
  }
  for (auto *GV : *variables_to_modify) {
    GV->removeFromParent();
    auto *replacement_type = RebuildType(GV->getValueType(), M);

    Constant *initializer = nullptr;
    if (auto old_init = GV->getInitializer()) {
      initializer = RebuildConstant(old_init, replacement_type, M);
    }
    // Recreate the global variable.
    GlobalVariable *replacement = new GlobalVariable(
        M, replacement_type, GV->isConstant(), GV->getLinkage(), initializer,
        GV->getName(), /*InsertBefore=*/nullptr, GV->getThreadLocalMode(),
        GV->getType()->getPointerAddressSpace());
    remapped_globals_[GV] = replacement;
    replacement->copyMetadata(GV, 0);
  }

  return changed;
}

bool clspv::UBOTypeTransformPass::RemapUser(User *user, Module &M) {
  if (isa<ConstantData>(user) || isa<ConstantAggregate>(user)) {
    return RemapConstant(cast<Constant>(user), M);
  }

  bool changed = RemapValue(user, M);

  for (Use &use : user->operands()) {
    User *operand_user = dyn_cast<User>(use.get());
    if (!operand_user) {
      changed |= RemapValue(use.get(), M);
    } else if (!isa<Instruction>(operand_user) &&
               !isa<GlobalValue>(operand_user) &&
               !isa<Argument>(operand_user)) {
      // Keep mutating to handle constant expressions.
      changed |= RemapUser(operand_user, M);
      // If this was a constant that got rebuilt, update the operand.
      if (auto *constant = dyn_cast<Constant>(operand_user)) {
        auto iter = remapped_globals_.find(constant);
        if (iter != remapped_globals_.end()) {
          use.set(iter->second);
          changed = true;
        }
      }
    }
  }

  return changed;
}

bool clspv::UBOTypeTransformPass::RemapValue(Value *value, Module &M) {
  Type *remapped = RebuildType(value->getType(), M);
  if (remapped == value->getType())
    return false;

  if (auto *gep = dyn_cast<GetElementPtrInst>(value)) {
    auto *remapped_ele_ty = RebuildType(gep->getResultElementType(), M);
    if (remapped_ele_ty != gep->getResultElementType()) {
      gep->setResultElementType(remapped->getNonOpaquePointerElementType());
    }
  }

  value->mutateType(remapped);
  return true;
}

bool clspv::UBOTypeTransformPass::RemapConstant(Constant *constant, Module &M) {
  // Rebuild the constant.
  Type *remapped = RebuildType(constant->getType(), M);
  if (remapped == constant->getType())
    return false;

  RebuildConstant(constant, remapped, M);
  return true;
}

Constant *clspv::UBOTypeTransformPass::RebuildConstant(Constant *constant,
                                                       Type *remapped_ty,
                                                       Module &M) {
  if (constant->getType() == remapped_ty)
    return constant;

  // Check whether this constant has been rebuilt already.
  auto iter = remapped_globals_.find(constant);
  if (iter != remapped_globals_.end())
    return iter->second;

  if (constant->isZeroValue()) {
    Constant *null_constant = Constant::getNullValue(remapped_ty);
    remapped_globals_[constant] = null_constant;
    return null_constant;
  } else if (isa<UndefValue>(constant)) {
    // This case should catch the padding transformations since the padding
    // can't be initialized.
    Constant *undef_constant = UndefValue::get(remapped_ty);
    remapped_globals_[constant] = undef_constant;
    return undef_constant;
  } else if (auto *agg_constant = dyn_cast<ConstantAggregate>(constant)) {
    auto *struct_ty = dyn_cast<StructType>(constant->getType());
    auto *arr_ty = dyn_cast<ArrayType>(constant->getType());
    auto *vec_ty = dyn_cast<VectorType>(constant->getType());
    // CompositeType doesn't implement getNumElements().
    unsigned num_elements = 0;
    if (struct_ty)
      num_elements = struct_ty->getNumElements();
    else if (arr_ty)
      num_elements = arr_ty->getNumElements();
    else if (vec_ty)
      num_elements = vec_ty->getElementCount().getKnownMinValue();
    SmallVector<Constant *, 8> rebuilt_constants;
    for (unsigned i = 0; i != num_elements; ++i) {
      Constant *element_constant = agg_constant->getAggregateElement(i);
      Type *remapped_ele_ty = nullptr;
      if (struct_ty) {
        remapped_ele_ty = cast<StructType>(remapped_ty)->getTypeAtIndex(i);
      } else if (arr_ty) {
        remapped_ele_ty = remapped_ty->getArrayElementType();
      } else if (vec_ty) {
        remapped_ele_ty = cast<VectorType>(remapped_ty)->getElementType();
      }
      if (remapped_ele_ty != element_constant->getType()) {
        rebuilt_constants.push_back(
            RebuildConstant(element_constant, remapped_ele_ty, M));
      } else {
        rebuilt_constants.push_back(element_constant);
      }
    }

    Constant *rebuilt = nullptr;
    if (auto remapped_struct_ty = dyn_cast<StructType>(remapped_ty)) {
      rebuilt = ConstantStruct::get(remapped_struct_ty, rebuilt_constants);
    } else if (auto remapped_array_ty = dyn_cast<ArrayType>(remapped_ty)) {
      rebuilt = ConstantArray::get(remapped_array_ty, rebuilt_constants);
    } else {
      rebuilt = ConstantVector::get(rebuilt_constants);
    }
    return rebuilt;
  } else {
    llvm_unreachable("rewriting scalar constant?");
  }

  return constant;
}

void clspv::UBOTypeTransformPass::FixupFunctions(
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

void clspv::UBOTypeTransformPass::FixupGlobalVariables(
    const ArrayRef<GlobalVariable *> &variables_to_modify) {
  for (auto *var : variables_to_modify) {
    // Mutate type to satisfy RAUW requirements.
    auto *remapped_var = remapped_globals_[var];
    var->mutateType(remapped_var->getType());
    var->replaceAllUsesWith(remapped_var);
    delete var;
  }
}
