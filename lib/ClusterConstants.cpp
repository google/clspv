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

// Cluster module-scope __constant variables.  But only if option
// ModuleScopeConstantsInUniformBuffer is true.

#include <cassert>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/PushConstant.h"

#include "ArgKind.h"
#include "ClusterConstants.h"
#include "Constants.h"
#include "NormalizeGlobalVariable.h"
#include "PushConstant.h"

using namespace llvm;

#define DEBUG_TYPE "clusterconstants"

PreservedAnalyses
clspv::ClusterModuleScopeConstantVars::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  LLVMContext &Context = M.getContext();
  const DataLayout &DL = M.getDataLayout();

  clspv::NormalizeGlobalVariables(M);

  SmallVector<GlobalVariable *, 8> global_constants;
  UniqueVector<Constant *> initializers;
  SmallVector<GlobalVariable *, 8> dead_global_constants;
  std::map<Constant *, uint64_t> initializers_alignment;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.hasInitializer() && GV.getType()->getPointerAddressSpace() ==
                                   clspv::AddressSpace::Constant) {
      // Only keep live __constant variables.
      if (GV.use_empty()) {
        dead_global_constants.push_back(&GV);
      } else {
        global_constants.push_back(&GV);
        initializers.insert(GV.getInitializer());
        initializers_alignment[GV.getInitializer()] = GV.getAlignment();
      }
    }
  }

  for (GlobalVariable *GV : dead_global_constants) {
    GV->eraseFromParent();
  }

  if (global_constants.size() > 1 ||
      (global_constants.size() == 1 &&
       !global_constants[0]->getType()->isStructTy())) {
    // Make the struct type.
    SmallVector<Type *, 8> types;

    // Make the global variable.
    SmallVector<Constant *, 8> initializers_as_vec;

    uint64_t max_alignment = 0;

    // Make sure that every element is at the proper offset regarding its
    // alignment (which might not be the one of its type due to the lowering of
    // long vectors).
    {
      UniqueVector<Constant *> new_initializers;
      for (Constant *init : initializers) {
        Type *ty = init->getType();
        types.push_back(ty);
        auto align = initializers_alignment[init];
        max_alignment = std::max(max_alignment, align);
        auto offset = DL.getStructLayout(StructType::get(Context, types))
                          ->getElementOffset(types.size() - 1);
        auto padding = align != 0 ? (align - (offset % align)) % align : 0;
        if (padding) {
          types.pop_back();
          Type *pad_elem_ty;
          if (padding % sizeof(uint32_t) == 0) {
            pad_elem_ty = ty->getInt32Ty(Context);
          } else if (padding % sizeof(uint16_t) == 0) {
            pad_elem_ty = ty->getInt16Ty(Context);
          } else {
            pad_elem_ty = ty->getInt8Ty(Context);
          }
          padding /= (pad_elem_ty->getScalarSizeInBits() / 8);
          ArrayType *pad_ty = ArrayType::get(pad_elem_ty, padding);
          SmallVector<Constant *, 4> data;
          for (unsigned i = 0; i < padding; i++) {
            data.push_back(ConstantInt::get(pad_elem_ty, 0));
          }
          types.push_back(pad_ty);
          types.push_back(ty);
          initializers_as_vec.push_back(ConstantArray::get(pad_ty, data));
          new_initializers.insert(nullptr);
        }
        initializers_as_vec.push_back(init);
        new_initializers.insert(init);
      }
      initializers = std::move(new_initializers);
    }

    StructType *type = StructType::get(Context, types);
    PointerType *ptr_type =
        PointerType::get(type, clspv::AddressSpace::Constant);

    Constant *clustered_initializer =
        ConstantStruct::get(type, initializers_as_vec);
    GlobalVariable *clustered_gv = new GlobalVariable(
        M, type, true, GlobalValue::InternalLinkage, clustered_initializer,
        clspv::ClusteredConstantsVariableName(), nullptr,
        GlobalValue::ThreadLocalMode::NotThreadLocal,
        clspv::AddressSpace::Constant);
    assert(clustered_gv);
    clustered_gv->setAlignment(MaybeAlign(max_alignment));

    // Replace uses of the other globals with references to the members of the
    // clustered constant.
    IRBuilder<> Builder(Context);
    Value *zero = Builder.getInt32(0);
    for (GlobalVariable *GV : global_constants) {
      SmallVector<User *, 8> users(GV->users());
      for (User *user : users) {
        if (GV == user) {
          // This is the original global variable declaration.  Skip it.
        } else if (auto *inst = dyn_cast<Instruction>(user)) {
          unsigned index = initializers.idFor(GV->getInitializer()) - 1;

          auto getTypeAndPtr = [&clustered_gv, &M, &Builder, &type, &ptr_type,
                                &zero](Type *&PointeeType, Value *&Ptr,
                                       Instruction *InsertBefore) {
            if (clspv::Option::PhysicalStorageBuffers()) {
              auto *bb = InsertBefore->getParent();
              auto *clustered_ptr_ty = clspv::GetPushConstantType(
                  M, clspv::PushConstant::ModuleConstantsPointer);
              auto *ptr_to_ptr = clspv::GetPushConstantPointer(
                  bb, clspv::PushConstant::ModuleConstantsPointer);
              Value *indices[] = {zero};
              auto *ptr_gep = Builder.CreateInBoundsGEP(clustered_ptr_ty,
                                                        ptr_to_ptr, indices);
              auto *clustered_ptr_val =
                  new LoadInst(clustered_ptr_ty, ptr_gep, "", InsertBefore);
              auto *clustered_ptr = CastInst::Create(
                  Instruction::CastOps::IntToPtr, clustered_ptr_val, ptr_type,
                  "", InsertBefore);
              PointeeType = type;
              Ptr = clustered_ptr;
            } else {
              PointeeType = clustered_gv->getValueType();
              Ptr = clustered_gv;
            }
          };

          if (auto phi = dyn_cast<PHINode>(inst)) {
            for (unsigned i = 0; i < phi->getNumIncomingValues(); i++) {
              if (phi->getIncomingValue(i) != GV) {
                continue;
              }
              auto InsertBefore = phi->getIncomingBlock(i)->getFirstNonPHI();
              Type *PointeeType;
              Value *Ptr;
              getTypeAndPtr(PointeeType, Ptr, InsertBefore);
              Instruction *gep = GetElementPtrInst::CreateInBounds(
                  PointeeType, Ptr, {zero, Builder.getInt32(index)}, "",
                  InsertBefore);
              phi->setIncomingValue(i, gep);
            }
          } else {
            Type *PointeeType;
            Value *Ptr;
            getTypeAndPtr(PointeeType, Ptr, inst);
            Instruction *gep = GetElementPtrInst::CreateInBounds(
                PointeeType, Ptr, {zero, Builder.getInt32(index)}, "", inst);
            user->replaceUsesOfWith(GV, gep);
          }
        } else {
          errs() << "Don't know how to handle updating user of __constant: "
                 << *user << "\n";
          llvm_unreachable("Unhandled case replacing a user of __constant");
        }
      }
    }

    // Remove the old constants.
    for (GlobalVariable *GV : global_constants) {
      GV->eraseFromParent();
    }
  }

  return PA;
}
