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
#include "SpecializeImageTypes.h"
#include "Types.h"
#include "clspv/Option.h"

using namespace clspv;
using namespace clspv::Builtins;
using namespace llvm;

PreservedAnalyses SpecializeImageTypesPass::run(Module &M,
                                                ModuleAnalysisManager &) {
  PreservedAnalyses PA;
  SmallVector<Function *, 8> kernels;
  for (auto &F : M) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;
    kernels.push_back(&F);
  }

  for (auto f : kernels) {
    for (auto &Arg : f->args()) {
      ResultType res;
      llvm::Type *new_ty = nullptr;
      std::tie(res, new_ty) = RemapType(&Arg);
      if (res != ResultType::kNotImage) {
        if (res == kNotSpecialized) {
          // Argument is an image, but not specializing information was found.
          // Assume the image is sampled with a float type.
          std::string name = cast<StructType>(new_ty)->getName().str();
          name += ".float";
          if (name.find("_ro") != std::string::npos) {
            name += ".sampled";
          } else if (Option::Language() >= Option::SourceLanguage::OpenCL_C_20) {
            // Treat write-only images as read-write images in OpenCL 2.0 or
            // later to avoid duplicate image types getting generated in the
            // SPIR.V.
            auto pos = name.find("_wo");
            if (pos != std::string::npos) {
              name = name.substr(0, pos) + "_rw" + name.substr(pos + 3);
            }
          }
          StructType *new_struct = StructType::getTypeByName(M.getContext(), name);
          if (!new_struct) {
            new_struct = StructType::create(M.getContext(), name);
          }
          new_ty = new_struct;
        }
        specialized_images_.insert(new_ty);
        SpecializeArg(f, &Arg, new_ty);
      }
    }
  }

  // TODO(#816): unnecessary after transition.
  // Keep functions in the same relative order.
  std::vector<Function *> to_rewrite;
  for (auto &F : M) {
    if (functions_to_modify_.count(&F))
      to_rewrite.push_back(&F);
  }
  for (auto f : to_rewrite) {
    RewriteFunction(f);
  }

  return PA;
}

std::pair<SpecializeImageTypesPass::ResultType, Type *>
SpecializeImageTypesPass::RemapType(Argument *arg) {
  ResultType final_res = ResultType::kNotImage;
  Type *new_ty = nullptr;
  for (auto &U : arg->uses()) {
    ResultType res;
    Type *ty = nullptr;
    std::tie(res, ty) = RemapUse(U.getUser(), U.getOperandNo());
    if (res == ResultType::kSpecialized) {
      return std::make_pair(res, ty);
    } else if (res == ResultType::kNotSpecialized && final_res == ResultType::kNotImage) {
      new_ty = ty;
      final_res = res;
    }
  }

  // TODO(#816): remove after final transition
  if (final_res == ResultType::kNotImage) {
    if (arg->getType()->isPointerTy() && !arg->getType()->isOpaquePointerTy()) {
      auto *ele_ty =
          cast<PointerType>(arg->getType())->getNonOpaquePointerElementType();
      StructType *struct_ty = dyn_cast<StructType>(ele_ty);
      if (IsImageType(struct_ty)) {
        return std::make_pair(ResultType::kNotSpecialized, struct_ty);
      }
    }
  }

  return std::make_pair(final_res, new_ty);
}

