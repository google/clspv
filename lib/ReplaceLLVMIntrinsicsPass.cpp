// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "BitcastUtils.h"
#include "clspv/Option.h"
#include "spirv/unified1/spirv.hpp"

#include "Builtins.h"
#include "Constants.h"
#include "ReplaceLLVMIntrinsicsPass.h"
#include "SPIRVOp.h"
#include "Types.h"

using namespace llvm;

#define DEBUG_TYPE "ReplaceLLVMIntrinsics"

namespace {
Type *UpdateTy(LLVMContext &Ctx, uint64_t Size) {
  if (Size % (4 * sizeof(uint32_t)) == 0) {
    return FixedVectorType::get(Type::getInt32Ty(Ctx), 4);
  } else if (Size % (2 * sizeof(uint32_t)) == 0) {
    return FixedVectorType::get(Type::getInt32Ty(Ctx), 2);
  } else if (Size % sizeof(uint32_t) == 0) {
    return Type::getInt32Ty(Ctx);
  } else if (Size % sizeof(uint16_t) == 0) {
    return Type::getInt16Ty(Ctx);
  } else {
    return Type::getInt8Ty(Ctx);
  }
}
} // namespace

PreservedAnalyses
clspv::ReplaceLLVMIntrinsicsPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  for (auto &F : M) {
    runOnFunction(F);
  }

  // Remove lifetime annotations first.  They could be using memset
  // and memcpy calls.
  replaceMemset(M);
  replaceMemcpy(M);

  for (auto F : DeadFunctions) {
    F->eraseFromParent();
  }

  return PA;
}

