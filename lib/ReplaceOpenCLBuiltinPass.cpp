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

#include <math.h>
#include <string>
#include <tuple>

#include "llvm/ADT/StringSwitch.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "spirv/1.0/spirv.hpp"

#include "clspv/AddressSpace.h"
#include "clspv/DescriptorMap.h"
#include "clspv/Option.h"

#include "Constants.h"
#include "Passes.h"
#include "SPIRVOp.h"
#include "Types.h"

using namespace llvm;

#define DEBUG_TYPE "ReplaceOpenCLBuiltin"

namespace {

struct ArgTypeInfo {
  enum class SignedNess { None, Unsigned, Signed };
  SignedNess signedness;
};

struct FunctionInfo {
  StringRef name;
  std::vector<ArgTypeInfo> argTypeInfos;

  bool isArgSigned(size_t arg) const {
    assert(argTypeInfos.size() > arg);
    return argTypeInfos[arg].signedness == ArgTypeInfo::SignedNess::Signed;
  }

  static FunctionInfo getFromMangledName(StringRef name) {
    FunctionInfo fi;
    if (!getFromMangledNameCheck(name, &fi)) {
      llvm_unreachable("Can't parse mangled function name!");
    }
    return fi;
  }

  static bool getFromMangledNameCheck(StringRef name, FunctionInfo *finfo) {
    if (!name.consume_front("_Z")) {
      return false;
    }
    size_t nameLen;
    if (name.consumeInteger(10, nameLen)) {
      return false;
    }

    finfo->name = name.take_front(nameLen);
    name = name.drop_front(nameLen);

    ArgTypeInfo prev_ti;

    while (name.size() != 0) {

      ArgTypeInfo ti;

      // Try parsing a vector prefix
      if (name.consume_front("Dv")) {
        int numElems;
        if (name.consumeInteger(10, numElems)) {
          return false;
        }

        if (!name.consume_front("_")) {
          return false;
        }
      }

      // Parse the base type
      if (name.consume_front("Dh")) {
        ti.signedness = ArgTypeInfo::SignedNess::None;
      } else {
        char typeCode = name.front();
        name = name.drop_front(1);
        switch (typeCode) {
        case 'c': // char
        case 'a': // signed char
        case 's': // short
        case 'i': // int
        case 'l': // long
          ti.signedness = ArgTypeInfo::SignedNess::Signed;
          break;
        case 'h': // unsigned char
        case 't': // unsigned short
        case 'j': // unsigned int
        case 'm': // unsigned long
          ti.signedness = ArgTypeInfo::SignedNess::Unsigned;
          break;
        case 'f':
          ti.signedness = ArgTypeInfo::SignedNess::None;
          break;
        case 'S':
          ti = prev_ti;
          if (!name.consume_front("_")) {
            return false;
          }
          break;
        default:
          return false;
        }
      }

      finfo->argTypeInfos.push_back(ti);

      prev_ti = ti;
    }

    return true;
  };
};

uint32_t clz(uint32_t v) {
  uint32_t r;
  uint32_t shift;

  r = (v > 0xFFFF) << 4;
  v >>= r;
  shift = (v > 0xFF) << 3;
  v >>= shift;
  r |= shift;
  shift = (v > 0xF) << 2;
  v >>= shift;
  r |= shift;
  shift = (v > 0x3) << 1;
  v >>= shift;
  r |= shift;
  r |= (v >> 1);

  return r;
}

Type *getBoolOrBoolVectorTy(LLVMContext &C, unsigned elements) {
  if (1 == elements) {
    return Type::getInt1Ty(C);
  } else {
    return VectorType::get(Type::getInt1Ty(C), elements);
  }
}

Type *getIntOrIntVectorTyForCast(LLVMContext &C, Type *Ty) {
  Type *IntTy = Type::getIntNTy(C, Ty->getScalarSizeInBits());
  if (Ty->isVectorTy()) {
    IntTy = VectorType::get(IntTy, Ty->getVectorNumElements());
  }
  return IntTy;
}

struct ReplaceOpenCLBuiltinPass final : public ModulePass {
  static char ID;
  ReplaceOpenCLBuiltinPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
  bool replaceAbs(Module &M);
  bool replaceAbsDiff(Module &M);
  bool replaceCopysign(Module &M);
  bool replaceRecip(Module &M);
  bool replaceDivide(Module &M);
  bool replaceDot(Module &M);
  bool replaceExp10(Module &M);
  bool replaceFmod(Module &M);
  bool replaceLog10(Module &M);
  bool replaceBarrier(Module &M);
  bool replaceMemFence(Module &M);
  bool replaceRelational(Module &M);
  bool replaceIsInfAndIsNan(Module &M);
  bool replaceIsFinite(Module &M);
  bool replaceAllAndAny(Module &M);
  bool replaceUpsample(Module &M);
  bool replaceRotate(Module &M);
  bool replaceConvert(Module &M);
  bool replaceMulHiMadHi(Module &M);
  bool replaceSelect(Module &M);
  bool replaceBitSelect(Module &M);
  bool replaceStepSmoothStep(Module &M);
  bool replaceSignbit(Module &M);
  bool replaceMadandMad24andMul24(Module &M);
  bool replaceVloadHalf(Module &M);
  bool replaceVloadHalf2(Module &M);
  bool replaceVloadHalf4(Module &M);
  bool replaceClspvVloadaHalf2(Module &M);
  bool replaceClspvVloadaHalf4(Module &M);
  bool replaceVstoreHalf(Module &M);
  bool replaceVstoreHalf2(Module &M);
  bool replaceVstoreHalf4(Module &M);
  bool replaceHalfReadImage(Module &M);
  bool replaceHalfWriteImage(Module &M);
  bool replaceUnsampledReadImage(Module &M);
  bool replaceSampledReadImageWithIntCoords(Module &M);
  bool replaceAtomics(Module &M);
  bool replaceCross(Module &M);
  bool replaceFract(Module &M);
  bool replaceVload(Module &M);
  bool replaceVstore(Module &M);
};
} // namespace

char ReplaceOpenCLBuiltinPass::ID = 0;
INITIALIZE_PASS(ReplaceOpenCLBuiltinPass, "ReplaceOpenCLBuiltin",
                "Replace OpenCL Builtins Pass", false, false)

namespace clspv {
ModulePass *createReplaceOpenCLBuiltinPass() {
  return new ReplaceOpenCLBuiltinPass();
}
} // namespace clspv

bool ReplaceOpenCLBuiltinPass::runOnModule(Module &M) {
  bool Changed = false;

  Changed |= replaceAbs(M);
  Changed |= replaceAbsDiff(M);
  Changed |= replaceCopysign(M);
  Changed |= replaceRecip(M);
  Changed |= replaceDivide(M);
  Changed |= replaceDot(M);
  Changed |= replaceExp10(M);
  Changed |= replaceFmod(M);
  Changed |= replaceLog10(M);
  Changed |= replaceBarrier(M);
  Changed |= replaceMemFence(M);
  Changed |= replaceRelational(M);
  Changed |= replaceIsInfAndIsNan(M);
  Changed |= replaceIsFinite(M);
  Changed |= replaceAllAndAny(M);
  Changed |= replaceUpsample(M);
  Changed |= replaceRotate(M);
  Changed |= replaceConvert(M);
  Changed |= replaceMulHiMadHi(M);
  Changed |= replaceSelect(M);
  Changed |= replaceBitSelect(M);
  Changed |= replaceStepSmoothStep(M);
  Changed |= replaceSignbit(M);
  Changed |= replaceMadandMad24andMul24(M);
  Changed |= replaceVloadHalf(M);
  Changed |= replaceVloadHalf2(M);
  Changed |= replaceVloadHalf4(M);
  Changed |= replaceClspvVloadaHalf2(M);
  Changed |= replaceClspvVloadaHalf4(M);
  Changed |= replaceVstoreHalf(M);
  Changed |= replaceVstoreHalf2(M);
  Changed |= replaceVstoreHalf4(M);
  // Replace the half image builtins before handling other image builtins.
  Changed |= replaceHalfReadImage(M);
  Changed |= replaceHalfWriteImage(M);
  // Replace unsampled reads before converting sampled read coordinates.
  Changed |= replaceUnsampledReadImage(M);
  Changed |= replaceSampledReadImageWithIntCoords(M);
  Changed |= replaceAtomics(M);
  Changed |= replaceCross(M);
  Changed |= replaceFract(M);
  Changed |= replaceVload(M);
  Changed |= replaceVstore(M);

  return Changed;
}

