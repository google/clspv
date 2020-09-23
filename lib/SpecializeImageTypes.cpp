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

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "Builtins.h"
#include "Constants.h"
#include "Passes.h"
#include "Types.h"
#include "clspv/Option.h"

using namespace clspv;
using namespace clspv::Builtins;
using namespace llvm;

namespace {

class SpecializeImageTypesPass : public ModulePass {
public:
  static char ID;
  SpecializeImageTypesPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Returns the specialized image type for |arg|.
  Type *RemapType(Argument *arg);

  // Returns the specialized image type for operand |operand_no| in |value|.
  Type *RemapUse(Value *value, unsigned operand_no);

  // Specializes |arg| as |new_type|. Recursively updates the use chain.
  void SpecializeArg(Function *f, Argument *arg, Type *new_type);

  // Returns a replacement image builtin function for the specialized type
  // |type|.
  Function *ReplaceImageBuiltin(Function *f, Type *type);

  // Rewrites |f| using the |remapped_args_| to determine to updated types.
  void RewriteFunction(Function *f);

  // Tracks the generation of specialized types so they are not further
  // specialized.
  DenseSet<Type *> specialized_images_;

  // Maps an argument to a specialized type.
  DenseMap<Argument *, Type *> remapped_args_;

  // Tracks which functions need rewritten due to modified arguments.
  DenseSet<Function *> functions_to_modify_;
};

} // namespace

char SpecializeImageTypesPass::ID = 0;
INITIALIZE_PASS(SpecializeImageTypesPass, "SpecializeImageTypesPass",
                "Specialize image types", false, false)

namespace clspv {
ModulePass *createSpecializeImageTypesPass() {
  return new SpecializeImageTypesPass();
}
} // namespace clspv

namespace {

bool SpecializeImageTypesPass::runOnModule(Module &M) {
  bool changed = false;
  SmallVector<Function *, 8> kernels;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;
    kernels.push_back(&F);
  }

  for (auto f : kernels) {
    for (auto &Arg : f->args()) {
      if (IsImageType(Arg.getType())) {
        Type *new_type = RemapType(&Arg);
        if (!new_type) {
          // No specializing information found, assume the image is sampled with
          // a float type.
          std::string name =
              cast<StructType>(Arg.getType()->getPointerElementType())
                  ->getName()
                  .str();
          name += ".float";
          if (name.find("ro_t") != std::string::npos)
            name += ".sampled";
          StructType *new_struct = M.getTypeByName(name);
          if (!new_struct)
            new_struct = StructType::create(Arg.getContext(), name);
          new_type = PointerType::get(new_struct,
                                      Arg.getType()->getPointerAddressSpace());
        }
        specialized_images_.insert(new_type);
        changed = true;
        SpecializeArg(f, &Arg, new_type);
      }
    }
  }

  // Keep functions in the same relative order.
  std::vector<Function *> to_rewrite;
  for (auto &F : M) {
    if (functions_to_modify_.count(&F))
      to_rewrite.push_back(&F);
  }
  for (auto f : to_rewrite) {
    RewriteFunction(f);
  }

  return changed;
}

Type *SpecializeImageTypesPass::RemapType(Argument *arg) {
  for (auto &U : arg->uses()) {
    if (auto new_type = RemapUse(U.getUser(), U.getOperandNo())) {
      return new_type;
    }
  }

  return nullptr;
}

Type *SpecializeImageTypesPass::RemapUse(Value *value, unsigned operand_no) {
  if (CallInst *call = dyn_cast<CallInst>(value)) {
    auto called = call->getCalledFunction();
    auto func_info = Builtins::Lookup(called);
    switch (func_info.getType()) {
    case Builtins::kReadImagef:
    case Builtins::kReadImagei:
    case Builtins::kReadImageui:
    case Builtins::kWriteImagef:
    case Builtins::kWriteImagei:
    case Builtins::kWriteImageui: {
      // Specialize the image type based on it's usage in the builtin.
      Value *image = call->getOperand(0);
      Type *imageTy = image->getType();

      // Check if this type is already specialized.
      if (specialized_images_.count(imageTy))
        return imageTy;

      std::string name =
          cast<StructType>(imageTy->getPointerElementType())->getName().str();
      switch (func_info.getType()) {
      case Builtins::kReadImagef:
      case Builtins::kWriteImagef:
        name += ".float";
        break;
      case Builtins::kReadImagei:
      case Builtins::kWriteImagei:
        name += ".int";
        break;
      case Builtins::kReadImageui:
      case Builtins::kWriteImageui:
        name += ".uint";
        break;
      default:
        break;
      }

      // Read only images are translated as sampled images.
      const auto pos = name.find("_wo_t");
      if (!IsStorageImageType(imageTy)) {
        name += ".sampled";
      } else if (clspv::Option::Language() >=
                     clspv::Option::SourceLanguage::OpenCL_C_20 &&
                 pos != std::string::npos) {
        // In OpenCL 2.0 (or later), treat write_only images as read_write
        // images. This prevents the compiler from generating duplicate image
        // types (invalid SPIR-V).
        name = name.substr(0, pos) + "_rw_t" + name.substr(pos + 5);
      }

      StructType *new_struct =
          call->getParent()->getParent()->getParent()->getTypeByName(name);
      if (!new_struct) {
        new_struct = StructType::create(call->getContext(), name);
      }
      PointerType *new_pointer =
          PointerType::get(new_struct, imageTy->getPointerAddressSpace());
      return new_pointer;
    }
    default:
      if (!called->isDeclaration()) {
        for (auto &U : called->getArg(operand_no)->uses()) {
          if (auto new_type = RemapUse(U.getUser(), U.getOperandNo())) {
            return new_type;
          }
        }
      }
      break;
    }
  } else if (IsImageType(value->getType())) {
    for (auto &U : value->uses()) {
      if (auto new_type = RemapUse(U.getUser(), U.getOperandNo())) {
        return new_type;
      }
    }
  }

  return nullptr;
}

