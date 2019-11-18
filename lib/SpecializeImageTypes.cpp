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

#include "llvm/IR/CallingConv.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "ArgKind.h"
#include "Builtins.h"
#include "Constants.h"
#include "Passes.h"

#include <unordered_set>

using namespace clspv;
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

  // Rewrites |f| to have arguments of |remapped| types.
  void RewriteFunction(Function *f, const ArrayRef<Type *> &remapped);

  std::unordered_set<Type *> specialized_images_;
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

  DenseMap<Function *, SmallVector<Type *, 8>> remapped_args;
  for (auto f : kernels) {
    bool local_changed = false;
    SmallVector<Type *, 8> remapped;
    for (auto &Arg : f->args()) {
      remapped.push_back(Arg.getType());
      if (IsImageType(Arg.getType())) {
        Type *new_type = RemapType(&Arg);
        if (!new_type) {
          // No specializing information found, assume the image is sampled with
          // a float type.
          std::string name =
              cast<StructType>(Arg.getType()->getPointerElementType())
                  ->getName();
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
        local_changed = true;
        SpecializeArg(f, &Arg, new_type);
        remapped.back() = new_type;
      }
    }
    if (local_changed) {
      remapped_args[f] = remapped;
    }

    changed |= local_changed;
  }

  for (auto f : kernels) {
    auto where = remapped_args.find(f);
    if (where == remapped_args.end())
      continue;

    RewriteFunction(f, where->second);
  }

  return true;
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
    if (IsSampledImageRead(called) || IsImageWrite(called)) {
      // Specialize the image type based on the it's usage in the builtin.
      Value *image = call->getOperand(0);
      Type *imageTy = image->getType();

      // Check if this type is already specialized.
      if (specialized_images_.count(imageTy))
        return imageTy;

      std::string name =
          cast<StructType>(imageTy->getPointerElementType())->getName();
      if (IsFloatSampledImageRead(called) || IsFloatImageWrite(called)) {
        name += ".float";
      } else if (IsUintSampledImageRead(called) || IsUintImageWrite(called)) {
        name += ".uint";
      } else if (IsIntSampledImageRead(called) || IsIntImageWrite(called)) {
        name += ".int";
      } else {
        assert(false && "Unhandled image builtin");
      }

      if (IsSampledImageRead(called)) {
        name += ".sampled";
      }

      StructType *new_struct =
          call->getParent()->getParent()->getParent()->getTypeByName(name);
      if (!new_struct) {
        new_struct = StructType::create(call->getContext(), name);
      }
      PointerType *new_pointer =
          PointerType::get(new_struct, imageTy->getPointerAddressSpace());
      return new_pointer;
    } else if (!called->isDeclaration()) {
      for (auto &U : called->getArg(operand_no)->uses()) {
        if (auto new_type = RemapUse(U.getUser(), U.getOperandNo())) {
          return new_type;
        }
      }
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
  if (arg->getType() == new_type)
    return;

  // First replace the uses.
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
        if (IsImageBuiltin(called)) {
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

  // Second, update the function.
  if (f->getCallingConv() != CallingConv::SPIR_KERNEL) {
    SmallVector<Type *, 8> remapped;
    for (auto &Arg : f->args()) {
      if (arg == &Arg)
        remapped.push_back(new_type);
      else
        remapped.push_back(Arg.getType());
    }
    RewriteFunction(f, remapped);
  }
}

Function *SpecializeImageTypesPass::ReplaceImageBuiltin(Function *f,
                                                        Type *type) {
  std::string name = f->getName();
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

void SpecializeImageTypesPass::RewriteFunction(
    Function *f, const ArrayRef<Type *> &remapped) {
  auto module = f->getParent();
  auto func_type =
      FunctionType::get(f->getReturnType(), remapped, f->isVarArg());

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
    old_arg_iter->replaceAllUsesWith(&*new_arg_iter);
    new_arg_iter->takeName(&*old_arg_iter);
  }

  f->replaceAllUsesWith(new_func);
  delete f;
}

} // namespace