bool replaceCallsWithValue(Module &M, std::vector<const char *> Names,
                           std::function<Value *(CallInst *)> Replacer) {

  bool Changed = false;

  for (auto Name : Names) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          auto NewValue = Replacer(CI);

          if (NewValue != nullptr) {
            CI->replaceAllUsesWith(NewValue);
          }

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceAbs(Module &M) {

  std::vector<const char *> Names = {
      "_Z3absh", "_Z3absDv2_h", "_Z3absDv3_h", "_Z3absDv4_h",
      "_Z3abst", "_Z3absDv2_t", "_Z3absDv3_t", "_Z3absDv4_t",
      "_Z3absj", "_Z3absDv2_j", "_Z3absDv3_j", "_Z3absDv4_j",
      "_Z3absm", "_Z3absDv2_m", "_Z3absDv3_m", "_Z3absDv4_m",
  };

  return replaceCallsWithValue(M, Names,
                               [](CallInst *CI) { return CI->getOperand(0); });
}

bool ReplaceOpenCLBuiltinPass::replaceAbsDiff(Module &M) {

  std::vector<const char *> Names = {
      "_Z8abs_diffcc",      "_Z8abs_diffDv2_cS_", "_Z8abs_diffDv3_cS_",
      "_Z8abs_diffDv4_cS_", "_Z8abs_diffhh",      "_Z8abs_diffDv2_hS_",
      "_Z8abs_diffDv3_hS_", "_Z8abs_diffDv4_hS_", "_Z8abs_diffss",
      "_Z8abs_diffDv2_sS_", "_Z8abs_diffDv3_sS_", "_Z8abs_diffDv4_sS_",
      "_Z8abs_difftt",      "_Z8abs_diffDv2_tS_", "_Z8abs_diffDv3_tS_",
      "_Z8abs_diffDv4_tS_", "_Z8abs_diffii",      "_Z8abs_diffDv2_iS_",
      "_Z8abs_diffDv3_iS_", "_Z8abs_diffDv4_iS_", "_Z8abs_diffjj",
      "_Z8abs_diffDv2_jS_", "_Z8abs_diffDv3_jS_", "_Z8abs_diffDv4_jS_",
      "_Z8abs_diffll",      "_Z8abs_diffDv2_lS_", "_Z8abs_diffDv3_lS_",
      "_Z8abs_diffDv4_lS_", "_Z8abs_diffmm",      "_Z8abs_diffDv2_mS_",
      "_Z8abs_diffDv3_mS_", "_Z8abs_diffDv4_mS_",
  };

  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    auto XValue = CI->getOperand(0);
    auto YValue = CI->getOperand(1);

    IRBuilder<> Builder(CI);
    auto XmY = Builder.CreateSub(XValue, YValue);
    auto YmX = Builder.CreateSub(YValue, XValue);

    Value *Cmp;
    auto F = CI->getCalledFunction();
    auto finfo = FunctionInfo::getFromMangledName(F->getName());
    if (finfo.isArgSigned(0)) {
      Cmp = Builder.CreateICmpSGT(YValue, XValue);
    } else {
      Cmp = Builder.CreateICmpUGT(YValue, XValue);
    }

    return Builder.CreateSelect(Cmp, YmX, XmY);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceCopysign(Module &M) {

  std::vector<const char *> Names = {
      "_Z8copysignff",
      "_Z8copysignDv2_fS_",
      "_Z8copysignDv3_fS_",
      "_Z8copysignDv4_fS_",
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    auto XValue = CI->getOperand(0);
    auto YValue = CI->getOperand(1);

    auto Ty = XValue->getType();

    Type *IntTy = Type::getIntNTy(M.getContext(), Ty->getScalarSizeInBits());
    if (Ty->isVectorTy()) {
      IntTy = VectorType::get(IntTy, Ty->getVectorNumElements());
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

bool ReplaceOpenCLBuiltinPass::replaceRecip(Module &M) {

  std::vector<const char *> Names = {
      "_Z10half_recipf",       "_Z12native_recipf",     "_Z10half_recipDv2_f",
      "_Z12native_recipDv2_f", "_Z10half_recipDv3_f",   "_Z12native_recipDv3_f",
      "_Z10half_recipDv4_f",   "_Z12native_recipDv4_f",
  };

  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    // Recip has one arg.
    auto Arg = CI->getOperand(0);
    auto Cst1 = ConstantFP::get(Arg->getType(), 1.0);
    return BinaryOperator::Create(Instruction::FDiv, Cst1, Arg, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceDivide(Module &M) {

  std::vector<const char *> Names = {
      "_Z11half_divideff",      "_Z13native_divideff",
      "_Z11half_divideDv2_fS_", "_Z13native_divideDv2_fS_",
      "_Z11half_divideDv3_fS_", "_Z13native_divideDv3_fS_",
      "_Z11half_divideDv4_fS_", "_Z13native_divideDv4_fS_",
  };

  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);
    return BinaryOperator::Create(Instruction::FDiv, Op0, Op1, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceDot(Module &M) {

  std::vector<const char *> Names = {
      "_Z3dotff",
      "_Z3dotDv2_fS_",
      "_Z3dotDv3_fS_",
      "_Z3dotDv4_fS_",
  };

  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);

    Value *V;
    if (Op0->getType()->isVectorTy()) {
      V = clspv::InsertSPIRVOp(CI, spv::OpDot, {Attribute::ReadNone},
                               CI->getType(), {Op0, Op1});
    } else {
      V = BinaryOperator::Create(Instruction::FMul, Op0, Op1, "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceExp10(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char *> Map = {
      {"_Z5exp10f", "_Z3expf"},
      {"_Z10half_exp10f", "_Z8half_expf"},
      {"_Z12native_exp10f", "_Z10native_expf"},
      {"_Z5exp10Dv2_f", "_Z3expDv2_f"},
      {"_Z10half_exp10Dv2_f", "_Z8half_expDv2_f"},
      {"_Z12native_exp10Dv2_f", "_Z10native_expDv2_f"},
      {"_Z5exp10Dv3_f", "_Z3expDv3_f"},
      {"_Z10half_exp10Dv3_f", "_Z8half_expDv3_f"},
      {"_Z12native_exp10Dv3_f", "_Z10native_expDv3_f"},
      {"_Z5exp10Dv4_f", "_Z3expDv4_f"},
      {"_Z10half_exp10Dv4_f", "_Z8half_expDv4_f"},
      {"_Z12native_exp10Dv4_f", "_Z10native_expDv4_f"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto NewF = M.getOrInsertFunction(Pair.second, F->getFunctionType());

          auto Arg = CI->getOperand(0);

          // Constant of the natural log of 10 (ln(10)).
          const double Ln10 =
              2.302585092994045684017991454684364207601101488628772976033;

          auto Mul = BinaryOperator::Create(
              Instruction::FMul, ConstantFP::get(Arg->getType(), Ln10), Arg, "",
              CI);

          auto NewCI = CallInst::Create(NewF, Mul, "", CI);

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceFmod(Module &M) {

  std::vector<const char *> Names = {
      "_Z4fmodff",
      "_Z4fmodDv2_fS_",
      "_Z4fmodDv3_fS_",
      "_Z4fmodDv4_fS_",
  };

  // OpenCL fmod(x,y) is x - y * trunc(x/y)
  // The sign for a non-zero result is taken from x.
  // (Try an example.)
  // So translate to FRem
  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);
    return BinaryOperator::Create(Instruction::FRem, Op0, Op1, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceLog10(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char *> Map = {
      {"_Z5log10f", "_Z3logf"},
      {"_Z10half_log10f", "_Z8half_logf"},
      {"_Z12native_log10f", "_Z10native_logf"},
      {"_Z5log10Dv2_f", "_Z3logDv2_f"},
      {"_Z10half_log10Dv2_f", "_Z8half_logDv2_f"},
      {"_Z12native_log10Dv2_f", "_Z10native_logDv2_f"},
      {"_Z5log10Dv3_f", "_Z3logDv3_f"},
      {"_Z10half_log10Dv3_f", "_Z8half_logDv3_f"},
      {"_Z12native_log10Dv3_f", "_Z10native_logDv3_f"},
      {"_Z5log10Dv4_f", "_Z3logDv4_f"},
      {"_Z10half_log10Dv4_f", "_Z8half_logDv4_f"},
      {"_Z12native_log10Dv4_f", "_Z10native_logDv4_f"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto NewF = M.getOrInsertFunction(Pair.second, F->getFunctionType());

          auto Arg = CI->getOperand(0);

          // Constant of the reciprocal of the natural log of 10 (ln(10)).
          const double Ln10 =
              0.434294481903251827651128918916605082294397005803666566114;

          auto NewCI = CallInst::Create(NewF, Arg, "", CI);

          auto Mul = BinaryOperator::Create(
              Instruction::FMul, ConstantFP::get(Arg->getType(), Ln10), NewCI,
              "", CI);

          CI->replaceAllUsesWith(Mul);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceBarrier(Module &M) {

  enum { CLK_LOCAL_MEM_FENCE = 0x01, CLK_GLOBAL_MEM_FENCE = 0x02 };

  const std::vector<const char *> Names = {"_Z7barrierj",
                                           // OpenCL 2.0 alias for barrier.
                                           "_Z18work_group_barrierj"};

  return replaceCallsWithValue(M, Names, [](CallInst *CI) {
    auto Arg = CI->getOperand(0);

    // We need to map the OpenCL constants to the SPIR-V equivalents.
    const auto LocalMemFence =
        ConstantInt::get(Arg->getType(), CLK_LOCAL_MEM_FENCE);
    const auto GlobalMemFence =
        ConstantInt::get(Arg->getType(), CLK_GLOBAL_MEM_FENCE);
    const auto ConstantSequentiallyConsistent = ConstantInt::get(
        Arg->getType(), spv::MemorySemanticsSequentiallyConsistentMask);
    const auto ConstantScopeDevice =
        ConstantInt::get(Arg->getType(), spv::ScopeDevice);
    const auto ConstantScopeWorkgroup =
        ConstantInt::get(Arg->getType(), spv::ScopeWorkgroup);

    // Map CLK_LOCAL_MEM_FENCE to MemorySemanticsWorkgroupMemoryMask.
    const auto LocalMemFenceMask =
        BinaryOperator::Create(Instruction::And, LocalMemFence, Arg, "", CI);
    const auto WorkgroupShiftAmount =
        clz(spv::MemorySemanticsWorkgroupMemoryMask) - clz(CLK_LOCAL_MEM_FENCE);
    const auto MemorySemanticsWorkgroup = BinaryOperator::Create(
        Instruction::Shl, LocalMemFenceMask,
        ConstantInt::get(Arg->getType(), WorkgroupShiftAmount), "", CI);

    // Map CLK_GLOBAL_MEM_FENCE to MemorySemanticsUniformMemoryMask.
    const auto GlobalMemFenceMask =
        BinaryOperator::Create(Instruction::And, GlobalMemFence, Arg, "", CI);
    const auto UniformShiftAmount =
        clz(spv::MemorySemanticsUniformMemoryMask) - clz(CLK_GLOBAL_MEM_FENCE);
    const auto MemorySemanticsUniform = BinaryOperator::Create(
        Instruction::Shl, GlobalMemFenceMask,
        ConstantInt::get(Arg->getType(), UniformShiftAmount), "", CI);

    // And combine the above together, also adding in
    // MemorySemanticsSequentiallyConsistentMask.
    auto MemorySemantics =
        BinaryOperator::Create(Instruction::Or, MemorySemanticsWorkgroup,
                               ConstantSequentiallyConsistent, "", CI);
    MemorySemantics = BinaryOperator::Create(Instruction::Or, MemorySemantics,
                                             MemorySemanticsUniform, "", CI);

    // For Memory Scope if we used CLK_GLOBAL_MEM_FENCE, we need to use
    // Device Scope, otherwise Workgroup Scope.
    const auto Cmp =
        CmpInst::Create(Instruction::ICmp, CmpInst::ICMP_EQ, GlobalMemFenceMask,
                        GlobalMemFence, "", CI);
    const auto MemoryScope = SelectInst::Create(Cmp, ConstantScopeDevice,
                                                ConstantScopeWorkgroup, "", CI);

    // Lastly, the Execution Scope is always Workgroup Scope.
    const auto ExecutionScope = ConstantScopeWorkgroup;

    return clspv::InsertSPIRVOp(CI, spv::OpControlBarrier,
                                {Attribute::NoDuplicate}, CI->getType(),
                                {ExecutionScope, MemoryScope, MemorySemantics});
  });
}

bool ReplaceOpenCLBuiltinPass::replaceMemFence(Module &M) {
  bool Changed = false;

  enum { CLK_LOCAL_MEM_FENCE = 0x01, CLK_GLOBAL_MEM_FENCE = 0x02 };

  using Tuple = std::tuple<spv::Op, unsigned>;
  const std::map<const char *, Tuple> Map = {
      {"_Z9mem_fencej", Tuple(spv::OpMemoryBarrier,
                              spv::MemorySemanticsSequentiallyConsistentMask)},
      {"_Z14read_mem_fencej",
       Tuple(spv::OpMemoryBarrier, spv::MemorySemanticsAcquireMask)},
      {"_Z15write_mem_fencej",
       Tuple(spv::OpMemoryBarrier, spv::MemorySemanticsReleaseMask)}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          auto Arg = CI->getOperand(0);

          // We need to map the OpenCL constants to the SPIR-V equivalents.
          const auto LocalMemFence =
              ConstantInt::get(Arg->getType(), CLK_LOCAL_MEM_FENCE);
          const auto GlobalMemFence =
              ConstantInt::get(Arg->getType(), CLK_GLOBAL_MEM_FENCE);
          const auto ConstantMemorySemantics =
              ConstantInt::get(Arg->getType(), std::get<1>(Pair.second));
          const auto ConstantScopeDevice =
              ConstantInt::get(Arg->getType(), spv::ScopeDevice);

          // Map CLK_LOCAL_MEM_FENCE to MemorySemanticsWorkgroupMemoryMask.
          const auto LocalMemFenceMask = BinaryOperator::Create(
              Instruction::And, LocalMemFence, Arg, "", CI);
          const auto WorkgroupShiftAmount =
              clz(spv::MemorySemanticsWorkgroupMemoryMask) -
              clz(CLK_LOCAL_MEM_FENCE);
          const auto MemorySemanticsWorkgroup = BinaryOperator::Create(
              Instruction::Shl, LocalMemFenceMask,
              ConstantInt::get(Arg->getType(), WorkgroupShiftAmount), "", CI);

          // Map CLK_GLOBAL_MEM_FENCE to MemorySemanticsUniformMemoryMask.
          const auto GlobalMemFenceMask = BinaryOperator::Create(
              Instruction::And, GlobalMemFence, Arg, "", CI);
          const auto UniformShiftAmount =
              clz(spv::MemorySemanticsUniformMemoryMask) -
              clz(CLK_GLOBAL_MEM_FENCE);
          const auto MemorySemanticsUniform = BinaryOperator::Create(
              Instruction::Shl, GlobalMemFenceMask,
              ConstantInt::get(Arg->getType(), UniformShiftAmount), "", CI);

          // And combine the above together, also adding in
          // MemorySemanticsSequentiallyConsistentMask.
          auto MemorySemantics =
              BinaryOperator::Create(Instruction::Or, MemorySemanticsWorkgroup,
                                     ConstantMemorySemantics, "", CI);
          MemorySemantics = BinaryOperator::Create(
              Instruction::Or, MemorySemantics, MemorySemanticsUniform, "", CI);

          // Memory Scope is always device.
          const auto MemoryScope = ConstantScopeDevice;

          const auto SPIRVOp = std::get<0>(Pair.second);
          auto NewCI = clspv::InsertSPIRVOp(CI, SPIRVOp, {}, CI->getType(),
                                            {MemoryScope, MemorySemantics});

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceRelational(Module &M) {
  bool Changed = false;

  const std::map<const char *, std::pair<CmpInst::Predicate, int32_t>> Map = {
      {"_Z7isequalff", {CmpInst::FCMP_OEQ, 1}},
      {"_Z7isequalDv2_fS_", {CmpInst::FCMP_OEQ, -1}},
      {"_Z7isequalDv3_fS_", {CmpInst::FCMP_OEQ, -1}},
      {"_Z7isequalDv4_fS_", {CmpInst::FCMP_OEQ, -1}},
      {"_Z9isgreaterff", {CmpInst::FCMP_OGT, 1}},
      {"_Z9isgreaterDv2_fS_", {CmpInst::FCMP_OGT, -1}},
      {"_Z9isgreaterDv3_fS_", {CmpInst::FCMP_OGT, -1}},
      {"_Z9isgreaterDv4_fS_", {CmpInst::FCMP_OGT, -1}},
      {"_Z14isgreaterequalff", {CmpInst::FCMP_OGE, 1}},
      {"_Z14isgreaterequalDv2_fS_", {CmpInst::FCMP_OGE, -1}},
      {"_Z14isgreaterequalDv3_fS_", {CmpInst::FCMP_OGE, -1}},
      {"_Z14isgreaterequalDv4_fS_", {CmpInst::FCMP_OGE, -1}},
      {"_Z6islessff", {CmpInst::FCMP_OLT, 1}},
      {"_Z6islessDv2_fS_", {CmpInst::FCMP_OLT, -1}},
      {"_Z6islessDv3_fS_", {CmpInst::FCMP_OLT, -1}},
      {"_Z6islessDv4_fS_", {CmpInst::FCMP_OLT, -1}},
      {"_Z11islessequalff", {CmpInst::FCMP_OLE, 1}},
      {"_Z11islessequalDv2_fS_", {CmpInst::FCMP_OLE, -1}},
      {"_Z11islessequalDv3_fS_", {CmpInst::FCMP_OLE, -1}},
      {"_Z11islessequalDv4_fS_", {CmpInst::FCMP_OLE, -1}},
      {"_Z10isnotequalff", {CmpInst::FCMP_ONE, 1}},
      {"_Z10isnotequalDv2_fS_", {CmpInst::FCMP_ONE, -1}},
      {"_Z10isnotequalDv3_fS_", {CmpInst::FCMP_ONE, -1}},
      {"_Z10isnotequalDv4_fS_", {CmpInst::FCMP_ONE, -1}},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The predicate to use in the CmpInst.
          auto Predicate = Pair.second.first;

          // The value to return for true.
          auto TrueValue =
              ConstantInt::getSigned(CI->getType(), Pair.second.second);

          // The value to return for false.
          auto FalseValue = Constant::getNullValue(CI->getType());

          auto Arg1 = CI->getOperand(0);
          auto Arg2 = CI->getOperand(1);

          const auto Cmp =
              CmpInst::Create(Instruction::FCmp, Predicate, Arg1, Arg2, "", CI);

          const auto Select =
              SelectInst::Create(Cmp, TrueValue, FalseValue, "", CI);

          CI->replaceAllUsesWith(Select);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceIsInfAndIsNan(Module &M) {
  bool Changed = false;

  const std::map<const char *, std::pair<spv::Op, int32_t>> Map = {
      {"_Z5isinff", {spv::OpIsInf, 1}},
      {"_Z5isinfDv2_f", {spv::OpIsInf, -1}},
      {"_Z5isinfDv3_f", {spv::OpIsInf, -1}},
      {"_Z5isinfDv4_f", {spv::OpIsInf, -1}},
      {"_Z5isnanf", {spv::OpIsNan, 1}},
      {"_Z5isnanDv2_f", {spv::OpIsNan, -1}},
      {"_Z5isnanDv3_f", {spv::OpIsNan, -1}},
      {"_Z5isnanDv4_f", {spv::OpIsNan, -1}},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          const auto CITy = CI->getType();

          auto SPIRVOp = Pair.second.first;

          // The value to return for true.
          auto TrueValue = ConstantInt::getSigned(CITy, Pair.second.second);

          // The value to return for false.
          auto FalseValue = Constant::getNullValue(CITy);

          const auto CorrespondingBoolTy = getBoolOrBoolVectorTy(
              M.getContext(),
              CITy->isVectorTy() ? CITy->getVectorNumElements() : 1);

          auto NewCI =
              clspv::InsertSPIRVOp(CI, SPIRVOp, {Attribute::ReadNone},
                                   CorrespondingBoolTy, {CI->getOperand(0)});

          const auto Select =
              SelectInst::Create(NewCI, TrueValue, FalseValue, "", CI);

          CI->replaceAllUsesWith(Select);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceIsFinite(Module &M) {
  std::vector<const char *> Names = {
      "_Z8isfiniteh",     "_Z8isfiniteDv2_h", "_Z8isfiniteDv3_h",
      "_Z8isfiniteDv4_h", "_Z8isfinitef",     "_Z8isfiniteDv2_f",
      "_Z8isfiniteDv3_f", "_Z8isfiniteDv4_f", "_Z8isfinited",
      "_Z8isfiniteDv2_d", "_Z8isfiniteDv3_d", "_Z8isfiniteDv4_d",
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    auto &C = M.getContext();
    auto Val = CI->getOperand(0);
    auto ValTy = Val->getType();
    auto RetTy = CI->getType();

    // Get a suitable integer type to represent the number
    auto IntTy = getIntOrIntVectorTyForCast(C, ValTy);

    // Create Mask
    auto ScalarSize = ValTy->getScalarSizeInBits();
    Value *InfMask;
    switch (ScalarSize) {
    case 16:
      InfMask = ConstantInt::get(IntTy, 0x7C00U);
      break;
    case 32:
      InfMask = ConstantInt::get(IntTy, 0x7F800000U);
      break;
    case 64:
      InfMask = ConstantInt::get(IntTy, 0x7FF0000000000000ULL);
      break;
    default:
      llvm_unreachable("Unsupported floating-point type");
    }

    IRBuilder<> Builder(CI);

    // Bitcast to int
    auto ValInt = Builder.CreateBitCast(Val, IntTy);

    // Mask and compare
    auto InfBits = Builder.CreateAnd(InfMask, ValInt);
    auto Cmp = Builder.CreateICmp(CmpInst::ICMP_EQ, InfBits, InfMask);

    auto RetFalse = ConstantInt::get(RetTy, 0);
    Value *RetTrue;
    if (ValTy->isVectorTy()) {
      RetTrue = ConstantInt::getSigned(RetTy, -1);
    } else {
      RetTrue = ConstantInt::get(RetTy, 1);
    }
    return Builder.CreateSelect(Cmp, RetFalse, RetTrue);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAllAndAny(Module &M) {
  bool Changed = false;

  const std::map<const char *, spv::Op> Map = {
      // all
      {"_Z3allc", spv::OpNop},
      {"_Z3allDv2_c", spv::OpAll},
      {"_Z3allDv3_c", spv::OpAll},
      {"_Z3allDv4_c", spv::OpAll},
      {"_Z3alls", spv::OpNop},
      {"_Z3allDv2_s", spv::OpAll},
      {"_Z3allDv3_s", spv::OpAll},
      {"_Z3allDv4_s", spv::OpAll},
      {"_Z3alli", spv::OpNop},
      {"_Z3allDv2_i", spv::OpAll},
      {"_Z3allDv3_i", spv::OpAll},
      {"_Z3allDv4_i", spv::OpAll},
      {"_Z3alll", spv::OpNop},
      {"_Z3allDv2_l", spv::OpAll},
      {"_Z3allDv3_l", spv::OpAll},
      {"_Z3allDv4_l", spv::OpAll},

      // any
      {"_Z3anyc", spv::OpNop},
      {"_Z3anyDv2_c", spv::OpAny},
      {"_Z3anyDv3_c", spv::OpAny},
      {"_Z3anyDv4_c", spv::OpAny},
      {"_Z3anys", spv::OpNop},
      {"_Z3anyDv2_s", spv::OpAny},
      {"_Z3anyDv3_s", spv::OpAny},
      {"_Z3anyDv4_s", spv::OpAny},
      {"_Z3anyi", spv::OpNop},
      {"_Z3anyDv2_i", spv::OpAny},
      {"_Z3anyDv3_i", spv::OpAny},
      {"_Z3anyDv4_i", spv::OpAny},
      {"_Z3anyl", spv::OpNop},
      {"_Z3anyDv2_l", spv::OpAny},
      {"_Z3anyDv3_l", spv::OpAny},
      {"_Z3anyDv4_l", spv::OpAny},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          auto Arg = CI->getOperand(0);

          Value *V;

          // If the argument is a 32-bit int, just use a shift
          if (Arg->getType() == Type::getInt32Ty(M.getContext())) {
            V = BinaryOperator::Create(Instruction::LShr, Arg,
                                       ConstantInt::get(Arg->getType(), 31), "",
                                       CI);
          } else {
            // The value for zero to compare against.
            const auto ZeroValue = Constant::getNullValue(Arg->getType());

            // The value to return for true.
            const auto TrueValue = ConstantInt::get(CI->getType(), 1);

            // The value to return for false.
            const auto FalseValue = Constant::getNullValue(CI->getType());

            const auto Cmp = CmpInst::Create(
                Instruction::ICmp, CmpInst::ICMP_SLT, Arg, ZeroValue, "", CI);

            Value *SelectSource;

            // If we have a function to call, call it!
            const auto SPIRVOp = Pair.second;

            if (SPIRVOp != spv::OpNop) {

              const auto BoolTy = Type::getInt1Ty(M.getContext());

              const auto NewCI = clspv::InsertSPIRVOp(
                  CI, SPIRVOp, {Attribute::ReadNone}, BoolTy, {Cmp});
              SelectSource = NewCI;

            } else {
              SelectSource = Cmp;
            }

            V = SelectInst::Create(SelectSource, TrueValue, FalseValue, "", CI);
          }

          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceUpsample(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    // Skip symbols whose name doesn't match
    if (!SymVal.getKey().startswith("_Z8upsample")) {
      continue;
    }
    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          // Get arguments
          auto HiValue = CI->getOperand(0);
          auto LoValue = CI->getOperand(1);

          // Don't touch overloads that aren't in OpenCL C
          auto HiType = HiValue->getType();
          auto LoType = LoValue->getType();

          if (HiType != LoType) {
            continue;
          }

          if (!HiType->isIntOrIntVectorTy()) {
            continue;
          }

          if (HiType->getScalarSizeInBits() * 2 !=
              CI->getType()->getScalarSizeInBits()) {
            continue;
          }

          if ((HiType->getScalarSizeInBits() != 8) &&
              (HiType->getScalarSizeInBits() != 16) &&
              (HiType->getScalarSizeInBits() != 32)) {
            continue;
          }

          if (HiType->isVectorTy()) {
            if ((HiType->getVectorNumElements() != 2) &&
                (HiType->getVectorNumElements() != 3) &&
                (HiType->getVectorNumElements() != 4) &&
                (HiType->getVectorNumElements() != 8) &&
                (HiType->getVectorNumElements() != 16)) {
              continue;
            }
          }

          // Convert both operands to the result type
          auto HiCast =
              CastInst::CreateZExtOrBitCast(HiValue, CI->getType(), "", CI);
          auto LoCast =
              CastInst::CreateZExtOrBitCast(LoValue, CI->getType(), "", CI);

          // Shift high operand
          auto ShiftAmount =
              ConstantInt::get(CI->getType(), HiType->getScalarSizeInBits());
          auto HiShifted = BinaryOperator::Create(Instruction::Shl, HiCast,
                                                  ShiftAmount, "", CI);

          // OR both results
          Value *V = BinaryOperator::Create(Instruction::Or, HiShifted, LoCast,
                                            "", CI);

          // Replace call with the expression
          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceRotate(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    // Skip symbols whose name doesn't match
    if (!SymVal.getKey().startswith("_Z6rotate")) {
      continue;
    }
    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          // Get arguments
          auto SrcValue = CI->getOperand(0);
          auto RotAmount = CI->getOperand(1);

          // Don't touch overloads that aren't in OpenCL C
          auto SrcType = SrcValue->getType();
          auto RotType = RotAmount->getType();

          if ((SrcType != RotType) || (CI->getType() != SrcType)) {
            continue;
          }

          if (!SrcType->isIntOrIntVectorTy()) {
            continue;
          }

          if ((SrcType->getScalarSizeInBits() != 8) &&
              (SrcType->getScalarSizeInBits() != 16) &&
              (SrcType->getScalarSizeInBits() != 32) &&
              (SrcType->getScalarSizeInBits() != 64)) {
            continue;
          }

          if (SrcType->isVectorTy()) {
            if ((SrcType->getVectorNumElements() != 2) &&
                (SrcType->getVectorNumElements() != 3) &&
                (SrcType->getVectorNumElements() != 4) &&
                (SrcType->getVectorNumElements() != 8) &&
                (SrcType->getVectorNumElements() != 16)) {
              continue;
            }
          }

          // The approach used is to shift the top bits down, the bottom bits up
          // and OR the two shifted values.

          // The rotation amount is to be treated modulo the element size.
          // Since SPIR-V shift ops don't support this, let's apply the
          // modulo ahead of shifting. The element size is always a power of
          // two so we can just AND with a mask.
          auto ModMask =
              ConstantInt::get(SrcType, SrcType->getScalarSizeInBits() - 1);
          RotAmount = BinaryOperator::Create(Instruction::And, RotAmount,
                                             ModMask, "", CI);

          // Let's calc the amount by which to shift top bits down
          auto ScalarSize =
              ConstantInt::get(SrcType, SrcType->getScalarSizeInBits());
          auto DownAmount = BinaryOperator::Create(Instruction::Sub, ScalarSize,
                                                   RotAmount, "", CI);

          // Now shift the bottom bits up and the top bits down
          auto LoRotated = BinaryOperator::Create(Instruction::Shl, SrcValue,
                                                  RotAmount, "", CI);
          auto HiRotated = BinaryOperator::Create(Instruction::LShr, SrcValue,
                                                  DownAmount, "", CI);

          // Finally OR the two shifted values
          Value *V = BinaryOperator::Create(Instruction::Or, LoRotated,
                                            HiRotated, "", CI);

          // Replace call with the expression
          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceConvert(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {

    // Skip symbols whose name obviously doesn't match
    if (!SymVal.getKey().contains("convert_")) {
      continue;
    }

    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {

      // Get info from the mangled name
      FunctionInfo finfo;
      bool parsed = FunctionInfo::getFromMangledNameCheck(F->getName(), &finfo);

      // All functions of interest are handled by our mangled name parser
      if (!parsed) {
        continue;
      }

      // Move on if this isn't a call to convert_
      if (!finfo.name.startswith("convert_")) {
        continue;
      }

      // Extract the destination type from the function name
      StringRef DstTypeName = finfo.name;
      DstTypeName.consume_front("convert_");

      auto DstSignedNess =
          StringSwitch<ArgTypeInfo::SignedNess>(DstTypeName)
              .StartsWith("char", ArgTypeInfo::SignedNess::Signed)
              .StartsWith("short", ArgTypeInfo::SignedNess::Signed)
              .StartsWith("int", ArgTypeInfo::SignedNess::Signed)
              .StartsWith("long", ArgTypeInfo::SignedNess::Signed)
              .StartsWith("uchar", ArgTypeInfo::SignedNess::Unsigned)
              .StartsWith("ushort", ArgTypeInfo::SignedNess::Unsigned)
              .StartsWith("uint", ArgTypeInfo::SignedNess::Unsigned)
              .StartsWith("ulong", ArgTypeInfo::SignedNess::Unsigned)
              .Default(ArgTypeInfo::SignedNess::None);

      bool DstIsSigned = DstSignedNess == ArgTypeInfo::SignedNess::Signed;
      bool SrcIsSigned = finfo.isArgSigned(0);

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          // Get arguments
          auto SrcValue = CI->getOperand(0);

          // Don't touch overloads that aren't in OpenCL C
          auto SrcType = SrcValue->getType();
          auto DstType = CI->getType();

          if ((SrcType->isVectorTy() && !DstType->isVectorTy()) ||
              (!SrcType->isVectorTy() && DstType->isVectorTy())) {
            continue;
          }

          if (SrcType->isVectorTy()) {

            if (SrcType->getVectorNumElements() !=
                DstType->getVectorNumElements()) {
              continue;
            }

            if ((SrcType->getVectorNumElements() != 2) &&
                (SrcType->getVectorNumElements() != 3) &&
                (SrcType->getVectorNumElements() != 4) &&
                (SrcType->getVectorNumElements() != 8) &&
                (SrcType->getVectorNumElements() != 16)) {
              continue;
            }
          }

          bool SrcIsFloat = SrcType->getScalarType()->isFloatingPointTy();
          bool DstIsFloat = DstType->getScalarType()->isFloatingPointTy();

          bool SrcIsInt = SrcType->isIntOrIntVectorTy();
          bool DstIsInt = DstType->isIntOrIntVectorTy();

          Value *V;
          if (SrcType == DstType && DstIsSigned == SrcIsSigned) {
            // Unnecessary cast operation.
            V = SrcValue;
          } else if (SrcIsFloat && DstIsFloat) {
            V = CastInst::CreateFPCast(SrcValue, DstType, "", CI);
          } else if (SrcIsFloat && DstIsInt) {
            if (DstIsSigned) {
              V = CastInst::Create(Instruction::FPToSI, SrcValue, DstType, "",
                                   CI);
            } else {
              V = CastInst::Create(Instruction::FPToUI, SrcValue, DstType, "",
                                   CI);
            }
          } else if (SrcIsInt && DstIsFloat) {
            if (SrcIsSigned) {
              V = CastInst::Create(Instruction::SIToFP, SrcValue, DstType, "",
                                   CI);
            } else {
              V = CastInst::Create(Instruction::UIToFP, SrcValue, DstType, "",
                                   CI);
            }
          } else if (SrcIsInt && DstIsInt) {
            V = CastInst::CreateIntegerCast(SrcValue, DstType, SrcIsSigned, "",
                                            CI);
          } else {
            // Not something we're supposed to handle, just move on
            continue;
          }

          // Replace call with the expression
          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
          }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceMulHiMadHi(Module &M) {
  bool Changed = false;

  SmallVector<Function *, 4> FnWorklist;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    bool isMad = SymVal.getKey().startswith("_Z6mad_hi");
    bool isMul = SymVal.getKey().startswith("_Z6mul_hi");

    // Skip symbols whose name doesn't match
    if (!isMad && !isMul) {
      continue;
    }

    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {
      FnWorklist.push_back(F);
    }
  }

  for (auto F : FnWorklist) {
    SmallVector<Instruction *, 4> ToRemoves;

    bool isMad = F->getName().startswith("_Z6mad_hi");
    // Walk the users of the function.
    for (auto &U : F->uses()) {
      if (auto CI = dyn_cast<CallInst>(U.getUser())) {

        // Get arguments
        auto AValue = CI->getOperand(0);
        auto BValue = CI->getOperand(1);
        auto CValue = CI->getOperand(2);

        // Don't touch overloads that aren't in OpenCL C
        auto AType = AValue->getType();
        auto BType = BValue->getType();
        auto CType = CValue->getType();

        if ((AType != BType) || (CI->getType() != AType) ||
            (isMad && (AType != CType))) {
          continue;
        }

        if (!AType->isIntOrIntVectorTy()) {
          continue;
        }

        if ((AType->getScalarSizeInBits() != 8) &&
            (AType->getScalarSizeInBits() != 16) &&
            (AType->getScalarSizeInBits() != 32) &&
            (AType->getScalarSizeInBits() != 64)) {
          continue;
        }

        if (AType->isVectorTy()) {
          if ((AType->getVectorNumElements() != 2) &&
              (AType->getVectorNumElements() != 3) &&
              (AType->getVectorNumElements() != 4) &&
              (AType->getVectorNumElements() != 8) &&
              (AType->getVectorNumElements() != 16)) {
            continue;
          }
        }

        // Get infos from the mangled OpenCL built-in function name
        auto finfo = FunctionInfo::getFromMangledName(F->getName());

        // Select the appropriate signed/unsigned SPIR-V op
        spv::Op opcode;
        if (finfo.isArgSigned(0)) {
          opcode = spv::OpSMulExtended;
        } else {
          opcode = spv::OpUMulExtended;
        }

        // Our SPIR-V op returns a struct, create a type for it
        SmallVector<Type *, 2> TwoValueType = {AType, AType};
        auto ExMulRetType = StructType::create(TwoValueType);

        // Call the SPIR-V op
        auto Call = clspv::InsertSPIRVOp(CI, opcode, {Attribute::ReadNone},
                                         ExMulRetType, {AValue, BValue});

        // Get the high part of the result
        unsigned Idxs[] = {1};
        Value *V = ExtractValueInst::Create(Call, Idxs, "", CI);

        // If we're handling a mad_hi, add the third argument to the result
        if (isMad) {
          V = BinaryOperator::Create(Instruction::Add, V, CValue, "", CI);
        }

        // Replace call with the expression
        CI->replaceAllUsesWith(V);

        // Lastly, remember to remove the user.
        ToRemoves.push_back(CI);
      }
    }

    Changed = !ToRemoves.empty();

    // And cleanup the calls we don't use anymore.
    for (auto V : ToRemoves) {
      V->eraseFromParent();
    }

    // And remove the function we don't need either too.
    F->eraseFromParent();
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceSelect(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    // Skip symbols whose name doesn't match
    if (!SymVal.getKey().startswith("_Z6select")) {
      continue;
    }
    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          // Get arguments
          auto FalseValue = CI->getOperand(0);
          auto TrueValue = CI->getOperand(1);
          auto PredicateValue = CI->getOperand(2);

          // Don't touch overloads that aren't in OpenCL C
          auto FalseType = FalseValue->getType();
          auto TrueType = TrueValue->getType();
          auto PredicateType = PredicateValue->getType();

          if (FalseType != TrueType) {
            continue;
          }

          if (!PredicateType->isIntOrIntVectorTy()) {
            continue;
          }

          if (!FalseType->isIntOrIntVectorTy() &&
              !FalseType->getScalarType()->isFloatingPointTy()) {
            continue;
          }

          if (FalseType->isVectorTy() && !PredicateType->isVectorTy()) {
            continue;
          }

          if (FalseType->getScalarSizeInBits() !=
              PredicateType->getScalarSizeInBits()) {
            continue;
          }

          if (FalseType->isVectorTy()) {
            if (FalseType->getVectorNumElements() !=
                PredicateType->getVectorNumElements()) {
              continue;
            }

            if ((FalseType->getVectorNumElements() != 2) &&
                (FalseType->getVectorNumElements() != 3) &&
                (FalseType->getVectorNumElements() != 4) &&
                (FalseType->getVectorNumElements() != 8) &&
                (FalseType->getVectorNumElements() != 16)) {
              continue;
            }
          }

          // Create constant
          const auto ZeroValue = Constant::getNullValue(PredicateType);

          // Scalar and vector are to be treated differently
          CmpInst::Predicate Pred;
          if (PredicateType->isVectorTy()) {
            Pred = CmpInst::ICMP_SLT;
          } else {
            Pred = CmpInst::ICMP_NE;
          }

          // Create comparison instruction
          auto Cmp = CmpInst::Create(Instruction::ICmp, Pred, PredicateValue,
                                     ZeroValue, "", CI);

          // Create select
          Value *V = SelectInst::Create(Cmp, TrueValue, FalseValue, "", CI);

          // Replace call with the selection
          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceBitSelect(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    // Skip symbols whose name doesn't match
    if (!SymVal.getKey().startswith("_Z9bitselect")) {
      continue;
    }
    // Is there a function going by that name?
    if (auto F = dyn_cast<Function>(SymVal.getValue())) {

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          if (CI->getNumOperands() != 4) {
            continue;
          }

          // Get arguments
          auto FalseValue = CI->getOperand(0);
          auto TrueValue = CI->getOperand(1);
          auto PredicateValue = CI->getOperand(2);

          // Don't touch overloads that aren't in OpenCL C
          auto FalseType = FalseValue->getType();
          auto TrueType = TrueValue->getType();
          auto PredicateType = PredicateValue->getType();

          if ((FalseType != TrueType) || (PredicateType != TrueType)) {
            continue;
          }

          if (TrueType->isVectorTy()) {
            if (!TrueType->getScalarType()->isFloatingPointTy() &&
                !TrueType->getScalarType()->isIntegerTy()) {
              continue;
            }
            if ((TrueType->getVectorNumElements() != 2) &&
                (TrueType->getVectorNumElements() != 3) &&
                (TrueType->getVectorNumElements() != 4) &&
                (TrueType->getVectorNumElements() != 8) &&
                (TrueType->getVectorNumElements() != 16)) {
              continue;
            }
          }

          // Remember the type of the operands
          auto OpType = TrueType;

          // The actual bit selection will always be done on an integer type,
          // declare it here
          Type *BitType;

          // If the operands are float, then bitcast them to int
          if (OpType->getScalarType()->isFloatingPointTy()) {

            // First create the new type
            BitType = getIntOrIntVectorTyForCast(M.getContext(), OpType);

            // Then bitcast all operands
            PredicateValue =
                CastInst::CreateZExtOrBitCast(PredicateValue, BitType, "", CI);
            FalseValue =
                CastInst::CreateZExtOrBitCast(FalseValue, BitType, "", CI);
            TrueValue =
                CastInst::CreateZExtOrBitCast(TrueValue, BitType, "", CI);

          } else {
            // The operands have an integer type, use it directly
            BitType = OpType;
          }

          // All the operands are now always integers
          // implement as (c & b) | (~c & a)

          // Create our negated predicate value
          auto AllOnes = Constant::getAllOnesValue(BitType);
          auto NotPredicateValue = BinaryOperator::Create(
              Instruction::Xor, PredicateValue, AllOnes, "", CI);

          // Then put everything together
          auto BitsFalse = BinaryOperator::Create(
              Instruction::And, NotPredicateValue, FalseValue, "", CI);
          auto BitsTrue = BinaryOperator::Create(
              Instruction::And, PredicateValue, TrueValue, "", CI);

          Value *V = BinaryOperator::Create(Instruction::Or, BitsFalse,
                                            BitsTrue, "", CI);

          // If we were dealing with a floating point type, we must bitcast
          // the result back to that
          if (OpType->getScalarType()->isFloatingPointTy()) {
            V = CastInst::CreateZExtOrBitCast(V, OpType, "", CI);
          }

          // Replace call with our new code
          CI->replaceAllUsesWith(V);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceStepSmoothStep(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char *> Map = {
      {"_Z4stepfDv2_f", "_Z4stepDv2_fS_"},
      {"_Z4stepfDv3_f", "_Z4stepDv3_fS_"},
      {"_Z4stepfDv4_f", "_Z4stepDv4_fS_"},
      {"_Z10smoothstepffDv2_f", "_Z10smoothstepDv2_fS_S_"},
      {"_Z10smoothstepffDv3_f", "_Z10smoothstepDv3_fS_S_"},
      {"_Z10smoothstepffDv4_f", "_Z10smoothstepDv4_fS_S_"},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          auto ReplacementFn = Pair.second;

          SmallVector<Value *, 2> ArgsToSplat = {CI->getOperand(0)};
          Value *VectorArg;

          // First figure out which function we're dealing with
          if (F->getName().startswith("_Z10smoothstep")) {
            ArgsToSplat.push_back(CI->getOperand(1));
            VectorArg = CI->getOperand(2);
          } else {
            VectorArg = CI->getOperand(1);
          }

          // Splat arguments that need to be
          SmallVector<Value *, 2> SplatArgs;
          auto VecType = VectorArg->getType();

          for (auto arg : ArgsToSplat) {
            Value *NewVectorArg = UndefValue::get(VecType);
            for (auto i = 0; i < VecType->getVectorNumElements(); i++) {
              auto index =
                  ConstantInt::get(Type::getInt32Ty(M.getContext()), i);
              NewVectorArg =
                  InsertElementInst::Create(NewVectorArg, arg, index, "", CI);
            }
            SplatArgs.push_back(NewVectorArg);
          }

          // Replace the call with the vector/vector flavour
          SmallVector<Type *, 3> NewArgTypes(ArgsToSplat.size() + 1, VecType);
          const auto NewFType =
              FunctionType::get(CI->getType(), NewArgTypes, false);

          const auto NewF = M.getOrInsertFunction(ReplacementFn, NewFType);

          SmallVector<Value *, 3> NewArgs;
          for (auto arg : SplatArgs) {
            NewArgs.push_back(arg);
          }
          NewArgs.push_back(VectorArg);

          const auto NewCI = CallInst::Create(NewF, NewArgs, "", CI);

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceSignbit(Module &M) {
  bool Changed = false;

  const std::map<const char *, Instruction::BinaryOps> Map = {
      {"_Z7signbitf", Instruction::LShr},
      {"_Z7signbitDv2_f", Instruction::AShr},
      {"_Z7signbitDv3_f", Instruction::AShr},
      {"_Z7signbitDv4_f", Instruction::AShr},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto Arg = CI->getOperand(0);

          auto Bitcast =
              CastInst::CreateZExtOrBitCast(Arg, CI->getType(), "", CI);

          auto Shr = BinaryOperator::Create(Pair.second, Bitcast,
                                            ConstantInt::get(CI->getType(), 31),
                                            "", CI);

          CI->replaceAllUsesWith(Shr);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceMadandMad24andMul24(Module &M) {
  bool Changed = false;

  const std::map<const char *,
                 std::pair<Instruction::BinaryOps, Instruction::BinaryOps>>
      Map = {
          {"_Z3madfff", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv2_fS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv3_fS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv4_fS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDhDhDh", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv2_DhS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv3_DhS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z3madDv4_DhS_S_", {Instruction::FMul, Instruction::FAdd}},
          {"_Z5mad24iii", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv2_iS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv3_iS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv4_iS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24jjj", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv2_jS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv3_jS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mad24Dv4_jS_S_", {Instruction::Mul, Instruction::Add}},
          {"_Z5mul24ii", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv2_iS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv3_iS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv4_iS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24jj", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv2_jS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv3_jS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
          {"_Z5mul24Dv4_jS_", {Instruction::Mul, Instruction::BinaryOpsEnd}},
      };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The multiply instruction to use.
          auto MulInst = Pair.second.first;

          // The add instruction to use.
          auto AddInst = Pair.second.second;

          SmallVector<Value *, 8> Args(CI->arg_begin(), CI->arg_end());

          auto I = BinaryOperator::Create(MulInst, CI->getArgOperand(0),
                                          CI->getArgOperand(1), "", CI);

          if (Instruction::BinaryOpsEnd != AddInst) {
            I = BinaryOperator::Create(AddInst, I, CI->getArgOperand(2), "",
                                       CI);
          }

          CI->replaceAllUsesWith(I);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceVstore(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    if (!SymVal.getKey().contains("vstore"))
      continue;
    if (SymVal.getKey().contains("vstore_"))
      continue;
    if (SymVal.getKey().contains("vstorea"))
      continue;

    if (auto F = dyn_cast<Function>(SymVal.getValue())) {
      SmallVector<Instruction *, 4> ToRemoves;

      auto fname = F->getName();
      if (!fname.consume_front("_Z"))
        continue;
      size_t name_len;
      if (fname.consumeInteger(10, name_len))
        continue;
      std::string name = fname.take_front(name_len);

      bool ok = StringSwitch<bool>(name)
                    .Case("vstore2", true)
                    .Case("vstore3", true)
                    .Case("vstore4", true)
                    .Case("vstore8", true)
                    .Case("vstore16", true)
                    .Default(false);
      if (!ok)
        continue;

      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto data = CI->getOperand(0);

          auto data_type = data->getType();
          if (!data_type->isVectorTy())
            continue;

          auto elems = data_type->getVectorNumElements();
          if (elems != 2 && elems != 3 && elems != 4 && elems != 8 &&
              elems != 16)
            continue;

          auto offset = CI->getOperand(1);
          auto ptr = CI->getOperand(2);
          auto ptr_type = ptr->getType();
          auto pointee_type = ptr_type->getPointerElementType();
          if (pointee_type != data_type->getVectorElementType())
            continue;

          // Avoid pointer casts. Instead generate the correct number of stores
          // and rely on drivers to coalesce appropriately.
          IRBuilder<> builder(CI);
          auto elems_const = builder.getInt32(elems);
          auto adjust = builder.CreateMul(offset, elems_const);
          for (auto i = 0; i < elems; ++i) {
            auto idx = builder.getInt32(i);
            auto add = builder.CreateAdd(adjust, idx);
            auto gep = builder.CreateGEP(ptr, add);
            auto extract = builder.CreateExtractElement(data, i);
            auto store = builder.CreateStore(extract, gep);
          }

          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceVload(Module &M) {
  bool Changed = false;

  for (auto const &SymVal : M.getValueSymbolTable()) {
    if (!SymVal.getKey().contains("vload"))
      continue;
    if (SymVal.getKey().contains("vload_"))
      continue;
    if (SymVal.getKey().contains("vloada"))
      continue;

    if (auto F = dyn_cast<Function>(SymVal.getValue())) {
      SmallVector<Instruction *, 4> ToRemoves;

      auto fname = F->getName();
      if (!fname.consume_front("_Z"))
        continue;
      size_t name_len;
      if (fname.consumeInteger(10, name_len))
        continue;
      std::string name = fname.take_front(name_len);

      bool ok = StringSwitch<bool>(name)
                    .Case("vload2", true)
                    .Case("vload3", true)
                    .Case("vload4", true)
                    .Case("vload8", true)
                    .Case("vload16", true)
                    .Default(false);
      if (!ok)
        continue;

      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto ret_type = F->getReturnType();
          if (!ret_type->isVectorTy())
            continue;

          auto elems = ret_type->getVectorNumElements();
          if (elems != 2 && elems != 3 && elems != 4 && elems != 8 &&
              elems != 16)
            continue;

          auto offset = CI->getOperand(0);
          auto ptr = CI->getOperand(1);
          auto ptr_type = ptr->getType();
          auto pointee_type = ptr_type->getPointerElementType();
          if (pointee_type != ret_type->getVectorElementType())
            continue;

          // Avoid pointer casts. Instead generate the correct number of loads
          // and rely on drivers to coalesce appropriately.
          IRBuilder<> builder(CI);
          auto elems_const = builder.getInt32(elems);
          Value *insert = UndefValue::get(ret_type);
          auto adjust = builder.CreateMul(offset, elems_const);
          for (auto i = 0; i < elems; ++i) {
            auto idx = builder.getInt32(i);
            auto add = builder.CreateAdd(adjust, idx);
            auto gep = builder.CreateGEP(ptr, add);
            auto load = builder.CreateLoad(gep);
            insert = builder.CreateInsertElement(insert, load, i);
          }

          CI->replaceAllUsesWith(insert);
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf(Module &M) {
  bool Changed = false;

  const std::vector<const char *> Map = {"_Z10vload_halfjPU3AS1KDh",
                                         "_Z10vload_halfjPU3AS2KDh"};

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The index argument from vload_half.
          auto Arg0 = CI->getOperand(0);

          // The pointer argument from vload_half.
          auto Arg1 = CI->getOperand(1);

          auto IntTy = Type::getInt32Ty(M.getContext());
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

          // Our intrinsic to unpack a float2 from an int.
          auto SPIRVIntrinsic = "spirv.unpack.v2f16";

          auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

          if (clspv::Option::F16BitStorage()) {
            auto ShortTy = Type::getInt16Ty(M.getContext());
            auto ShortPointerTy = PointerType::get(
                ShortTy, Arg1->getType()->getPointerAddressSpace());

            // Cast the half* pointer to short*.
            auto Cast =
                CastInst::CreatePointerCast(Arg1, ShortPointerTy, "", CI);

            // Index into the correct address of the casted pointer.
            auto Index = GetElementPtrInst::Create(ShortTy, Cast, Arg0, "", CI);

            // Load from the short* we casted to.
            auto Load = new LoadInst(Index, "", CI);

            // ZExt the short -> int.
            auto ZExt = CastInst::CreateZExtOrBitCast(Load, IntTy, "", CI);

            // Get our float2.
            auto Call = CallInst::Create(NewF, ZExt, "", CI);

            // Extract out the bottom element which is our float result.
            auto Extract = ExtractElementInst::Create(
                Call, ConstantInt::get(IntTy, 0), "", CI);

            CI->replaceAllUsesWith(Extract);
          } else {
            // Assume the pointer argument points to storage aligned to 32bits
            // or more.
            // TODO(dneto): Do more analysis to make sure this is true?
            //
            // Replace call vstore_half(i32 %index, half addrspace(1) %base)
            // with:
            //
            //   %base_i32_ptr = bitcast half addrspace(1)* %base to i32
            //   addrspace(1)* %index_is_odd32 = and i32 %index, 1 %index_i32 =
            //   lshr i32 %index, 1 %in_ptr = getlementptr i32, i32
            //   addrspace(1)* %base_i32_ptr, %index_i32 %value_i32 = load i32,
            //   i32 addrspace(1)* %in_ptr %converted = call <2 x float>
            //   @spirv.unpack.v2f16(i32 %value_i32) %value = extractelement <2
            //   x float> %converted, %index_is_odd32

            auto IntPointerTy = PointerType::get(
                IntTy, Arg1->getType()->getPointerAddressSpace());

            // Cast the base pointer to int*.
            // In a valid call (according to assumptions), this should get
            // optimized away in the simplify GEP pass.
            auto Cast = CastInst::CreatePointerCast(Arg1, IntPointerTy, "", CI);

            auto One = ConstantInt::get(IntTy, 1);
            auto IndexIsOdd = BinaryOperator::CreateAnd(Arg0, One, "", CI);
            auto IndexIntoI32 = BinaryOperator::CreateLShr(Arg0, One, "", CI);

            // Index into the correct address of the casted pointer.
            auto Ptr =
                GetElementPtrInst::Create(IntTy, Cast, IndexIntoI32, "", CI);

            // Load from the int* we casted to.
            auto Load = new LoadInst(Ptr, "", CI);

            // Get our float2.
            auto Call = CallInst::Create(NewF, Load, "", CI);

            // Extract out the float result, where the element number is
            // determined by whether the original index was even or odd.
            auto Extract = ExtractElementInst::Create(Call, IndexIsOdd, "", CI);

            CI->replaceAllUsesWith(Extract);
          }

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf2(Module &M) {

  const std::vector<const char *> Names = {
      "_Z11vload_half2jPU3AS1KDh",
      "_Z12vloada_half2jPU3AS1KDh", // vloada_half2 global
      "_Z11vload_half2jPU3AS2KDh",
      "_Z12vloada_half2jPU3AS2KDh", // vloada_half2 constant
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    // The index argument from vload_half.
    auto Arg0 = CI->getOperand(0);

    // The pointer argument from vload_half.
    auto Arg1 = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(IntTy, Arg1->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    // Cast the half* pointer to int*.
    auto Cast = CastInst::CreatePointerCast(Arg1, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(IntTy, Cast, Arg0, "", CI);

    // Load from the int* we casted to.
    auto Load = new LoadInst(Index, "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = "spirv.unpack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get our float2.
    return CallInst::Create(NewF, Load, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf4(Module &M) {

  const std::vector<const char *> Names = {
      "_Z11vload_half4jPU3AS1KDh",
      "_Z12vloada_half4jPU3AS1KDh",
      "_Z11vload_half4jPU3AS2KDh",
      "_Z12vloada_half4jPU3AS2KDh",
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    // The index argument from vload_half.
    auto Arg0 = CI->getOperand(0);

    // The pointer argument from vload_half.
    auto Arg1 = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = VectorType::get(IntTy, 2);
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(Int2Ty, Arg1->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    // Cast the half* pointer to int2*.
    auto Cast = CastInst::CreatePointerCast(Arg1, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(Int2Ty, Cast, Arg0, "", CI);

    // Load from the int2* we casted to.
    auto Load = new LoadInst(Index, "", CI);

    // Extract each element from the loaded int2.
    auto X =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0), "", CI);
    auto Y =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1), "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = "spirv.unpack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get the lower (x & y) components of our final float4.
    auto Lo = CallInst::Create(NewF, X, "", CI);

    // Get the higher (z & w) components of our final float4.
    auto Hi = CallInst::Create(NewF, Y, "", CI);

    Constant *ShuffleMask[4] = {
        ConstantInt::get(IntTy, 0), ConstantInt::get(IntTy, 1),
        ConstantInt::get(IntTy, 2), ConstantInt::get(IntTy, 3)};

    // Combine our two float2's into one float4.
    return new ShuffleVectorInst(Lo, Hi, ConstantVector::get(ShuffleMask), "",
                                 CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf2(Module &M) {

  // Replace __clspv_vloada_half2(uint Index, global uint* Ptr) with:
  //
  //    %u = load i32 %ptr
  //    %fxy = call <2 x float> Unpack2xHalf(u)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  const std::vector<const char *> Names = {
      "_Z20__clspv_vloada_half2jPU3AS1Kj", // global
      "_Z20__clspv_vloada_half2jPU3AS3Kj", // local
      "_Z20__clspv_vloada_half2jPKj",      // private
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    auto Index = CI->getOperand(0);
    auto Ptr = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    auto IndexedPtr = GetElementPtrInst::Create(IntTy, Ptr, Index, "", CI);
    auto Load = new LoadInst(IndexedPtr, "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = "spirv.unpack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get our final float2.
    return CallInst::Create(NewF, Load, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf4(Module &M) {

  // Replace __clspv_vloada_half4(uint Index, global uint2* Ptr) with:
  //
  //    %u2 = load <2 x i32> %ptr
  //    %u2xy = extractelement %u2, 0
  //    %u2zw = extractelement %u2, 1
  //    %fxy = call <2 x float> Unpack2xHalf(uint)
  //    %fzw = call <2 x float> Unpack2xHalf(uint)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  const std::vector<const char *> Names = {
      "_Z20__clspv_vloada_half4jPU3AS1KDv2_j", // global
      "_Z20__clspv_vloada_half4jPU3AS3KDv2_j", // local
      "_Z20__clspv_vloada_half4jPKDv2_j",      // private
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    auto Index = CI->getOperand(0);
    auto Ptr = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = VectorType::get(IntTy, 2);
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    auto IndexedPtr = GetElementPtrInst::Create(Int2Ty, Ptr, Index, "", CI);
    auto Load = new LoadInst(IndexedPtr, "", CI);

    // Extract each element from the loaded int2.
    auto X =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0), "", CI);
    auto Y =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1), "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = "spirv.unpack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get the lower (x & y) components of our final float4.
    auto Lo = CallInst::Create(NewF, X, "", CI);

    // Get the higher (z & w) components of our final float4.
    auto Hi = CallInst::Create(NewF, Y, "", CI);

    Constant *ShuffleMask[4] = {
        ConstantInt::get(IntTy, 0), ConstantInt::get(IntTy, 1),
        ConstantInt::get(IntTy, 2), ConstantInt::get(IntTy, 3)};

    // Combine our two float2's into one float4.
    return new ShuffleVectorInst(Lo, Hi, ConstantVector::get(ShuffleMask), "",
                                 CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf(Module &M) {

  const std::vector<const char *> Names = {"_Z11vstore_halffjPU3AS1Dh",
                                           "_Z15vstore_half_rtefjPU3AS1Dh",
                                           "_Z15vstore_half_rtzfjPU3AS1Dh"};

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(IntTy, Float2Ty, false);
    auto One = ConstantInt::get(IntTy, 1);

    // Our intrinsic to pack a float2 to an int.
    auto SPIRVIntrinsic = "spirv.pack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Insert our value into a float2 so that we can pack it.
    auto TempVec = InsertElementInst::Create(
        UndefValue::get(Float2Ty), Arg0, ConstantInt::get(IntTy, 0), "", CI);

    // Pack the float2 -> half2 (in an int).
    auto X = CallInst::Create(NewF, TempVec, "", CI);

    Value *Ret;
    if (clspv::Option::F16BitStorage()) {
      auto ShortTy = Type::getInt16Ty(M.getContext());
      auto ShortPointerTy =
          PointerType::get(ShortTy, Arg2->getType()->getPointerAddressSpace());

      // Truncate our i32 to an i16.
      auto Trunc = CastInst::CreateTruncOrBitCast(X, ShortTy, "", CI);

      // Cast the half* pointer to short*.
      auto Cast = CastInst::CreatePointerCast(Arg2, ShortPointerTy, "", CI);

      // Index into the correct address of the casted pointer.
      auto Index = GetElementPtrInst::Create(ShortTy, Cast, Arg1, "", CI);

      // Store to the int* we casted to.
      Ret = new StoreInst(Trunc, Index, CI);
    } else {
      // We can only write to 32-bit aligned words.
      //
      // Assuming base is aligned to 32-bits, replace the equivalent of
      //   vstore_half(value, index, base)
      // with:
      //   uint32_t* target_ptr = (uint32_t*)(base) + index / 2;
      //   uint32_t write_to_upper_half = index & 1u;
      //   uint32_t shift = write_to_upper_half << 4;
      //
      //   // Pack the float value as a half number in bottom 16 bits
      //   // of an i32.
      //   uint32_t packed = spirv.pack.v2f16((float2)(value, undef));
      //
      //   uint32_t xor_value =   (*target_ptr & (0xffff << shift))
      //                        ^ ((packed & 0xffff) << shift)
      //   // We only need relaxed consistency, but OpenCL 1.2 only has
      //   // sequentially consistent atomics.
      //   // TODO(dneto): Use relaxed consistency.
      //   atomic_xor(target_ptr, xor_value)
      auto IntPointerTy =
          PointerType::get(IntTy, Arg2->getType()->getPointerAddressSpace());

      auto Four = ConstantInt::get(IntTy, 4);
      auto FFFF = ConstantInt::get(IntTy, 0xffff);

      auto IndexIsOdd =
          BinaryOperator::CreateAnd(Arg1, One, "index_is_odd_i32", CI);
      // Compute index / 2
      auto IndexIntoI32 =
          BinaryOperator::CreateLShr(Arg1, One, "index_into_i32", CI);
      auto BaseI32Ptr =
          CastInst::CreatePointerCast(Arg2, IntPointerTy, "base_i32_ptr", CI);
      auto OutPtr = GetElementPtrInst::Create(IntTy, BaseI32Ptr, IndexIntoI32,
                                              "base_i32_ptr", CI);
      auto CurrentValue = new LoadInst(OutPtr, "current_value", CI);
      auto Shift = BinaryOperator::CreateShl(IndexIsOdd, Four, "shift", CI);
      auto MaskBitsToWrite =
          BinaryOperator::CreateShl(FFFF, Shift, "mask_bits_to_write", CI);
      auto MaskedCurrent = BinaryOperator::CreateAnd(
          MaskBitsToWrite, CurrentValue, "masked_current", CI);

      auto XLowerBits =
          BinaryOperator::CreateAnd(X, FFFF, "lower_bits_of_packed", CI);
      auto NewBitsToWrite =
          BinaryOperator::CreateShl(XLowerBits, Shift, "new_bits_to_write", CI);
      auto ValueToXor = BinaryOperator::CreateXor(MaskedCurrent, NewBitsToWrite,
                                                  "value_to_xor", CI);

      // Generate the call to atomi_xor.
      SmallVector<Type *, 5> ParamTypes;
      // The pointer type.
      ParamTypes.push_back(IntPointerTy);
      // The Types for memory scope, semantics, and value.
      ParamTypes.push_back(IntTy);
      ParamTypes.push_back(IntTy);
      ParamTypes.push_back(IntTy);
      auto NewFType = FunctionType::get(IntTy, ParamTypes, false);
      auto NewF = M.getOrInsertFunction("spirv.atomic_xor", NewFType);

      const auto ConstantScopeDevice =
          ConstantInt::get(IntTy, spv::ScopeDevice);
      // Assume the pointee is in OpenCL global (SPIR-V Uniform) or local
      // (SPIR-V Workgroup).
      const auto AddrSpaceSemanticsBits =
          IntPointerTy->getPointerAddressSpace() == 1
              ? spv::MemorySemanticsUniformMemoryMask
              : spv::MemorySemanticsWorkgroupMemoryMask;

      // We're using relaxed consistency here.
      const auto ConstantMemorySemantics =
          ConstantInt::get(IntTy, spv::MemorySemanticsUniformMemoryMask |
                                      AddrSpaceSemanticsBits);

      SmallVector<Value *, 5> Params{OutPtr, ConstantScopeDevice,
                                     ConstantMemorySemantics, ValueToXor};
      CallInst::Create(NewF, Params, "store_halfword_xor_trick", CI);
      Ret = nullptr;
    }

    return Ret;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf2(Module &M) {

  const std::vector<const char *> Names = {
      "_Z12vstore_half2Dv2_fjPU3AS1Dh",
      "_Z13vstorea_half2Dv2_fjPU3AS1Dh", // vstorea global
      "_Z13vstorea_half2Dv2_fjPU3AS3Dh", // vstorea local
      "_Z13vstorea_half2Dv2_fjPDh",      // vstorea private
      "_Z16vstore_half2_rteDv2_fjPU3AS1Dh",
      "_Z17vstorea_half2_rteDv2_fjPU3AS1Dh", // vstorea global
      "_Z17vstorea_half2_rteDv2_fjPU3AS3Dh", // vstorea local
      "_Z17vstorea_half2_rteDv2_fjPDh",      // vstorea private
      "_Z16vstore_half2_rtzDv2_fjPU3AS1Dh",
      "_Z17vstorea_half2_rtzDv2_fjPU3AS1Dh", // vstorea global
      "_Z17vstorea_half2_rtzDv2_fjPU3AS3Dh", // vstorea local
      "_Z17vstorea_half2_rtzDv2_fjPDh",      // vstorea private
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(IntTy, Arg2->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(IntTy, Float2Ty, false);

    // Our intrinsic to pack a float2 to an int.
    auto SPIRVIntrinsic = "spirv.pack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Turn the packed x & y into the final packing.
    auto X = CallInst::Create(NewF, Arg0, "", CI);

    // Cast the half* pointer to int*.
    auto Cast = CastInst::CreatePointerCast(Arg2, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(IntTy, Cast, Arg1, "", CI);

    // Store to the int* we casted to.
    return new StoreInst(X, Index, CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf4(Module &M) {

  const std::vector<const char *> Names = {
      "_Z12vstore_half4Dv4_fjPU3AS1Dh",
      "_Z13vstorea_half4Dv4_fjPU3AS1Dh", // global
      "_Z13vstorea_half4Dv4_fjPU3AS3Dh", // local
      "_Z13vstorea_half4Dv4_fjPDh",      // private
      "_Z16vstore_half4_rteDv4_fjPU3AS1Dh",
      "_Z17vstorea_half4_rteDv4_fjPU3AS1Dh", // global
      "_Z17vstorea_half4_rteDv4_fjPU3AS3Dh", // local
      "_Z17vstorea_half4_rteDv4_fjPDh",      // private
      "_Z16vstore_half4_rtzDv4_fjPU3AS1Dh",
      "_Z17vstorea_half4_rtzDv4_fjPU3AS1Dh", // global
      "_Z17vstorea_half4_rtzDv4_fjPU3AS3Dh", // local
      "_Z17vstorea_half4_rtzDv4_fjPDh",      // private
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = VectorType::get(IntTy, 2);
    auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(Int2Ty, Arg2->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(IntTy, Float2Ty, false);

    Constant *LoShuffleMask[2] = {ConstantInt::get(IntTy, 0),
                                  ConstantInt::get(IntTy, 1)};

    // Extract out the x & y components of our to store value.
    auto Lo = new ShuffleVectorInst(Arg0, UndefValue::get(Arg0->getType()),
                                    ConstantVector::get(LoShuffleMask), "", CI);

    Constant *HiShuffleMask[2] = {ConstantInt::get(IntTy, 2),
                                  ConstantInt::get(IntTy, 3)};

    // Extract out the z & w components of our to store value.
    auto Hi = new ShuffleVectorInst(Arg0, UndefValue::get(Arg0->getType()),
                                    ConstantVector::get(HiShuffleMask), "", CI);

    // Our intrinsic to pack a float2 to an int.
    auto SPIRVIntrinsic = "spirv.pack.v2f16";

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Turn the packed x & y into the final component of our int2.
    auto X = CallInst::Create(NewF, Lo, "", CI);

    // Turn the packed z & w into the final component of our int2.
    auto Y = CallInst::Create(NewF, Hi, "", CI);

    auto Combine = InsertElementInst::Create(
        UndefValue::get(Int2Ty), X, ConstantInt::get(IntTy, 0), "", CI);
    Combine = InsertElementInst::Create(Combine, Y, ConstantInt::get(IntTy, 1),
                                        "", CI);

    // Cast the half* pointer to int2*.
    auto Cast = CastInst::CreatePointerCast(Arg2, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(Int2Ty, Cast, Arg1, "", CI);

    // Store to the int2* we casted to.
    return new StoreInst(Combine, Index, CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceHalfReadImage(Module &M) {
  bool Changed = false;
  const std::map<const char *, const char *> Map = {
      // 1D
      {"_Z11read_imageh14ocl_image1d_roi", "_Z11read_imagef14ocl_image1d_roi"},
      {"_Z11read_imageh14ocl_image1d_ro11ocl_sampleri",
       "_Z11read_imagef14ocl_image1d_ro11ocl_sampleri"},
      {"_Z11read_imageh14ocl_image1d_ro11ocl_samplerf",
       "_Z11read_imagef14ocl_image1d_ro11ocl_samplerf"},
      // TODO 1D array
      // 2D
      {"_Z11read_imageh14ocl_image2d_roDv2_i",
       "_Z11read_imagef14ocl_image2d_roDv2_i"},
      {"_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_i",
       "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i"},
      {"_Z11read_imageh14ocl_image2d_ro11ocl_samplerDv2_f",
       "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f"},
      // TODO 2D array
      // 3D
      {"_Z11read_imageh14ocl_image3d_roDv4_i",
       "_Z11read_imagef14ocl_image3d_roDv4_i"},
      {"_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_i",
       "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i"},
      {"_Z11read_imageh14ocl_image3d_ro11ocl_samplerDv4_f",
       "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          SmallVector<Type *, 3> types;
          SmallVector<Value *, 3> args;
          for (auto i = 0; i < CI->getNumArgOperands(); ++i) {
            types.push_back(CI->getArgOperand(i)->getType());
            args.push_back(CI->getArgOperand(i));
          }

          auto NewFType = FunctionType::get(
              VectorType::get(Type::getFloatTy(M.getContext()),
                              CI->getType()->getVectorNumElements()),
              types, false);

          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

          auto NewCI = CallInst::Create(NewF, args, "", CI);

          // Convert to the half type.
          auto Cast = CastInst::CreateFPCast(NewCI, CI->getType(), "", CI);

          CI->replaceAllUsesWith(Cast);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceHalfWriteImage(Module &M) {
  bool Changed = false;
  const std::map<const char *, const char *> Map = {
      // 1D
      {"_Z12write_imageh14ocl_image1d_woiDv4_Dh",
       "_Z12write_imagef14ocl_image1d_woiDv4_f"},
      // TODO 1D array
      // 2D
      {"_Z12write_imageh14ocl_image2d_woDv2_iDv4_Dh",
       "_Z12write_imagef14ocl_image2d_woDv2_iDv4_f"},
      // TODO 2D array
      // 3D
      {"_Z12write_imageh14ocl_image3d_woDv4_iDv4_Dh",
       "_Z12write_imagef14ocl_image3d_woDv4_iDv4_f"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          SmallVector<Type *, 3> types(3);
          SmallVector<Value *, 3> args(3);

          // Image
          types[0] = CI->getArgOperand(0)->getType();
          args[0] = CI->getArgOperand(0);

          // Coord
          types[1] = CI->getArgOperand(1)->getType();
          args[1] = CI->getArgOperand(1);

          // Data
          types[2] = VectorType::get(
              Type::getFloatTy(M.getContext()),
              CI->getArgOperand(2)->getType()->getVectorNumElements());

          auto NewFType =
              FunctionType::get(Type::getVoidTy(M.getContext()), types, false);

          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

          // Convert data to the float type.
          auto Cast =
              CastInst::CreateFPCast(CI->getArgOperand(2), types[2], "", CI);
          args[2] = Cast;

          auto NewCI = CallInst::Create(NewF, args, "", CI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceUnsampledReadImage(Module &M) {
  bool Changed = false;
  const std::map<const char *, const char *> Map = {
      // 1D
      {"_Z11read_imagef14ocl_image1d_roi",
       "_Z11read_imagef14ocl_image1d_ro11ocl_sampleri"},
      {"_Z11read_imagei14ocl_image1d_roi",
       "_Z11read_imagei14ocl_image1d_ro11ocl_sampleri"},
      {"_Z12read_imageui14ocl_image1d_roi",
       "_Z12read_imageui14ocl_image1d_ro11ocl_sampleri"},
      // TODO 1D array
      // 2D
      {"_Z11read_imagef14ocl_image2d_roDv2_i",
       "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i"},
      {"_Z11read_imagei14ocl_image2d_roDv2_i",
       "_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_i"},
      {"_Z12read_imageui14ocl_image2d_roDv2_i",
       "_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_i"},
      // TODO 2D array
      // 3D
      {"_Z11read_imagef14ocl_image3d_roDv4_i",
       "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i"},
      {"_Z11read_imagei14ocl_image3d_roDv4_i",
       "_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_i"},
      {"_Z12read_imageui14ocl_image3d_roDv4_i",
       "_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_i"}};

  Function *translate_sampler =
      M.getFunction(clspv::TranslateSamplerInitializerFunction());
  Type *sampler_type = M.getTypeByName("opencl.sampler_t");
  if (sampler_type) {
    sampler_type = sampler_type->getPointerTo(clspv::AddressSpace::Constant);
  }
  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The image.
          auto Image = CI->getOperand(0);

          // The coordinate.
          auto Coord = CI->getOperand(1);

          // Create the sampler translation function if necessary.
          if (!translate_sampler) {
            // Create the sampler type if necessary.
            if (!sampler_type) {
              sampler_type =
                  StructType::create(M.getContext(), "opencl.sampler_t");
              sampler_type =
                  sampler_type->getPointerTo(clspv::AddressSpace::Constant);
            }
            auto fn_type = FunctionType::get(
                sampler_type, {Type::getInt32Ty(M.getContext())}, false);
            auto callee = M.getOrInsertFunction(
                clspv::TranslateSamplerInitializerFunction(), fn_type);
            translate_sampler = cast<Function>(callee.getCallee());
          }

          auto NewFType = FunctionType::get(
              CI->getType(), {Image->getType(), sampler_type, Coord->getType()},
              false);

          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

          const uint64_t data_mask =
              clspv::version0::CLK_ADDRESS_NONE |
              clspv::version0::CLK_FILTER_NEAREST |
              clspv::version0::CLK_NORMALIZED_COORDS_FALSE;
          auto NewSamplerCI = CallInst::Create(
              translate_sampler,
              {ConstantInt::get(Type::getInt32Ty(M.getContext()), data_mask)},
              "", CI);
          auto NewCI =
              CallInst::Create(NewF, {Image, NewSamplerCI, Coord}, "", CI);

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceSampledReadImageWithIntCoords(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char *> Map = {
      // 1D
      {"_Z11read_imagei14ocl_image1d_ro11ocl_sampleri",
       "_Z11read_imagei14ocl_image1d_ro11ocl_samplerf"},
      {"_Z12read_imageui14ocl_image1d_ro11ocl_sampleri",
       "_Z12read_imageui14ocl_image1d_ro11ocl_samplerf"},
      {"_Z11read_imagef14ocl_image1d_ro11ocl_sampleri",
       "_Z11read_imagef14ocl_image1d_ro11ocl_samplerf"},
      // TODO 1Darray
      // 2D
      {"_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_i",
       "_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_f"},
      {"_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_i",
       "_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_f"},
      {"_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i",
       "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f"},
      // TODO 2D array
      // 3D
      {"_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_i",
       "_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_f"},
      {"_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_i",
       "_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_f"},
      {"_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i",
       "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The image.
          auto Arg0 = CI->getOperand(0);

          // The sampler.
          auto Arg1 = CI->getOperand(1);

          // The coordinate (integer type that we can't handle).
          auto Arg2 = CI->getOperand(2);

          uint32_t dim = clspv::ImageDimensionality(Arg0->getType());
          // TODO(alan-baker): when arrayed images are supported fix component
          // calculation.
          uint32_t components = dim;
          Type *float_ty = nullptr;
          if (components == 1) {
            float_ty = Type::getFloatTy(M.getContext());
          } else {
            float_ty = VectorType::get(Type::getFloatTy(M.getContext()),
                                       Arg2->getType()->getVectorNumElements());
          }

          auto NewFType = FunctionType::get(
              CI->getType(), {Arg0->getType(), Arg1->getType(), float_ty},
              false);

          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

          auto Cast =
              CastInst::Create(Instruction::SIToFP, Arg2, float_ty, "", CI);

          auto NewCI = CallInst::Create(NewF, {Arg0, Arg1, Cast}, "", CI);

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceAtomics(Module &M) {
  bool Changed = false;

  const std::map<const char *, spv::Op> Map = {
      {"_Z8atom_incPU3AS1Vi", spv::OpAtomicIIncrement},
      {"_Z8atom_incPU3AS3Vi", spv::OpAtomicIIncrement},
      {"_Z8atom_incPU3AS1Vj", spv::OpAtomicIIncrement},
      {"_Z8atom_incPU3AS3Vj", spv::OpAtomicIIncrement},
      {"_Z8atom_decPU3AS1Vi", spv::OpAtomicIDecrement},
      {"_Z8atom_decPU3AS3Vi", spv::OpAtomicIDecrement},
      {"_Z8atom_decPU3AS1Vj", spv::OpAtomicIDecrement},
      {"_Z8atom_decPU3AS3Vj", spv::OpAtomicIDecrement},
      {"_Z12atom_cmpxchgPU3AS1Viii", spv::OpAtomicCompareExchange},
      {"_Z12atom_cmpxchgPU3AS3Viii", spv::OpAtomicCompareExchange},
      {"_Z12atom_cmpxchgPU3AS1Vjjj", spv::OpAtomicCompareExchange},
      {"_Z12atom_cmpxchgPU3AS3Vjjj", spv::OpAtomicCompareExchange},
      {"_Z10atomic_incPU3AS1Vi", spv::OpAtomicIIncrement},
      {"_Z10atomic_incPU3AS3Vi", spv::OpAtomicIIncrement},
      {"_Z10atomic_incPU3AS1Vj", spv::OpAtomicIIncrement},
      {"_Z10atomic_incPU3AS3Vj", spv::OpAtomicIIncrement},
      {"_Z10atomic_decPU3AS1Vi", spv::OpAtomicIDecrement},
      {"_Z10atomic_decPU3AS3Vi", spv::OpAtomicIDecrement},
      {"_Z10atomic_decPU3AS1Vj", spv::OpAtomicIDecrement},
      {"_Z10atomic_decPU3AS3Vj", spv::OpAtomicIDecrement},
      {"_Z14atomic_cmpxchgPU3AS1Viii", spv::OpAtomicCompareExchange},
      {"_Z14atomic_cmpxchgPU3AS3Viii", spv::OpAtomicCompareExchange},
      {"_Z14atomic_cmpxchgPU3AS1Vjjj", spv::OpAtomicCompareExchange},
      {"_Z14atomic_cmpxchgPU3AS3Vjjj", spv::OpAtomicCompareExchange}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          auto IntTy = Type::getInt32Ty(M.getContext());

          // We need to map the OpenCL constants to the SPIR-V equivalents.
          const auto ConstantScopeDevice =
              ConstantInt::get(IntTy, spv::ScopeDevice);
          const auto ConstantMemorySemantics = ConstantInt::get(
              IntTy, spv::MemorySemanticsUniformMemoryMask |
                         spv::MemorySemanticsSequentiallyConsistentMask);

          SmallVector<Value *, 5> Params;

          // The pointer.
          Params.push_back(CI->getArgOperand(0));

          // The memory scope.
          Params.push_back(ConstantScopeDevice);

          // The memory semantics.
          Params.push_back(ConstantMemorySemantics);

          if (2 < CI->getNumArgOperands()) {
            // The unequal memory semantics.
            Params.push_back(ConstantMemorySemantics);

            // The value.
            Params.push_back(CI->getArgOperand(2));

            // The comparator.
            Params.push_back(CI->getArgOperand(1));
          } else if (1 < CI->getNumArgOperands()) {
            // The value.
            Params.push_back(CI->getArgOperand(1));
          }

          auto NewCI =
              clspv::InsertSPIRVOp(CI, Pair.second, {}, CI->getType(), Params);

          CI->replaceAllUsesWith(NewCI);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  const std::map<const char *, llvm::AtomicRMWInst::BinOp> Map2 = {
      {"_Z8atom_addPU3AS1Vii", llvm::AtomicRMWInst::Add},
      {"_Z8atom_addPU3AS3Vii", llvm::AtomicRMWInst::Add},
      {"_Z8atom_addPU3AS1Vjj", llvm::AtomicRMWInst::Add},
      {"_Z8atom_addPU3AS3Vjj", llvm::AtomicRMWInst::Add},
      {"_Z8atom_subPU3AS1Vii", llvm::AtomicRMWInst::Sub},
      {"_Z8atom_subPU3AS3Vii", llvm::AtomicRMWInst::Sub},
      {"_Z8atom_subPU3AS1Vjj", llvm::AtomicRMWInst::Sub},
      {"_Z8atom_subPU3AS3Vjj", llvm::AtomicRMWInst::Sub},
      {"_Z9atom_xchgPU3AS1Vii", llvm::AtomicRMWInst::Xchg},
      {"_Z9atom_xchgPU3AS3Vii", llvm::AtomicRMWInst::Xchg},
      {"_Z9atom_xchgPU3AS1Vjj", llvm::AtomicRMWInst::Xchg},
      {"_Z9atom_xchgPU3AS3Vjj", llvm::AtomicRMWInst::Xchg},
      {"_Z8atom_minPU3AS1Vii", llvm::AtomicRMWInst::Min},
      {"_Z8atom_minPU3AS3Vii", llvm::AtomicRMWInst::Min},
      {"_Z8atom_minPU3AS1Vjj", llvm::AtomicRMWInst::UMin},
      {"_Z8atom_minPU3AS3Vjj", llvm::AtomicRMWInst::UMin},
      {"_Z8atom_maxPU3AS1Vii", llvm::AtomicRMWInst::Max},
      {"_Z8atom_maxPU3AS3Vii", llvm::AtomicRMWInst::Max},
      {"_Z8atom_maxPU3AS1Vjj", llvm::AtomicRMWInst::UMax},
      {"_Z8atom_maxPU3AS3Vjj", llvm::AtomicRMWInst::UMax},
      {"_Z8atom_andPU3AS1Vii", llvm::AtomicRMWInst::And},
      {"_Z8atom_andPU3AS3Vii", llvm::AtomicRMWInst::And},
      {"_Z8atom_andPU3AS1Vjj", llvm::AtomicRMWInst::And},
      {"_Z8atom_andPU3AS3Vjj", llvm::AtomicRMWInst::And},
      {"_Z7atom_orPU3AS1Vii", llvm::AtomicRMWInst::Or},
      {"_Z7atom_orPU3AS3Vii", llvm::AtomicRMWInst::Or},
      {"_Z7atom_orPU3AS1Vjj", llvm::AtomicRMWInst::Or},
      {"_Z7atom_orPU3AS3Vjj", llvm::AtomicRMWInst::Or},
      {"_Z8atom_xorPU3AS1Vii", llvm::AtomicRMWInst::Xor},
      {"_Z8atom_xorPU3AS3Vii", llvm::AtomicRMWInst::Xor},
      {"_Z8atom_xorPU3AS1Vjj", llvm::AtomicRMWInst::Xor},
      {"_Z8atom_xorPU3AS3Vjj", llvm::AtomicRMWInst::Xor},
      {"_Z10atomic_addPU3AS1Vii", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_addPU3AS3Vii", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_addPU3AS1Vjj", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_addPU3AS3Vjj", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_subPU3AS1Vii", llvm::AtomicRMWInst::Sub},
      {"_Z10atomic_subPU3AS3Vii", llvm::AtomicRMWInst::Sub},
      {"_Z10atomic_subPU3AS1Vjj", llvm::AtomicRMWInst::Sub},
      {"_Z10atomic_subPU3AS3Vjj", llvm::AtomicRMWInst::Sub},
      {"_Z11atomic_xchgPU3AS1Vii", llvm::AtomicRMWInst::Xchg},
      {"_Z11atomic_xchgPU3AS3Vii", llvm::AtomicRMWInst::Xchg},
      {"_Z11atomic_xchgPU3AS1Vjj", llvm::AtomicRMWInst::Xchg},
      {"_Z11atomic_xchgPU3AS3Vjj", llvm::AtomicRMWInst::Xchg},
      {"_Z10atomic_minPU3AS1Vii", llvm::AtomicRMWInst::Min},
      {"_Z10atomic_minPU3AS3Vii", llvm::AtomicRMWInst::Min},
      {"_Z10atomic_minPU3AS1Vjj", llvm::AtomicRMWInst::UMin},
      {"_Z10atomic_minPU3AS3Vjj", llvm::AtomicRMWInst::UMin},
      {"_Z10atomic_maxPU3AS1Vii", llvm::AtomicRMWInst::Max},
      {"_Z10atomic_maxPU3AS3Vii", llvm::AtomicRMWInst::Max},
      {"_Z10atomic_maxPU3AS1Vjj", llvm::AtomicRMWInst::UMax},
      {"_Z10atomic_maxPU3AS3Vjj", llvm::AtomicRMWInst::UMax},
      {"_Z10atomic_andPU3AS1Vii", llvm::AtomicRMWInst::And},
      {"_Z10atomic_andPU3AS3Vii", llvm::AtomicRMWInst::And},
      {"_Z10atomic_andPU3AS1Vjj", llvm::AtomicRMWInst::And},
      {"_Z10atomic_andPU3AS3Vjj", llvm::AtomicRMWInst::And},
      {"_Z9atomic_orPU3AS1Vii", llvm::AtomicRMWInst::Or},
      {"_Z9atomic_orPU3AS3Vii", llvm::AtomicRMWInst::Or},
      {"_Z9atomic_orPU3AS1Vjj", llvm::AtomicRMWInst::Or},
      {"_Z9atomic_orPU3AS3Vjj", llvm::AtomicRMWInst::Or},
      {"_Z10atomic_xorPU3AS1Vii", llvm::AtomicRMWInst::Xor},
      {"_Z10atomic_xorPU3AS3Vii", llvm::AtomicRMWInst::Xor},
      {"_Z10atomic_xorPU3AS1Vjj", llvm::AtomicRMWInst::Xor},
      {"_Z10atomic_xorPU3AS3Vjj", llvm::AtomicRMWInst::Xor}};

  for (auto Pair : Map2) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto AtomicOp = new AtomicRMWInst(
              Pair.second, CI->getArgOperand(0), CI->getArgOperand(1),
              AtomicOrdering::SequentiallyConsistent, SyncScope::System, CI);

          CI->replaceAllUsesWith(AtomicOp);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = !ToRemoves.empty();

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceCross(Module &M) {

  std::vector<const char *> Names = {
      "_Z5crossDv4_fS_",
  };

  return replaceCallsWithValue(M, Names, [&M](CallInst *CI) {
    auto IntTy = Type::getInt32Ty(M.getContext());
    auto FloatTy = Type::getFloatTy(M.getContext());

    Constant *DownShuffleMask[3] = {ConstantInt::get(IntTy, 0),
                                    ConstantInt::get(IntTy, 1),
                                    ConstantInt::get(IntTy, 2)};

    Constant *UpShuffleMask[4] = {
        ConstantInt::get(IntTy, 0), ConstantInt::get(IntTy, 1),
        ConstantInt::get(IntTy, 2), ConstantInt::get(IntTy, 3)};

    Constant *FloatVec[3] = {ConstantFP::get(FloatTy, 0.0f),
                             UndefValue::get(FloatTy),
                             UndefValue::get(FloatTy)};

    auto Vec4Ty = CI->getArgOperand(0)->getType();
    auto Arg0 =
        new ShuffleVectorInst(CI->getArgOperand(0), UndefValue::get(Vec4Ty),
                              ConstantVector::get(DownShuffleMask), "", CI);
    auto Arg1 =
        new ShuffleVectorInst(CI->getArgOperand(1), UndefValue::get(Vec4Ty),
                              ConstantVector::get(DownShuffleMask), "", CI);
    auto Vec3Ty = Arg0->getType();

    auto NewFType = FunctionType::get(Vec3Ty, {Vec3Ty, Vec3Ty}, false);

    auto Cross3Func = M.getOrInsertFunction("_Z5crossDv3_fS_", NewFType);

    auto DownResult = CallInst::Create(Cross3Func, {Arg0, Arg1}, "", CI);

    return new ShuffleVectorInst(DownResult, ConstantVector::get(FloatVec),
                                 ConstantVector::get(UpShuffleMask), "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceFract(Module &M) {
  bool Changed = false;

  // OpenCL's   float result = fract(float x, float* ptr)
  //
  // In the LLVM domain:
  //
  //    %floor_result = call spir_func float @floor(float %x)
  //    store float %floor_result, float * %ptr
  //    %fract_intermediate = call spir_func float @clspv.fract(float %x)
  //    %result = call spir_func float
  //        @fmin(float %fract_intermediate, float 0x1.fffffep-1f)
  //
  // Becomes in the SPIR-V domain, where translations of floor, fmin,
  // and clspv.fract occur in the SPIR-V generator pass:
  //
  //    %glsl_ext = OpExtInstImport "GLSL.std.450"
  //    %just_under_1 = OpConstant %float 0x1.fffffep-1f
  //    ...
  //    %floor_result = OpExtInst %float %glsl_ext Floor %x
  //    OpStore %ptr %floor_result
  //    %fract_intermediate = OpExtInst %float %glsl_ext Fract %x
  //    %fract_result = OpExtInst %float
  //       %glsl_ext Fmin %fract_intermediate %just_under_1

  using std::string;

  // Mapping from the fract builtin to the floor, fmin, and clspv.fract builtins
  // we need.  The clspv.fract builtin is the same as GLSL.std.450 Fract.
  using QuadType =
      std::tuple<const char *, const char *, const char *, const char *>;
  auto make_quad = [](const char *a, const char *b, const char *c,
                      const char *d) {
    return std::tuple<const char *, const char *, const char *, const char *>(
        a, b, c, d);
  };
  const std::vector<QuadType> Functions = {
      make_quad("_Z5fractfPf", "_Z5floorff", "_Z4fminff", "clspv.fract.f"),
      make_quad("_Z5fractDv2_fPS_", "_Z5floorDv2_f", "_Z4fminDv2_ff",
                "clspv.fract.v2f"),
      make_quad("_Z5fractDv3_fPS_", "_Z5floorDv3_f", "_Z4fminDv3_ff",
                "clspv.fract.v3f"),
      make_quad("_Z5fractDv4_fPS_", "_Z5floorDv4_f", "_Z4fminDv4_ff",
                "clspv.fract.v4f"),
  };

  for (auto &quad : Functions) {
    const StringRef fract_name(std::get<0>(quad));

    // If we find a function with the matching name.
    if (auto F = M.getFunction(fract_name)) {
      if (F->use_begin() == F->use_end())
        continue;

      // We have some uses.
      Changed = true;

      auto &Context = M.getContext();

      const StringRef floor_name(std::get<1>(quad));
      const StringRef fmin_name(std::get<2>(quad));
      const StringRef clspv_fract_name(std::get<3>(quad));

      // This is either float or a float vector.  All the float-like
      // types are this type.
      auto result_ty = F->getReturnType();

      Function *fmin_fn = M.getFunction(fmin_name);
      if (!fmin_fn) {
        // Make the fmin function.
        FunctionType *fn_ty =
            FunctionType::get(result_ty, {result_ty, result_ty}, false);
        fmin_fn =
            cast<Function>(M.getOrInsertFunction(fmin_name, fn_ty).getCallee());
        fmin_fn->addFnAttr(Attribute::ReadNone);
        fmin_fn->setCallingConv(CallingConv::SPIR_FUNC);
      }

      Function *floor_fn = M.getFunction(floor_name);
      if (!floor_fn) {
        // Make the floor function.
        FunctionType *fn_ty = FunctionType::get(result_ty, {result_ty}, false);
        floor_fn = cast<Function>(
            M.getOrInsertFunction(floor_name, fn_ty).getCallee());
        floor_fn->addFnAttr(Attribute::ReadNone);
        floor_fn->setCallingConv(CallingConv::SPIR_FUNC);
      }

      Function *clspv_fract_fn = M.getFunction(clspv_fract_name);
      if (!clspv_fract_fn) {
        // Make the clspv_fract function.
        FunctionType *fn_ty = FunctionType::get(result_ty, {result_ty}, false);
        clspv_fract_fn = cast<Function>(
            M.getOrInsertFunction(clspv_fract_name, fn_ty).getCallee());
        clspv_fract_fn->addFnAttr(Attribute::ReadNone);
        clspv_fract_fn->setCallingConv(CallingConv::SPIR_FUNC);
      }

      // Number of significant significand bits, whether represented or not.
      unsigned num_significand_bits;
      switch (result_ty->getScalarType()->getTypeID()) {
      case Type::HalfTyID:
        num_significand_bits = 11;
        break;
      case Type::FloatTyID:
        num_significand_bits = 24;
        break;
      case Type::DoubleTyID:
        num_significand_bits = 53;
        break;
      default:
        assert(false && "Unhandled float type when processing fract builtin");
        break;
      }
      // Beware that the disassembler displays this value as
      //   OpConstant %float 1
      // which is not quite right.
      const double kJustUnderOneScalar =
          ldexp(double((1 << num_significand_bits) - 1), -num_significand_bits);

      Constant *just_under_one =
          ConstantFP::get(result_ty->getScalarType(), kJustUnderOneScalar);
      if (result_ty->isVectorTy()) {
        just_under_one = ConstantVector::getSplat(
            result_ty->getVectorNumElements(), just_under_one);
      }

      IRBuilder<> Builder(Context);

      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {

          Builder.SetInsertPoint(CI);
          auto arg = CI->getArgOperand(0);
          auto ptr = CI->getArgOperand(1);

          // Compute floor result and store it.
          auto floor = Builder.CreateCall(floor_fn, {arg});
          Builder.CreateStore(floor, ptr);

          auto fract_intermediate = Builder.CreateCall(clspv_fract_fn, arg);
          auto fract_result =
              Builder.CreateCall(fmin_fn, {fract_intermediate, just_under_one});

          CI->replaceAllUsesWith(fract_result);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      // And cleanup the calls we don't use anymore.
      for (auto V : ToRemoves) {
        V->eraseFromParent();
      }

      // And remove the function we don't need either too.
      F->eraseFromParent();
    }
  }

  return Changed;
}