void SpecializeImageTypesPass::SpecializeArg(Function *f, Argument *arg,
                                             Type *new_type) {
  auto where = remapped_args_.find(arg);
  if (where != remapped_args_.end())
    return;

  remapped_args_[arg] = new_type;
  functions_to_modify_.insert(f);

  // Fix all uses of |arg|.
  std::vector<Value *> stack;
  stack.push_back(arg);
  while (!stack.empty()) {
    Value *value = stack.back();
    stack.pop_back();

    if (value->getType() == new_type)
      continue;

    auto old_type = value->getType();
    value->mutateType(new_type);
    for (auto &u : value->uses()) {
      if (auto call = dyn_cast<CallInst>(u.getUser())) {
        auto called = call->getCalledFunction();
        auto &func_info = Builtins::Lookup(called);
        if (BUILTIN_IN_GROUP(func_info.getType(), Image)) {
          auto new_func = ReplaceImageBuiltin(called, new_type);
          call->setCalledFunction(new_func);
          if (called->getNumUses() == 0)
            called->eraseFromParent();
        } else {
          SpecializeArg(called, called->getArg(u.getOperandNo()), new_type);
          // Ensure the called function type matches the called function's type.
          call->setCalledFunction(call->getCalledFunction());
        }
      }

      if (old_type == u.getUser()->getType()) {
        stack.push_back(u.getUser());
      }
    }
  }
}

Function *SpecializeImageTypesPass::ReplaceImageBuiltin(Function *f,
                                                        Type *type) {
  std::string name = f->getName().str();
  name += ".";
  name += cast<StructType>(type->getPointerElementType())->getName();
  if (auto replaced = f->getParent()->getFunction(name))
    return replaced;

  // Change the image argument to the specialized type.
  SmallVector<Type *, 4> paramTys;
  for (auto &Arg : f->args()) {
    if (IsImageType(Arg.getType()))
      paramTys.push_back(type);
    else
      paramTys.push_back(Arg.getType());
  }

  auto func_type =
      FunctionType::get(f->getReturnType(), paramTys, f->isVarArg());
  auto callee =
      f->getParent()->getOrInsertFunction(name, func_type, f->getAttributes());
  auto new_func = cast<Function>(callee.getCallee());
  new_func->setCallingConv(f->getCallingConv());
  new_func->copyMetadata(f, 0);
  return new_func;
}

void SpecializeImageTypesPass::RewriteFunction(Function *f) {
  auto module = f->getParent();

  SmallVector<Type *, 8> arg_types;
  for (auto &arg : f->args()) {
    auto where = remapped_args_.find(&arg);
    if (where == remapped_args_.end())
      arg_types.push_back(arg.getType());
    else
      arg_types.push_back(where->second);
  }

  auto func_type =
      FunctionType::get(f->getReturnType(), arg_types, f->isVarArg());

  if (func_type == f->getFunctionType())
    return;

  f->removeFromParent();

  auto callee =
      module->getOrInsertFunction(f->getName(), func_type, f->getAttributes());
  auto new_func = cast<Function>(callee.getCallee());
  new_func->setCallingConv(f->getCallingConv());
  new_func->copyMetadata(f, 0);

  // Move the basic blocks.
  if (!f->isDeclaration()) {
    std::vector<BasicBlock *> blocks;
    for (auto &BB : *f) {
      blocks.push_back(&BB);
    }
    for (auto *BB : blocks) {
      BB->removeFromParent();
      BB->insertInto(new_func);
    }
  }

  // Replace args uses.
  for (auto old_arg_iter = f->arg_begin(), new_arg_iter = new_func->arg_begin();
       old_arg_iter != f->arg_end(); ++old_arg_iter, ++new_arg_iter) {
    // Mutate the old arg type to satisfy RAUW.
    old_arg_iter->mutateType(new_arg_iter->getType());
    old_arg_iter->replaceAllUsesWith(&*new_arg_iter);
    new_arg_iter->takeName(&*old_arg_iter);
  }

  // Copy uses because they will be modified.
  SmallVector<Value *, 8> users;
  for (auto U : f->users()) {
    users.push_back(U);
  }

  for (auto U : users) {
    if (auto call = dyn_cast<CallInst>(U)) {
      call->setCalledFunction(new_func);
    }
  }
  delete f;
}

} // namespace
