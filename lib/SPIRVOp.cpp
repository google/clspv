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

#include "SPIRVOp.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"

#include "clspv/Option.h"

#include "Builtins.h"
#include "Constants.h"

namespace clspv {

using namespace llvm;

Instruction *InsertSPIRVOp(Instruction *Insert, spv::Op Opcode,
                           ArrayRef<Attribute::AttrKind> Attributes,
                           Type *RetType, ArrayRef<Value *> Args,
                           const MemoryEffects &MemEffects) {

  // Prepare mangled name
  std::string MangledName = clspv::SPIRVOpIntrinsicFunction();
  MangledName += ".";
  MangledName += std::to_string(Opcode);
  MangledName += ".";
  for (auto Arg : Args) {
    MangledName += Builtins::GetMangledTypeName(Arg->getType());
  }

  auto M = Insert->getModule();
  auto Int32Ty = Type::getInt32Ty(M->getContext());
  Function *func = M->getFunction(MangledName);
  if (!func) {
    // Create a function in the module
    SmallVector<Type *, 8> ArgTypes = {Int32Ty};
    for (auto Arg : Args) {
      ArgTypes.push_back(Arg->getType());
    }
    auto NewFType = FunctionType::get(RetType, ArgTypes, false);
    auto NewFTyC = M->getOrInsertFunction(MangledName, NewFType);
    func = cast<Function>(NewFTyC.getCallee());
    for (auto A : Attributes) {
      func->addFnAttr(A);
    }
    if (MemEffects != MemoryEffects::unknown())
      func->setMemoryEffects(MemEffects);
  }

  // Now call it with the values we were passed
  SmallVector<Value *, 8> ArgValues = {ConstantInt::get(Int32Ty, Opcode)};
  for (auto Arg : Args) {
    ArgValues.push_back(Arg);
  }

  Instruction *NewInst =
      CallInst::Create(func, ArgValues, "", Insert->getIterator());

  // Set the source location for the new instruction
  NewInst->setDebugLoc(Insert->getDebugLoc());

  return NewInst;
}

std::pair<Value *, Value *> InsertOpMulExtended(Instruction *InsertPoint,
                                                Value *a, Value *b,
                                                bool IsSigned, bool ExtractLo,
                                                bool Int64) {
  Type *Ty = a->getType();
  Type *RetTy = StructType::get(Ty->getContext(), {Ty, Ty});
  assert(Ty == b->getType());

  IRBuilder<> Builder(InsertPoint);

  if (!Option::HackMulExtended()) {
    spv::Op opcode = IsSigned ? spv::OpSMulExtended : spv::OpUMulExtended;

    auto Call = clspv::InsertSPIRVOp(InsertPoint, opcode, {}, RetTy, {a, b},
                                     MemoryEffects::none());
    Value *mul_lo = ExtractLo ? Builder.CreateExtractValue(Call, {0}) : nullptr;
    Value *mul_hi = Builder.CreateExtractValue(Call, {1});
    return {mul_lo, mul_hi};
  }

  unsigned int ScalarSizeInBits = Ty->getScalarSizeInBits();
  bool IsVector = Ty->isVectorTy();

  if (ScalarSizeInBits < 32 || (ScalarSizeInBits == 32 && Int64)) {
    /*
     * {mul_lo, mul_hi} = OpMulExtended(a, b, IsSigned) {
     *    S = SizeInBits(a)
     *    a_ext = ext2S(a, IsSigned)
     *    b_ext = ext2S(b, IsSigned)
     *    mul = a_ext * b_ext
     *    mul_lo = truncS(mul)
     *    mul_hi = truncS(mul >> S)
     *    return {mul_lo, mul_hi}
     * }
     */
    Type *TyTimes2 =
        Ty->getIntNTy(InsertPoint->getContext(), ScalarSizeInBits * 2);
    if (IsVector) {
      TyTimes2 = VectorType::get(TyTimes2, dyn_cast<VectorType>(Ty));
    }
    Value *aExtended, *bExtended;
    if (IsSigned) {
      aExtended = Builder.CreateSExt(a, TyTimes2);
      bExtended = Builder.CreateSExt(b, TyTimes2);
    } else {
      aExtended = Builder.CreateZExt(a, TyTimes2);
      bExtended = Builder.CreateZExt(b, TyTimes2);
    }
    auto mul = Builder.CreateMul(bExtended, aExtended);
    Value *mul_lo = ExtractLo ? Builder.CreateTrunc(mul, Ty) : nullptr;
    Value *mul_hi =
        Builder.CreateTrunc(Builder.CreateLShr(mul, ScalarSizeInBits), Ty);

    return {mul_lo, mul_hi};
  } else if (ScalarSizeInBits == 64 || (ScalarSizeInBits == 32 && !Int64)) {
    /*
     * {mul_lo, mul_hi} = OpMulExtended(a, b, IsSigned) {
     *   S = SizeInBits(a)
     *   hS = S / 2
     *   if (IsSigned) {
     *     res_neg = (a > 0) ^ (b > 0) = (a ^ b) < 0
     *     a = abs(a)
     *     b = abs(b)
     *   }
     *   a0 = trunchS(a)
     *   a1 = trunchS(a >> hS)
     *   b0 = trunchS(b)
     *   b1 = trunchS(b >> hS)
     *   {a0b0_0, a0b0_1} = zextS(OpUMulExtended(a0, b0))
     *   {a1b0_0, a1b0_1} = zextS(OpUMulExtended(a1, b0))
     *   {a0b1_0, a0b1_1} = zextS(OpUMulExtended(a0, b1))
     *   {a1b1_0, a1b1_1} = zextS(OpUMulExtended(a1, b1))
     *
     *   mul_lo_hi = a0b0_1 + a1b0_0 + a0b1_0
     *   carry_mul_lo_hi = mul_lo_hi >> hS
     *   mul_hi_lo = a1b1_0 + a1b0_1 + a0b1_1 + carry_mul_lo_hi
     *   mul_lo = a0b0_0 + mul_lo_hi << hS
     *   mul_hi = mul_hi_lo + a1b1_1 << hS
     *
     *   if (IsSigned) {
     *     mul_lo_xor = mul_lo ^ -1
     *     {mul_lo_inv, carry} = OpIAddCarry(mul_lo_xor, 1)
     *     mul_hi_inv = mul_hi ^ -1 + carry
     *     mul_lo = res_neg ? mul_lo_inv : mul_lo
     *     mul_hi = res_neg ? mul_hi_inv : mul_hi
     *   }
     *   return {mul_lo, mul_hi}
     * }
     */
    Type *TyDiv2 =
        Ty->getIntNTy(InsertPoint->getContext(), ScalarSizeInBits / 2);
    if (IsVector) {
      TyDiv2 = VectorType::get(TyDiv2, dyn_cast<VectorType>(Ty));
    }

    Value *res_neg;
    if (IsSigned) {
      // We want to work with unsigned value.
      // Convert everything to unsigned and remember the signed of the end
      // result.
      auto a_b_xor = Builder.CreateXor(a, b);
      res_neg = Builder.CreateICmpSLT(a_b_xor, ConstantInt::get(Ty, 0, true));

      auto F = InsertPoint->getFunction();
      auto abs =
          Intrinsic::getOrInsertDeclaration(F->getParent(), Intrinsic::abs, Ty);
      a = Builder.CreateCall(abs, {a, Builder.getInt1(false)});
      b = Builder.CreateCall(abs, {b, Builder.getInt1(false)});
    }

    auto a0 = Builder.CreateTrunc(a, TyDiv2);
    auto a1 = Builder.CreateTrunc(Builder.CreateLShr(a, ScalarSizeInBits / 2),
                                  TyDiv2);
    auto b0 = Builder.CreateTrunc(b, TyDiv2);
    auto b1 = Builder.CreateTrunc(Builder.CreateLShr(b, ScalarSizeInBits / 2),
                                  TyDiv2);

    auto [a0b0_lo, a0b0_hi] =
        InsertOpMulExtended(InsertPoint, a0, b0, false, true, true);
    auto [a1b0_lo, a1b0_hi] =
        InsertOpMulExtended(InsertPoint, a1, b0, false, true, true);
    auto [a0b1_lo, a0b1_hi] =
        InsertOpMulExtended(InsertPoint, a0, b1, false, true, true);
    auto [a1b1_lo, a1b1_hi] =
        InsertOpMulExtended(InsertPoint, a1, b1, false, true, true);
    auto a0b0_0 = Builder.CreateZExt(a0b0_lo, Ty);
    auto a0b0_1 = Builder.CreateZExt(a0b0_hi, Ty);
    auto a1b0_0 = Builder.CreateZExt(a1b0_lo, Ty);
    auto a1b0_1 = Builder.CreateZExt(a1b0_hi, Ty);
    auto a0b1_0 = Builder.CreateZExt(a0b1_lo, Ty);
    auto a0b1_1 = Builder.CreateZExt(a0b1_hi, Ty);
    auto a1b1_0 = Builder.CreateZExt(a1b1_lo, Ty);
    auto a1b1_1 = Builder.CreateZExt(a1b1_hi, Ty);

    auto mul_lo_hi =
        Builder.CreateAdd(Builder.CreateAdd(a0b0_1, a1b0_0), a0b1_0);
    auto carry_mul_lo_hi = Builder.CreateLShr(mul_lo_hi, ScalarSizeInBits / 2);
    auto mul_hi_lo = Builder.CreateAdd(
        Builder.CreateAdd(Builder.CreateAdd(a1b1_0, a1b0_1), a0b1_1),
        carry_mul_lo_hi);
    auto mul_lo = Builder.CreateAdd(
        a0b0_0, Builder.CreateShl(mul_lo_hi, ScalarSizeInBits / 2));
    auto mul_hi = Builder.CreateAdd(
        mul_hi_lo, Builder.CreateShl(a1b1_1, ScalarSizeInBits / 2));

    if (IsSigned) {
      // Apply the sign that we got from the previous if statement setting
      // res_neg.
      auto mul_lo_xor =
          Builder.CreateXor(mul_lo, Constant::getAllOnesValue(Ty));
      auto mul_lo_xor_add = InsertSPIRVOp(
          InsertPoint, spv::OpIAddCarry, {}, RetTy,
          {mul_lo_xor, ConstantInt::get(Ty, 1)}, MemoryEffects::none());
      auto mul_lo_inv = Builder.CreateExtractValue(mul_lo_xor_add, {0});
      auto carry = Builder.CreateExtractValue(mul_lo_xor_add, {1});
      auto mul_hi_inv = Builder.CreateAdd(
          carry, Builder.CreateXor(mul_hi, Constant::getAllOnesValue(Ty)));
      mul_lo = Builder.CreateSelect(res_neg, mul_lo_inv, mul_lo);
      mul_hi = Builder.CreateSelect(res_neg, mul_hi_inv, mul_hi);
    }

    return {mul_lo, mul_hi};
  } else {
    llvm_unreachable("Unexpected type for InsertOpMulExtended");
  }
}

} // namespace clspv
