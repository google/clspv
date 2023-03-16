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
      visited_.clear();
      ResultType res;
      llvm::Type *new_ty = nullptr;
      std::tie(res, new_ty) = RemapType(&Arg);
      if (res != ResultType::kNotImage) {
        if (res == kNotSpecialized) {
          // Argument is an image, but no specializing information was found.
          // Assume the image is sampled with a float type.
          // TODO(#1036): remove opaque struct support
          if (auto *ext_ty = dyn_cast<TargetExtType>(new_ty)) {
            SmallVector<Type *, 1> types(1, Type::getFloatTy(M.getContext()));
            SmallVector<uint32_t, 8> ints(ext_ty->int_params());
            auto &access = ints[SpvImageTypeOperand::kAccessQualifier];
            if (access == 0) {
              ints[SpvImageTypeOperand::kSampled] = 1;
            } else {
              ints[SpvImageTypeOperand::kSampled] = 2;
            }

            if (Option::Language() >= Option::SourceLanguage::OpenCL_C_20 && access == 1) {
              // In OpenCL 2.0 treat write_only as read_write.
              access = 2;
            }
            ints.push_back(0); // unsigned
            new_ty = TargetExtType::get(M.getContext(), "spirv.Image", types, ints);
          } else if (auto *struct_ty = dyn_cast<StructType>(new_ty)) {
            std::string name = struct_ty->getName().str();
            name += ".float";
            if (name.find("_ro") != std::string::npos) {
              name += ".sampled";
            } else if (Option::Language() >=
                       Option::SourceLanguage::OpenCL_C_20) {
              // Treat write-only images as read-write images in OpenCL 2.0 or
              // later to avoid duplicate image types getting generated in the
              // SPIR.V.
              auto pos = name.find("_wo");
              if (pos != std::string::npos) {
                name = name.substr(0, pos) + "_rw" + name.substr(pos + 3);
              }
            }
            StructType *new_struct =
                StructType::getTypeByName(M.getContext(), name);
            if (!new_struct) {
              new_struct = StructType::create(M.getContext(), name);
            }
            new_ty = new_struct;
          }
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
  if (!visited_.insert(value).second) {
    // There is a larger problem if an image is used in a phi loop so if we're
    // re-looping through instructions, just return not an image.
    return std::make_pair(ResultType::kNotImage, nullptr);
  }

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
    auto *operand_ty = operand->getType();
    if (isa<TargetExtType>(operand_ty)) {
      // This is an image.
      assert(clspv::IsImageType(operand_ty));
    } else if (!operand_ty->isOpaquePointerTy()) {
      // TODO(#816): remove after final transition.
      auto *ele_ty =
          dyn_cast<PointerType>(operand_ty)->getNonOpaquePointerElementType();
      name = dyn_cast<StructType>(ele_ty)->getName().str();
    } else {
      auto param = info.getParameter(operand_no);
      assert(param.type_id == Type::StructTyID);
      name = param.name;
    }

    Type *image_ty = nullptr;
    if (name.empty()) {
      image_ty = operand_ty;
    } else {
      auto *struct_ty =
        StructType::getTypeByName(call->getContext(), name);
      if (!struct_ty) {
        struct_ty = StructType::create(call->getContext(), name);
      }
      image_ty = struct_ty;
    }

    if (specialized_images_.count(image_ty))
      return std::make_pair(ResultType::kSpecialized, image_ty);

    Type *sampled_ty = nullptr;
    uint32_t uint = 0;
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
        sampled_ty = Type::getFloatTy(image_ty->getContext());
        break;
      case Builtins::kReadImagei:
      case Builtins::kWriteImagei:
        name += ".int";
        sampled_ty = Type::getInt32Ty(image_ty->getContext());
        break;
      case Builtins::kReadImageui:
      case Builtins::kWriteImageui:
        name += ".uint";
        sampled_ty = Type::getInt32Ty(image_ty->getContext());
        uint = 1;
        break;
      default:
        break;
      }

      if (auto *ext_ty = dyn_cast<TargetExtType>(image_ty)) {
        SmallVector<Type *, 1> types({sampled_ty});
        SmallVector<uint32_t, 8> ints(ext_ty->int_params());
        ints.push_back(uint);
        uint32_t sampled = 1;
        if (clspv::IsSampledImageType(ext_ty)) {
          // Sampled image
          sampled = 1;
        } else {
          // Storage image
          sampled = 2;
        }
        ints[clspv::SpvImageTypeOperand::kSampled] = sampled;
        auto &access = ints[clspv::SpvImageTypeOperand::kAccessQualifier];
        if (Option::Language() >= Option::SourceLanguage::OpenCL_C_20 &&
            access == 1) {
          access = 2;
        }
        auto *spec_ty = TargetExtType::get(image_ty->getContext(),
                                           "spirv.Image", types, ints);
        image_ty = spec_ty;
      } else {
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

        auto *struct_ty = StructType::getTypeByName(call->getContext(), name);
        if (!struct_ty) {
          struct_ty = StructType::create(call->getContext(), name);
        }
        image_ty = struct_ty;
      }
      return std::make_pair(ResultType::kSpecialized, image_ty);
    }
    // Non-specializable cases: queries.
    default:
      return std::make_pair(ResultType::kNotSpecialized, image_ty);
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

  // Fix all uses of |arg|.
  std::vector<Value *> stack;
  stack.push_back(arg);
  while (!stack.empty()) {
    Value *value = stack.back();
    stack.pop_back();

    if (value->getType() == new_type) {
      continue;
    } else if (transparent && isa<PointerType>(value->getType()) &&
               cast<PointerType>(value->getType())
                       ->getNonOpaquePointerElementType() == new_type) {
      // TODO(#816): remove after final transition.
      continue;
    }
    //if (transparent &&
    //    cast<PointerType>(value->getType())->getNonOpaquePointerElementType() ==
    //        new_type) {
    //  continue;
    //}

    auto old_type = value->getType();
    if (transparent && isa<PointerType>(old_type)) {
      value->mutateType(
          PointerType::get(new_type, old_type->getPointerAddressSpace()));
    } else if (!isa<PointerType>(old_type)) {
      value->mutateType(new_type);
    }
    for (auto &u : value->uses()) {
      if (auto call = dyn_cast<CallInst>(u.getUser())) {
        auto called = call->getCalledFunction();
        auto &func_info = Builtins::Lookup(called);
        if (BUILTIN_IN_GROUP(func_info.getType(), Image)) {
          auto new_func = ReplaceImageBuiltin(called, func_info, new_type);
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
                                                        Type *type) {
  // Update the parameter name and produce a new mangling of the function to
  // match.
  auto &image_param = info.getParameter(0);
  if (auto *struct_ty = dyn_cast<StructType>(type)) {
    image_param.name = struct_ty->getName().str();
  } else {
    // Construct a struct name.
    auto *ext_ty = dyn_cast<TargetExtType>(type);
    std::string name = "ocl_image";
    switch (ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kDim)) {
    case 0:
      name += "1d";
      break;
    case 1:
      name += "2d";
      break;
    case 2:
      name += "3d";
      break;
    case 5:
      name += "1d_buffer";
      break;
    default:
      llvm_unreachable("Unknown dim");
      break;
    }
    name += "_";
    if (ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kArrayed) == 1) {
      name += "array_";
    }
    switch (
        ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kAccessQualifier)) {
    case 0:
      name += "ro_t";
      break;
    case 1:
      if (clspv::Option::Language() >= Option::SourceLanguage::OpenCL_C_20)
        name += "rw_t";
      else
        name += "wo_t";
      break;
    case 2:
      name += "rw_t";
      break;
    default:
      llvm_unreachable("Unknown access qualifier");
      break;
    }
    if (ext_ty->getTypeParameter(0)->isFloatTy()) {
      name += ".float";
    } else if (ext_ty->getIntParameter(
                   clspv::SpvImageTypeOperand::kClspvUnsigned) == 1) {
      name += ".uint";
    } else {
      name += ".int";
    }
    if (ext_ty->getIntParameter(clspv::SpvImageTypeOperand::kSampled) == 1) {
      name += ".sampled";
    }
    image_param.name = name;
  }
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
    if (type->isStructTy()) {
      param_tys[0] = PointerType::get(type, param_tys[0]->getPointerAddressSpace());
    } else {
      param_tys[0] = type;
    }

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
    if (where == remapped_args_.end()) {
      arg_types.push_back(arg.getType());
    } else if (where->second->isStructTy()) {
      arg_types.push_back(PointerType::get(
          where->second, arg.getType()->getPointerAddressSpace()));
    } else {
      arg_types.push_back(where->second);
    }
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
