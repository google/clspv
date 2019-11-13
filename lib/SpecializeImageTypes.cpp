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

#include "Constants.h"
#include "Passes.h"

using namespace llvm;

namespace {

class SpecializeImageTypesPass : public ModulePass {
public:
  static char ID;
  SpecializeImageTypesPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Returns true if |type| is an OpenCL image type.
  bool IsImageType(Type *type) const;

  // Returns true if |f| is an OpenCL image builtin function.
  bool IsImageBuiltin(Function *f) const;

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
  // outs() << M << "\n";
  bool changed = false;
  SmallVector<Function *, 8> kernels;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;
    kernels.push_back(&F);
  }

  DenseMap<Function *, SmallVector<Type *, 8>> remapped_args;
  for (auto f : kernels) {
    outs() << "Function: " << f->getName() << "\n";
    bool local_changed = false;
    SmallVector<Type *, 8> remapped;
    for (auto &Arg : f->args()) {
      outs() << " Arg: " << Arg.getName() << "\n";
      remapped.push_back(Arg.getType());
      if (IsImageType(Arg.getType())) {
        outs() << "  Image: " << Arg << "\n";
        Type *new_type = RemapType(&Arg);
        if (new_type) {
          outs() << "   new type: " << *new_type << "\n";
          local_changed = true;
          SpecializeArg(f, &Arg, new_type);
          remapped.back() = new_type;
        }
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

bool SpecializeImageTypesPass::IsImageType(Type *type) const {
  if (auto ptrTy = dyn_cast<PointerType>(type)) {
    if (auto structTy = dyn_cast<StructType>(ptrTy->getPointerElementType())) {
      if (structTy->getName().startswith("opencl.image"))
        return true;
    }
  }

  return false;
}

bool SpecializeImageTypesPass::IsImageBuiltin(Function *f) const {
  // TODO(alan-baker): finish these
  if (f->getName() == "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f" ||
      f->getName() == "_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_f" ||
      f->getName() == "_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_f" ||
      f->getName() == "_Z12write_imagef14ocl_image2d_woDv2_iDv4_f" ||
      f->getName() == "_Z12write_imagei14ocl_image2d_woDv2_iDv4_i" ||
      f->getName() == "_Z13write_imageui14ocl_image2d_woDv2_iDv4_j") {
    return true;
  }

  return false;
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
    if (IsImageBuiltin(called)) {
      Value *image = call->getOperand(0);
      Type *imageTy = image->getType();
      std::string name =
          cast<StructType>(imageTy->getPointerElementType())->getName();
      if (called->getName().contains("read_imagef") ||
          called->getName().contains("write_imagef")) {
        name += ".float";
      } else if (called->getName().contains("read_imageui") ||
                 called->getName().contains("write_imageui")) {
        name += ".uint";
      } else if (called->getName().contains("read_imagei") ||
                 called->getName().contains("write_imagei")) {
        name += ".int";
      } else {
        assert(false && "Unhandled image builtin");
      }

      if (called->getName().contains("read_image") &&
          called->getName().contains("ocl_sampler")) {
        name += ".sampled";
      }

      StructType *new_struct = StructType::create(call->getContext(), name);
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
          outs() << "OLD BUILTIN CALL: " << *call << "\n";
          auto new_func = ReplaceImageBuiltin(called, new_type);
          call->setCalledFunction(new_func);
          if (called->getNumUses() == 0)
            called->eraseFromParent();
          outs() << "NEW BUILTIN CALL: " << *call << "\n";
        } else {
          SpecializeArg(called, called->getArg(u.getOperandNo()), new_type);
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

  // There are no calls to |f| yet so we don't need to worry about updating
  // calls.

  delete f;
}

} // namespace