std::pair<SpecializeImageTypesPass::ResultType, Type *>
SpecializeImageTypesPass::RemapUse(Value *value, unsigned operand_no) {
  if (CallInst *call = dyn_cast<CallInst>(value)) {
    auto *called = call->getCalledFunction();
    auto info = Builtins::Lookup(called);
    if (!BUILTIN_IN_GROUP(info.getType(), Image)) {
      // Not an image builtin so see if we can specialize the type by
      // traversing the called function.
      ResultType final_res = ResultType::kNotImage;
      Type *new_ty = nullptr;
      if (!called->isDeclaration()) {
        for (auto &U : called->getArg(operand_no)->uses()) {
          ResultType res = ResultType::kNotImage;
          Type *ty = nullptr;
          std::tie(res, ty) = RemapUse(U.getUser(), U.getOperandNo());
          if (res == ResultType::kSpecialized) {
            return std::make_pair(res, ty);
          } else if (res == kNotSpecialized && final_res == kNotImage) {
            final_res = res;
            new_ty = ty;
          }
        }
      }
      return std::make_pair(final_res, new_ty);
    }
    if (operand_no != 0) {
      // All image builtins take the image as the first operand, so this is not
      // an image type.
      return std::make_pair(ResultType::kNotImage, nullptr);
    }

    // This user is an image type. Check if we've specialized it already. If
    // not, see if it can be specialized by this builtin.
    std::string name;
    auto *operand = call->getArgOperand(operand_no);
    // TODO(#816): remove after final transition.
    if (!operand->getType()->isOpaquePointerTy()) {
      auto *ele_ty = dyn_cast<PointerType>(operand->getType())
                         ->getNonOpaquePointerElementType();
      name = dyn_cast<StructType>(ele_ty)->getName().str();
    } else {
      auto param = info.getParameter(operand_no);
      assert(param.type_id == Type::StructTyID);
      name = param.name;
    }

    auto *struct_ty =
      StructType::getTypeByName(call->getContext(), name);

    if (specialized_images_.count(struct_ty))
      return std::make_pair(ResultType::kSpecialized, struct_ty);

    switch (info.getType()) {
    // Specializable cases: reads and writes.
    case Builtins::kReadImagef:
    case Builtins::kReadImagei:
    case Builtins::kReadImageui:
    case Builtins::kWriteImagef:
    case Builtins::kWriteImagei:
    case Builtins::kWriteImageui: {
      switch (info.getType()) {
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

      const auto wo_pos = name.find("_wo");
      const auto ro_pos = name.find("_ro");
      if (ro_pos != std::string::npos) {
        name += ".sampled";
      } else if (Option::Language() >= Option::SourceLanguage::OpenCL_C_20 &&
                 wo_pos != std::string::npos) {
        // In OpenCL 2.0 (or later), treat write_only images as read_write
        // images. This prevents the compiler from generating duplicate image
        // types (invalid SPIR-V).
        name = name.substr(0, wo_pos) + "_rw" + name.substr(wo_pos + 3);
      }

      struct_ty = StructType::getTypeByName(call->getContext(), name);
      if (!struct_ty) {
        struct_ty = StructType::create(call->getContext(), name);
      }
      return std::make_pair(ResultType::kSpecialized, struct_ty);
    }
    // Non-specializable cases: queries.
    default:
      return std::make_pair(ResultType::kNotSpecialized, struct_ty);
      break;
    }
  } else if (value->getType()->isPointerTy()) {
    // This can occur for instructions such as address space cast.
    ResultType final_res = ResultType::kNotImage;
    Type *new_ty = nullptr;
    for (auto &U : value->uses()) {
      ResultType res = ResultType::kNotImage;
      Type *ty = nullptr;
      std::tie(res, ty) = RemapUse(U.getUser(), U.getOperandNo());
      if (res == ResultType::kSpecialized) {
        return std::make_pair(res, ty);
      } else if (res == kNotSpecialized && final_res == kNotImage) {
        final_res = res;
        new_ty = ty;
      }
    }
  }

  return std::make_pair(ResultType::kNotImage, nullptr);
}

void SpecializeImageTypesPass::SpecializeArg(Function *f, Argument *arg,
                                             Type *new_type) {
  auto where = remapped_args_.find(arg);
  if (where != remapped_args_.end())
    return;

  // TODO(#816): remove after transition.
  const bool transparent = !arg->getType()->isOpaquePointerTy();
  remapped_args_[arg] = new_type;
  if (transparent) functions_to_modify_.insert(f);

  auto *struct_ty = cast<StructType>(new_type);

  // Fix all uses of |arg|.
  std::vector<Value *> stack;
  stack.push_back(arg);
  while (!stack.empty()) {
    Value *value = stack.back();
    stack.pop_back();

    if (transparent &&
        cast<PointerType>(value->getType())->getNonOpaquePointerElementType() ==
            new_type) {
      continue;
    }

    auto old_type = value->getType();
    if (transparent) {
      value->mutateType(
          PointerType::get(new_type, old_type->getPointerAddressSpace()));
    }
    for (auto &u : value->uses()) {
      if (auto call = dyn_cast<CallInst>(u.getUser())) {
        auto called = call->getCalledFunction();
        auto &func_info = Builtins::Lookup(called);
        if (BUILTIN_IN_GROUP(func_info.getType(), Image)) {
          auto new_func = ReplaceImageBuiltin(called, func_info, struct_ty);
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
                                                        Builtins::FunctionInfo info,
                                                        StructType *type) {
  // Update the parameter name and produce a new mangling of the function to
  // match.
  auto &image_param = info.getParameter(0);
  image_param.name = type->getName().str();
  std::string new_name = Builtins::GetMangledFunctionName(info);

  // TODO(#816): remove after transition
  Function *new_func = nullptr;
  if (f->getArg(0)->getType()->isOpaquePointerTy()) {
    auto callee = f->getParent()->getOrInsertFunction(
        new_name, f->getFunctionType(), f->getAttributes());
    new_func = cast<Function>(callee.getCallee());
  } else {
    SmallVector<Type *, 4> param_tys;
    for (auto &Arg : f->args()) {
      param_tys.push_back(Arg.getType());
    }
    param_tys[0] = PointerType::get(type, param_tys[0]->getPointerAddressSpace());

    auto func_ty =
        FunctionType::get(f->getReturnType(), param_tys, f->isVarArg());
    auto callee =
        f->getParent()->getOrInsertFunction(new_name, func_ty, f->getAttributes());
    new_func = cast<Function>(callee.getCallee());
  }

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
      arg_types.push_back(PointerType::get(
          where->second, arg.getType()->getPointerAddressSpace()));
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