bool clspv::ReplaceLLVMIntrinsicsPass::runOnFunction(Function &F) {
  switch (F.getIntrinsicID()) {
  case Intrinsic::fshl:
    return replaceFshl(F);
  case Intrinsic::copysign:
    return replaceCopysign(F);
  case Intrinsic::ctlz:
    return replaceCountZeroes(F, true);
  case Intrinsic::cttz:
    return replaceCountZeroes(F, false);
  case Intrinsic::usub_sat:
    return replaceAddSubSat(F, false, false);
  case Intrinsic::uadd_sat:
    return replaceAddSubSat(F, false, true);
  case Intrinsic::ssub_sat:
    return replaceAddSubSat(F, true, false);
  case Intrinsic::sadd_sat:
    return replaceAddSubSat(F, true, true);
  // SPIR-V OpAssumeTrueKHR requires ExpectAssumeKHR capability in SPV_KHR_expect_assume extension.
  // Vulkan doesn't support that, so remove assume declaration.
  case Intrinsic::assume:
  // SPIR-V OpLifetimeStart and OpLifetimeEnd require Kernel capability.
  // Vulkan doesn't support that, so remove all lifteime bounds declarations.
  case Intrinsic::lifetime_start:
  case Intrinsic::lifetime_end:
    return removeIntrinsicDeclaration(F);
  default:
    break;
  }

  return false;
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceCallsWithValue(
    Function &F, std::function<Value *(CallInst *)> Replacer) {
  SmallVector<Instruction *, 8> ToRemove;
  for (auto &U : F.uses()) {
    if (auto Call = dyn_cast<CallInst>(U.getUser())) {
      auto replacement = Replacer(Call);
      if (replacement != nullptr && replacement != Call) {
        Call->replaceAllUsesWith(replacement);
        ToRemove.push_back(Call);
      }
    }
  }

  for (auto inst : ToRemove) {
    inst->eraseFromParent();
  }

  DeadFunctions.push_back(&F);

  return !ToRemove.empty();
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceFshl(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *call) {
    auto arg_hi = call->getArgOperand(0);
    auto arg_lo = call->getArgOperand(1);
    auto arg_shift = call->getArgOperand(2);

    // Validate argument types.
    auto type = arg_hi->getType();
    if ((type->getScalarSizeInBits() != 8) &&
        (type->getScalarSizeInBits() != 16) &&
        (type->getScalarSizeInBits() != 32) &&
        (type->getScalarSizeInBits() != 64)) {
      return static_cast<Value *>(nullptr);
    }

    // We shift the bottom bits of the first argument up, the top bits of the
    // second argument down, and then OR the two shifted values.
    IRBuilder<> builder(call);

    // The shift amount is treated modulo the element size.
    auto mod_mask = ConstantInt::get(type, type->getScalarSizeInBits() - 1);
    auto shift_amount = builder.CreateAnd(arg_shift, mod_mask);

    // Calculate the amount by which to shift the second argument down.
    auto scalar_size = ConstantInt::get(type, type->getScalarSizeInBits());
    auto down_amount = builder.CreateSub(scalar_size, shift_amount);

    // "The resulting value is undefined if Shift is greater than or equal to
    // the bit width of the components of Base."
    // https://www.khronos.org/registry/SPIR-V/specs/unified1/SPIRV.html#Bit
    if (!dyn_cast<ConstantInt>(arg_shift)) {
      down_amount = builder.CreateAnd(down_amount, mod_mask);
    }

    // Shift the two arguments and OR the results together.
    auto hi_bits = builder.CreateShl(arg_hi, shift_amount);
    auto lo_bits = builder.CreateLShr(arg_lo, down_amount);

    return builder.CreateOr(lo_bits, hi_bits);
  });
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceMemset(Module &M) {
  bool Changed = false;
  auto Layout = M.getDataLayout();

  DenseMap<Value *, Type *> type_cache;

  auto unpack = [&Layout](CallInst &CI, uint64_t Size, Type **Ty,
                          unsigned *NumUnpackings) {
    auto ElemSize = Layout.getTypeSizeInBits(*Ty) / 8;
    while (Size < ElemSize) {
      auto EleTy = BitcastUtils::GetEleType(*Ty);
      assert(EleTy != *Ty);
      *Ty = EleTy;
      (*NumUnpackings)++;
      ElemSize = Layout.getTypeSizeInBits(*Ty) / 8;
    }
  };

  for (auto &F : M) {
    if (F.getName().contains("llvm.memset")) {
      SmallVector<CallInst *, 8> CallsToReplace;

      for (auto U : F.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          auto Initializer = dyn_cast<ConstantInt>(CI->getArgOperand(1));

          // We only handle cases where the initializer is a constant int that
          // is 0.
          if (!Initializer || (0 != Initializer->getZExtValue())) {
            Initializer->print(errs());
            llvm_unreachable("Unhandled llvm.memset.* instruction that had a "
                             "non-0 initializer!");
          }

          CallsToReplace.push_back(CI);
        }
      }

      for (auto CI : CallsToReplace) {
        auto NewArg = CI->getArgOperand(0);
        auto Bitcast = dyn_cast<BitCastInst>(NewArg);
        if (Bitcast != nullptr) {
          NewArg = Bitcast->getOperand(0);
        }

        auto I32Ty = Type::getInt32Ty(M.getContext());
        auto NumBytes = cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();
        auto PointeeTy = clspv::InferType(NewArg, M.getContext(), &type_cache);
        if (PointeeTy == nullptr) {
          PointeeTy = UpdateTy(M.getContext(), NumBytes);
          NewArg = GetElementPtrInst::Create(
              PointeeTy, NewArg, {ConstantInt::get(I32Ty, 0)}, "", CI);
        }
        unsigned Unpacking = 0;
        unpack(*CI, NumBytes, &PointeeTy, &Unpacking);

        auto NullValue = Constant::getNullValue(PointeeTy);
        auto Zero = ConstantInt::get(I32Ty, 0);

        SmallVector<Value *, 3> Indices;
        for (unsigned i = 0; i < Unpacking; i++) {
          Indices.push_back(Zero);
        }
        // Add a placeholder for the final index.
        Indices.push_back(Zero);

        const auto num_stores = NumBytes / Layout.getTypeAllocSize(PointeeTy);
        assert((NumBytes == num_stores * Layout.getTypeAllocSize(PointeeTy)) &&
               "Null memset can't be divided evenly across multiple stores.");
        assert((num_stores & 0xFFFFFFFF) == num_stores);

        for (uint32_t i = 0; i < num_stores; i++) {
          Indices.back() = ConstantInt::get(I32Ty, i);
          auto Ptr =
              GetElementPtrInst::Create(PointeeTy, NewArg, Indices, "", CI);
          new StoreInst(NullValue, Ptr, CI);
        }

        CI->eraseFromParent();

        if (Bitcast != nullptr) {
          Bitcast->eraseFromParent();
        }
      }
      DeadFunctions.push_back(&F);
    }
  }

  return Changed;
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceMemcpy(Module &M) {
  bool Changed = false;
  auto Layout = M.getDataLayout();

  DenseMap<Value *, Type *> type_cache;

  for (auto &F : M) {
    if (F.getName().contains("llvm.memcpy")) {
      SmallVector<CallInst *, 8> CallsToReplaceWithSpirvCopyMemory;

      for (auto U : F.users()) {
        if (auto CI = dyn_cast<CallInst>(U)) {
          CallsToReplaceWithSpirvCopyMemory.push_back(CI);
        }
      }

      for (auto CI : CallsToReplaceWithSpirvCopyMemory) {
        auto I32Ty = Type::getInt32Ty(M.getContext());
        bool Volatile =
            dyn_cast<ConstantInt>(CI->getArgOperand(3))->getZExtValue();

        auto Dst = CI->getArgOperand(0);
        auto Src = CI->getArgOperand(1);
        auto DstTy = clspv::InferType(Dst, M.getContext(), &type_cache);
        auto SrcTy = clspv::InferType(Src, M.getContext(), &type_cache);

        auto Size = dyn_cast<ConstantInt>(CI->getArgOperand(2))->getZExtValue();

        IRBuilder<> Builder(CI);
        Type *ElemTy;
        if (DstTy == SrcTy && SrcTy != nullptr &&
            ((Size % (BitcastUtils::SizeInBits(Layout, SrcTy) / CHAR_BIT)) ==
             0)) {
          ElemTy = SrcTy;
        } else {
          ElemTy = UpdateTy(M.getContext(), Size);
        }
        auto ElemSize = Layout.getTypeSizeInBits(ElemTy) / CHAR_BIT;

        for (unsigned i = 0; i < Size / ElemSize; ++i) {
          auto Index = ConstantInt::get(I32Ty, i);
          SmallVector<Value *, 3> Indices = {Index};

          // Avoid the builder for Src in order to prevent the folder from
          // creating constant expressions for constant memcpys.
          auto SrcElemPtr =
              GetElementPtrInst::CreateInBounds(ElemTy, Src, Indices, "", CI);
          auto Srci = Builder.CreateLoad(ElemTy, SrcElemPtr, Volatile);
          auto DstElemPtr = Builder.CreateGEP(ElemTy, Dst, Indices);
          Builder.CreateStore(Srci, DstElemPtr, Volatile);
        }

        // Erase the call.
        CI->eraseFromParent();
      }
      DeadFunctions.push_back(&F);
    }
  }

  return Changed;
}

bool clspv::ReplaceLLVMIntrinsicsPass::removeIntrinsicDeclaration(Function &F) {
  // Copy users to avoid modifying the list in place.
  SmallVector<User *, 8> users(F.users());
  for (auto U : users) {
    if (auto *CI = dyn_cast<CallInst>(U)) {
      CI->eraseFromParent();
    }
  }
  DeadFunctions.push_back(&F);
  return true;
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceCountZeroes(Function &F,
                                                          bool leading) {
  if (!isa<IntegerType>(F.getReturnType()->getScalarType()))
    return false;

  auto bitwidth = F.getReturnType()->getScalarSizeInBits();
  if (bitwidth == 32 || bitwidth > 64)
    return false;

  return replaceCallsWithValue(F, [&F, bitwidth, leading](CallInst *Call) {
    auto c_false = ConstantInt::getFalse(Call->getContext());
    auto in = Call->getArgOperand(0);
    IRBuilder<> builder(Call);
    auto ty = Call->getType()->getWithNewBitWidth(32);
    auto c32 = ConstantInt::get(ty, 32);
    auto func_32bit = Intrinsic::getDeclaration(
        F.getParent(), leading ? Intrinsic::ctlz : Intrinsic::cttz, ty);
    if (bitwidth < 32) {
      // Extend the input to 32-bits and perform a clz/ctz.
      auto zext = builder.CreateZExt(in, ty);
      Value *call_input = zext;
      if (!leading) {
        // Or the extended input value with a constant that caps the max to the
        // right bitwidth (e.g. 256 for i8 and 65536 for i16).
        auto mask = ConstantInt::get(ty, 1 << bitwidth);
        call_input = builder.CreateOr(zext, mask);
      }
      auto call = builder.CreateCall(func_32bit->getFunctionType(), func_32bit,
                                     {call_input, c_false});
      Value *tmp = call;
      if (leading) {
        // Clz is implemented as 31 - FindUMsb(|zext|), so adjust the result
        // the right bitwidth.
        auto sub_const = ConstantInt::get(ty, 32 - bitwidth);
        tmp = builder.CreateSub(call, sub_const);
      }
      // Truncate the intermediate result to the right size.
      return builder.CreateTrunc(tmp, Call->getType());
    } else {
      // Perform a 32-bit version of clz/ctz on each half of the 64-bit input.
      auto lshr = builder.CreateLShr(in, 32);
      auto top_bits = builder.CreateTrunc(lshr, ty);
      auto bot_bits = builder.CreateTrunc(in, ty);
      auto top_func = builder.CreateCall(func_32bit->getFunctionType(),
                                         func_32bit, {top_bits, c_false});
      auto bot_func = builder.CreateCall(func_32bit->getFunctionType(),
                                         func_32bit, {bot_bits, c_false});
      Value *tmp = nullptr;
      if (leading) {
        // For clz, if clz(top) is 32, return 32 + clz(bot).
        auto cmp = builder.CreateICmpEQ(top_func, c32);
        auto adjust = builder.CreateAdd(bot_func, c32);
        tmp = builder.CreateSelect(cmp, adjust, top_func);
      } else {
        // For ctz, if clz(bot) is 32, return 32 + ctz(top)
        auto bot_cmp = builder.CreateICmpEQ(bot_func, c32);
        auto adjust = builder.CreateAdd(top_func, c32);
        tmp = builder.CreateSelect(bot_cmp, adjust, bot_func);
      }
      // Extend the intermediate result to the correct size.
      return builder.CreateZExt(tmp, Call->getType());
    }
  });
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceCopysign(Function &F) {
  return replaceCallsWithValue(F, [&F](CallInst *CI) {
    auto XValue = CI->getOperand(0);
    auto YValue = CI->getOperand(1);

    auto Ty = XValue->getType();

    Type *IntTy = Type::getIntNTy(F.getContext(), Ty->getScalarSizeInBits());
    if (auto vec_ty = dyn_cast<VectorType>(Ty)) {
      IntTy = FixedVectorType::get(
          IntTy, vec_ty->getElementCount().getKnownMinValue());
    }

    // Return X with the sign of Y

    // Sign bit masks
    auto SignBit = IntTy->getScalarSizeInBits() - 1;
    auto SignBitMask = 1 << SignBit;
    auto SignBitMaskValue = ConstantInt::get(IntTy, SignBitMask);
    auto NotSignBitMaskValue = ConstantInt::get(IntTy, ~SignBitMask);

    IRBuilder<> Builder(CI);

    // Extract sign of Y
    auto YInt = Builder.CreateBitCast(YValue, IntTy);
    auto YSign = Builder.CreateAnd(YInt, SignBitMaskValue);

    // Clear sign bit in X
    auto XInt = Builder.CreateBitCast(XValue, IntTy);
    XInt = Builder.CreateAnd(XInt, NotSignBitMaskValue);

    // Insert sign bit of Y into X
    auto NewXInt = Builder.CreateOr(XInt, YSign);

    // And cast back to floating-point
    return Builder.CreateBitCast(NewXInt, Ty);
  });
}

bool clspv::ReplaceLLVMIntrinsicsPass::replaceAddSubSat(Function &F,
                                                        bool is_signed,
                                                        bool is_add) {
  return replaceCallsWithValue(F, [&F, is_signed, is_add](CallInst *Call) {
    auto ty = Call->getType();
    auto a = Call->getArgOperand(0);
    auto b = Call->getArgOperand(1);
    IRBuilder<> builder(Call);
    if (is_signed) {
      unsigned bitwidth = ty->getScalarSizeInBits();
      if (bitwidth < 32) {
        unsigned extended_width = bitwidth << 1;
        if (clspv::Option::HackClampWidth() && extended_width < 32) {
          extended_width = 32;
        }
        Type *extended_ty =
            IntegerType::get(Call->getContext(), extended_width);
        Constant *min = ConstantInt::get(
            Call->getContext(),
            APInt::getSignedMinValue(bitwidth).sext(extended_width));
        Constant *max = ConstantInt::get(
            Call->getContext(),
            APInt::getSignedMaxValue(bitwidth).sext(extended_width));
        // Don't use the type in GetMangledFunctionName to ensure we get
        // signed parameters.
        std::string sclamp_name = Builtins::GetMangledFunctionName("clamp");
        if (auto vec_ty = dyn_cast<VectorType>(ty)) {
          extended_ty = VectorType::get(extended_ty, vec_ty->getElementCount());
          min = ConstantVector::getSplat(vec_ty->getElementCount(), min);
          max = ConstantVector::getSplat(vec_ty->getElementCount(), max);
          unsigned vec_width = vec_ty->getElementCount().getKnownMinValue();
          if (extended_width == 32) {
            sclamp_name += "Dv" + std::to_string(vec_width) + "_iS_S_";
          } else {
            sclamp_name += "Dv" + std::to_string(vec_width) + "_sS_S_";
          }
        } else {
          if (extended_width == 32) {
            sclamp_name += "iii";
          } else {
            sclamp_name += "sss";
          }
        }

        auto sext_a = builder.CreateSExt(a, extended_ty);
        auto sext_b = builder.CreateSExt(b, extended_ty);
        Value *op = nullptr;
        // Extended operations won't wrap.
        if (is_add)
          op = builder.CreateAdd(sext_a, sext_b, "", true, true);
        else
          op = builder.CreateSub(sext_a, sext_b, "", true, true);
        auto clamp_ty = FunctionType::get(
            extended_ty, {extended_ty, extended_ty, extended_ty}, false);
        auto callee = F.getParent()->getOrInsertFunction(sclamp_name, clamp_ty);
        auto clamp = builder.CreateCall(callee, {op, min, max});
        return builder.CreateTrunc(clamp, ty);
      } else {
        // Add:
        // c = a + b
        // if (b < 0)
        //   c = c > a ? min : c;
        // else
        //   c  = c < a ? max : c;
        //
        // Sub:
        // c = a - b;
        // if (b < 0)
        //   c = c < a ? max : c;
        // else
        //   c = c > a ? min : c;
        Constant *min = ConstantInt::get(Call->getContext(),
                                         APInt::getSignedMinValue(bitwidth));
        Constant *max = ConstantInt::get(Call->getContext(),
                                         APInt::getSignedMaxValue(bitwidth));
        if (auto vec_ty = dyn_cast<VectorType>(ty)) {
          min = ConstantVector::getSplat(vec_ty->getElementCount(), min);
          max = ConstantVector::getSplat(vec_ty->getElementCount(), max);
        }
        Value *op = nullptr;
        if (is_add) {
          op = builder.CreateAdd(a, b);
        } else {
          op = builder.CreateSub(a, b);
        }
        auto b_lt_0 = builder.CreateICmpSLT(b, Constant::getNullValue(ty));
        auto op_gt_a = builder.CreateICmpSGT(op, a);
        auto op_lt_a = builder.CreateICmpSLT(op, a);
        auto neg_cmp = is_add ? op_gt_a : op_lt_a;
        auto pos_cmp = is_add ? op_lt_a : op_gt_a;
        auto neg_value = is_add ? min : max;
        auto pos_value = is_add ? max : min;
        auto neg_clamp = builder.CreateSelect(neg_cmp, neg_value, op);
        auto pos_clamp = builder.CreateSelect(pos_cmp, pos_value, op);
        return builder.CreateSelect(b_lt_0, neg_clamp, pos_clamp);
      }
    } else {
      // Replace with OpIAddCarry/OpISubBorrow and clamp to max/0 on a
      // carry/borrow.
      spv::Op op = is_add ? spv::OpIAddCarry : spv::OpISubBorrow;
      auto clamp_value =
          is_add ? Constant::getAllOnesValue(ty) : Constant::getNullValue(ty);
      auto struct_ty = StructType::get(ty->getContext(), {ty, ty});
      auto call = clspv::InsertSPIRVOp(Call, op, {}, struct_ty, {a, b},
                                       MemoryEffects::none());

      auto add_sub = builder.CreateExtractValue(call, {0});
      auto carry_borrow = builder.CreateExtractValue(call, {1});
      auto cmp = builder.CreateICmpEQ(carry_borrow, Constant::getNullValue(ty));
      return builder.CreateSelect(cmp, add_sub, clamp_value);
    }
  });
}
