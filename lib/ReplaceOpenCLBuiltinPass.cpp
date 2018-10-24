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

#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "spirv/1.0/spirv.hpp"

#include "clspv/Option.h"

using namespace llvm;

#define DEBUG_TYPE "ReplaceOpenCLBuiltin"

namespace {
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

struct ReplaceOpenCLBuiltinPass final : public ModulePass {
  static char ID;
  ReplaceOpenCLBuiltinPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
  bool replaceRecip(Module &M);
  bool replaceDivide(Module &M);
  bool replaceExp10(Module &M);
  bool replaceLog10(Module &M);
  bool replaceBarrier(Module &M);
  bool replaceMemFence(Module &M);
  bool replaceRelational(Module &M);
  bool replaceIsInfAndIsNan(Module &M);
  bool replaceAllAndAny(Module &M);
  bool replaceSelect(Module &M);
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
  bool replaceReadImageF(Module &M);
  bool replaceAtomics(Module &M);
  bool replaceCross(Module &M);
  bool replaceFract(Module &M);
  bool replaceVload(Module &M);
  bool replaceVstore(Module &M);
};
}

char ReplaceOpenCLBuiltinPass::ID = 0;
static RegisterPass<ReplaceOpenCLBuiltinPass> X("ReplaceOpenCLBuiltin",
                                                "Replace OpenCL Builtins Pass");

namespace clspv {
ModulePass *createReplaceOpenCLBuiltinPass() {
  return new ReplaceOpenCLBuiltinPass();
}
}

bool ReplaceOpenCLBuiltinPass::runOnModule(Module &M) {
  bool Changed = false;

  Changed |= replaceRecip(M);
  Changed |= replaceDivide(M);
  Changed |= replaceExp10(M);
  Changed |= replaceLog10(M);
  Changed |= replaceBarrier(M);
  Changed |= replaceMemFence(M);
  Changed |= replaceRelational(M);
  Changed |= replaceIsInfAndIsNan(M);
  Changed |= replaceAllAndAny(M);
  Changed |= replaceSelect(M);
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
  Changed |= replaceReadImageF(M);
  Changed |= replaceAtomics(M);
  Changed |= replaceCross(M);
  Changed |= replaceFract(M);
  Changed |= replaceVload(M);
  Changed |= replaceVstore(M);

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceRecip(Module &M) {
  bool Changed = false;

  const char *Names[] = {
      "_Z10half_recipf",       "_Z12native_recipf",     "_Z10half_recipDv2_f",
      "_Z12native_recipDv2_f", "_Z10half_recipDv3_f",   "_Z12native_recipDv3_f",
      "_Z10half_recipDv4_f",   "_Z12native_recipDv4_f",
  };

  for (auto Name : Names) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // Recip has one arg.
          auto Arg = CI->getOperand(0);

          auto Div = BinaryOperator::Create(
              Instruction::FDiv, ConstantFP::get(Arg->getType(), 1.0), Arg, "",
              CI);

          CI->replaceAllUsesWith(Div);

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

bool ReplaceOpenCLBuiltinPass::replaceDivide(Module &M) {
  bool Changed = false;

  const char *Names[] = {
      "_Z11half_divideff",      "_Z13native_divideff",
      "_Z11half_divideDv2_fS_", "_Z13native_divideDv2_fS_",
      "_Z11half_divideDv3_fS_", "_Z13native_divideDv3_fS_",
      "_Z11half_divideDv4_fS_", "_Z13native_divideDv4_fS_",
  };

  for (auto Name : Names) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto Div = BinaryOperator::Create(
              Instruction::FDiv, CI->getOperand(0), CI->getOperand(1), "", CI);

          CI->replaceAllUsesWith(Div);

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
  bool Changed = false;

  enum { CLK_LOCAL_MEM_FENCE = 0x01, CLK_GLOBAL_MEM_FENCE = 0x02 };

  const std::map<const char *, const char *> Map = {
      {"_Z7barrierj", "__spirv_control_barrier"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto FType = F->getFunctionType();
          SmallVector<Type *, 3> Params;
          for (unsigned i = 0; i < 3; i++) {
            Params.push_back(FType->getParamType(0));
          }
          auto NewFType =
              FunctionType::get(FType->getReturnType(), Params, false);
          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

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
                                     ConstantSequentiallyConsistent, "", CI);
          MemorySemantics = BinaryOperator::Create(
              Instruction::Or, MemorySemantics, MemorySemanticsUniform, "", CI);

          // For Memory Scope if we used CLK_GLOBAL_MEM_FENCE, we need to use
          // Device Scope, otherwise Workgroup Scope.
          const auto Cmp =
              CmpInst::Create(Instruction::ICmp, CmpInst::ICMP_EQ,
                              GlobalMemFenceMask, GlobalMemFence, "", CI);
          const auto MemoryScope = SelectInst::Create(
              Cmp, ConstantScopeDevice, ConstantScopeWorkgroup, "", CI);

          // Lastly, the Execution Scope is always Workgroup Scope.
          const auto ExecutionScope = ConstantScopeWorkgroup;

          auto NewCI = CallInst::Create(
              NewF, {ExecutionScope, MemoryScope, MemorySemantics}, "", CI);

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

bool ReplaceOpenCLBuiltinPass::replaceMemFence(Module &M) {
  bool Changed = false;

  enum { CLK_LOCAL_MEM_FENCE = 0x01, CLK_GLOBAL_MEM_FENCE = 0x02 };

  using Tuple = std::tuple<const char *, unsigned>;
  const std::map<const char *, Tuple> Map = {
      {"_Z9mem_fencej",
       Tuple("__spirv_memory_barrier",
        spv::MemorySemanticsSequentiallyConsistentMask)},
      {"_Z14read_mem_fencej",
       Tuple("__spirv_memory_barrier", spv::MemorySemanticsAcquireMask)},
      {"_Z15write_mem_fencej",
       Tuple("__spirv_memory_barrier", spv::MemorySemanticsReleaseMask)}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto FType = F->getFunctionType();
          SmallVector<Type *, 2> Params;
          for (unsigned i = 0; i < 2; i++) {
            Params.push_back(FType->getParamType(0));
          }
          auto NewFType =
              FunctionType::get(FType->getReturnType(), Params, false);
          auto NewF = M.getOrInsertFunction(std::get<0>(Pair.second), NewFType);

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

          auto NewCI =
              CallInst::Create(NewF, {MemoryScope, MemorySemantics}, "", CI);

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

  const std::map<const char *, std::pair<const char *, int32_t>> Map = {
      {"_Z5isinff", {"__spirv_isinff", 1}},
      {"_Z5isinfDv2_f", {"__spirv_isinfDv2_f", -1}},
      {"_Z5isinfDv3_f", {"__spirv_isinfDv3_f", -1}},
      {"_Z5isinfDv4_f", {"__spirv_isinfDv4_f", -1}},
      {"_Z5isnanf", {"__spirv_isnanf", 1}},
      {"_Z5isnanDv2_f", {"__spirv_isnanDv2_f", -1}},
      {"_Z5isnanDv3_f", {"__spirv_isnanDv3_f", -1}},
      {"_Z5isnanDv4_f", {"__spirv_isnanDv4_f", -1}},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          const auto CITy = CI->getType();

          // The fake SPIR-V intrinsic to generate.
          auto SPIRVIntrinsic = Pair.second.first;

          // The value to return for true.
          auto TrueValue = ConstantInt::getSigned(CITy, Pair.second.second);

          // The value to return for false.
          auto FalseValue = Constant::getNullValue(CITy);

          const auto CorrespondingBoolTy = getBoolOrBoolVectorTy(
              M.getContext(),
              CITy->isVectorTy() ? CITy->getVectorNumElements() : 1);

          auto NewFType =
              FunctionType::get(CorrespondingBoolTy,
                                F->getFunctionType()->getParamType(0), false);

          auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

          auto Arg = CI->getOperand(0);

          auto NewCI = CallInst::Create(NewF, Arg, "", CI);

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

bool ReplaceOpenCLBuiltinPass::replaceAllAndAny(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char *> Map = {
      {"_Z3alli", ""},
      {"_Z3allDv2_i", "__spirv_allDv2_i"},
      {"_Z3allDv3_i", "__spirv_allDv3_i"},
      {"_Z3allDv4_i", "__spirv_allDv4_i"},
      {"_Z3anyi", ""},
      {"_Z3anyDv2_i", "__spirv_anyDv2_i"},
      {"_Z3anyDv3_i", "__spirv_anyDv3_i"},
      {"_Z3anyDv4_i", "__spirv_anyDv4_i"},
  };

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The fake SPIR-V intrinsic to generate.
          auto SPIRVIntrinsic = Pair.second;

          auto Arg = CI->getOperand(0);

          Value *V;

          // If we have a function to call, call it!
          if (0 < strlen(SPIRVIntrinsic)) {
            // The value for zero to compare against.
            const auto ZeroValue = Constant::getNullValue(Arg->getType());

            const auto Cmp = CmpInst::Create(
                Instruction::ICmp, CmpInst::ICMP_SLT, Arg, ZeroValue, "", CI);
            const auto NewFType = FunctionType::get(
                Type::getInt1Ty(M.getContext()), Cmp->getType(), false);

            const auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

            const auto NewCI = CallInst::Create(NewF, Cmp, "", CI);

            // The value to return for true.
            const auto TrueValue = ConstantInt::get(CI->getType(), 1);

            // The value to return for false.
            const auto FalseValue = Constant::getNullValue(CI->getType());

            V = SelectInst::Create(NewCI, TrueValue, FalseValue, "", CI);
          } else {
            V = BinaryOperator::Create(Instruction::LShr, Arg,
                                       ConstantInt::get(CI->getType(), 31), "",
                                       CI);
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

  struct VectorStoreOps {
    const char* name;
    int n;
    Type* (*get_scalar_type_function)(LLVMContext&);
  } vector_store_ops[] = {
    // TODO(derekjchow): Expand this list.
    { "_Z7vstore4Dv4_fjPU3AS1f", 4, Type::getFloatTy }
  };

  for (const auto& Op : vector_store_ops) {
    auto Name = Op.name;
    auto N = Op.n;
    auto TypeFn = Op.get_scalar_type_function;
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The value argument from vstoren.
          auto Arg0 = CI->getOperand(0);

          // The index argument from vstoren.
          auto Arg1 = CI->getOperand(1);

          // The pointer argument from vstoren.
          auto Arg2 = CI->getOperand(2);

          // Get types.
          auto ScalarNTy = VectorType::get(TypeFn(M.getContext()), N);
          auto ScalarNPointerTy = PointerType::get(
              ScalarNTy, Arg2->getType()->getPointerAddressSpace());

          // Cast to scalarn
          auto Cast = CastInst::CreatePointerCast(
              Arg2, ScalarNPointerTy, "", CI);
          // Index to correct address
          auto Index = GetElementPtrInst::Create(ScalarNTy, Cast, Arg1, "", CI);
          // Store
          auto Store = new StoreInst(Arg0, Index, CI);

          CI->replaceAllUsesWith(Store);
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

bool ReplaceOpenCLBuiltinPass::replaceVload(Module &M) {
  bool Changed = false;

  struct VectorLoadOps {
    const char* name;
    int n;
    Type* (*get_scalar_type_function)(LLVMContext&);
  } vector_load_ops[] = {
    // TODO(derekjchow): Expand this list.
    { "_Z6vload4jPU3AS1Kf", 4, Type::getFloatTy }
  };

  for (const auto& Op : vector_load_ops) {
    auto Name = Op.name;
    auto N = Op.n;
    auto TypeFn = Op.get_scalar_type_function;
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The index argument from vloadn.
          auto Arg0 = CI->getOperand(0);

          // The pointer argument from vloadn.
          auto Arg1 = CI->getOperand(1);

          // Get types.
          auto ScalarNTy = VectorType::get(TypeFn(M.getContext()), N);
          auto ScalarNPointerTy = PointerType::get(
              ScalarNTy, Arg1->getType()->getPointerAddressSpace());

          // Cast to scalarn
          auto Cast = CastInst::CreatePointerCast(
              Arg1, ScalarNPointerTy, "", CI);
          // Index to correct address
          auto Index = GetElementPtrInst::Create(ScalarNTy, Cast, Arg0, "", CI);
          // Load
          auto Load = new LoadInst(Index, "", CI);

          CI->replaceAllUsesWith(Load);
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
  bool Changed = false;

  const std::vector<const char *> Map = {
      "_Z11vload_half2jPU3AS1KDh",
      "_Z12vloada_half2jPU3AS1KDh", // vloada_half2 global
      "_Z11vload_half2jPU3AS2KDh",
      "_Z12vloada_half2jPU3AS2KDh", // vloada_half2 constant
  };

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
          auto NewPointerTy = PointerType::get(
              IntTy, Arg1->getType()->getPointerAddressSpace());
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
          auto Call = CallInst::Create(NewF, Load, "", CI);

          CI->replaceAllUsesWith(Call);

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

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf4(Module &M) {
  bool Changed = false;

  const std::vector<const char *> Map = {
      "_Z11vload_half4jPU3AS1KDh",
      "_Z12vloada_half4jPU3AS1KDh",
      "_Z11vload_half4jPU3AS2KDh",
      "_Z12vloada_half4jPU3AS2KDh",
  };

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
          auto Int2Ty = VectorType::get(IntTy, 2);
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewPointerTy = PointerType::get(
              Int2Ty, Arg1->getType()->getPointerAddressSpace());
          auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

          // Cast the half* pointer to int2*.
          auto Cast = CastInst::CreatePointerCast(Arg1, NewPointerTy, "", CI);

          // Index into the correct address of the casted pointer.
          auto Index = GetElementPtrInst::Create(Int2Ty, Cast, Arg0, "", CI);

          // Load from the int2* we casted to.
          auto Load = new LoadInst(Index, "", CI);

          // Extract each element from the loaded int2.
          auto X = ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0),
                                              "", CI);
          auto Y = ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1),
                                              "", CI);

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
          auto Combine = new ShuffleVectorInst(
              Lo, Hi, ConstantVector::get(ShuffleMask), "", CI);

          CI->replaceAllUsesWith(Combine);

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

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf2(Module &M) {
  bool Changed = false;

  // Replace __clspv_vloada_half2(uint Index, global uint* Ptr) with:
  //
  //    %u = load i32 %ptr
  //    %fxy = call <2 x float> Unpack2xHalf(u)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  const std::vector<const char *> Map = {
      "_Z20__clspv_vloada_half2jPU3AS1Kj", // global
      "_Z20__clspv_vloada_half2jPU3AS3Kj", // local
      "_Z20__clspv_vloada_half2jPKj",      // private
  };

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto* CI = dyn_cast<CallInst>(U.getUser())) {
          auto Index = CI->getOperand(0);
          auto Ptr = CI->getOperand(1);

          auto IntTy = Type::getInt32Ty(M.getContext());
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

          auto IndexedPtr =
              GetElementPtrInst::Create(IntTy, Ptr, Index, "", CI);
          auto Load = new LoadInst(IndexedPtr, "", CI);

          // Our intrinsic to unpack a float2 from an int.
          auto SPIRVIntrinsic = "spirv.unpack.v2f16";

          auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

          // Get our final float2.
          auto Result = CallInst::Create(NewF, Load, "", CI);

          CI->replaceAllUsesWith(Result);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = true;

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

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf4(Module &M) {
  bool Changed = false;

  // Replace __clspv_vloada_half4(uint Index, global uint2* Ptr) with:
  //
  //    %u2 = load <2 x i32> %ptr
  //    %u2xy = extractelement %u2, 0
  //    %u2zw = extractelement %u2, 1
  //    %fxy = call <2 x float> Unpack2xHalf(uint)
  //    %fzw = call <2 x float> Unpack2xHalf(uint)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  const std::vector<const char *> Map = {
      "_Z20__clspv_vloada_half4jPU3AS1KDv2_j", // global
      "_Z20__clspv_vloada_half4jPU3AS3KDv2_j", // local
      "_Z20__clspv_vloada_half4jPKDv2_j",      // private
  };

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto Index = CI->getOperand(0);
          auto Ptr = CI->getOperand(1);

          auto IntTy = Type::getInt32Ty(M.getContext());
          auto Int2Ty = VectorType::get(IntTy, 2);
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

          auto IndexedPtr =
              GetElementPtrInst::Create(Int2Ty, Ptr, Index, "", CI);
          auto Load = new LoadInst(IndexedPtr, "", CI);

          // Extract each element from the loaded int2.
          auto X = ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0),
                                              "", CI);
          auto Y = ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1),
                                              "", CI);

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
          auto Combine = new ShuffleVectorInst(
              Lo, Hi, ConstantVector::get(ShuffleMask), "", CI);

          CI->replaceAllUsesWith(Combine);

          // Lastly, remember to remove the user.
          ToRemoves.push_back(CI);
        }
      }

      Changed = true;

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

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf(Module &M) {
  bool Changed = false;

  const std::vector<const char *> Map = {"_Z11vstore_halffjPU3AS1Dh",
                                         "_Z15vstore_half_rtefjPU3AS1Dh",
                                         "_Z15vstore_half_rtzfjPU3AS1Dh"};

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
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
          auto TempVec =
              InsertElementInst::Create(UndefValue::get(Float2Ty), Arg0,
                                        ConstantInt::get(IntTy, 0), "", CI);

          // Pack the float2 -> half2 (in an int).
          auto X = CallInst::Create(NewF, TempVec, "", CI);

          if (clspv::Option::F16BitStorage()) {
            auto ShortTy = Type::getInt16Ty(M.getContext());
            auto ShortPointerTy = PointerType::get(
                ShortTy, Arg2->getType()->getPointerAddressSpace());

            // Truncate our i32 to an i16.
            auto Trunc = CastInst::CreateTruncOrBitCast(X, ShortTy, "", CI);

            // Cast the half* pointer to short*.
            auto Cast = CastInst::CreatePointerCast(Arg2, ShortPointerTy, "", CI);

            // Index into the correct address of the casted pointer.
            auto Index = GetElementPtrInst::Create(ShortTy, Cast, Arg1, "", CI);

            // Store to the int* we casted to.
            auto Store = new StoreInst(Trunc, Index, CI);

            CI->replaceAllUsesWith(Store);
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
            auto IntPointerTy = PointerType::get(
                IntTy, Arg2->getType()->getPointerAddressSpace());

            auto Four = ConstantInt::get(IntTy, 4);
            auto FFFF = ConstantInt::get(IntTy, 0xffff);

            auto IndexIsOdd = BinaryOperator::CreateAnd(Arg1, One, "index_is_odd_i32", CI);
            // Compute index / 2
            auto IndexIntoI32 = BinaryOperator::CreateLShr(Arg1, One, "index_into_i32", CI);
            auto BaseI32Ptr = CastInst::CreatePointerCast(Arg2, IntPointerTy, "base_i32_ptr", CI);
            auto OutPtr = GetElementPtrInst::Create(IntTy, BaseI32Ptr, IndexIntoI32, "base_i32_ptr", CI);
            auto CurrentValue = new LoadInst(OutPtr, "current_value", CI);
            auto Shift = BinaryOperator::CreateShl(IndexIsOdd, Four, "shift", CI);
            auto MaskBitsToWrite = BinaryOperator::CreateShl(FFFF, Shift, "mask_bits_to_write", CI);
            auto MaskedCurrent = BinaryOperator::CreateAnd(MaskBitsToWrite, CurrentValue, "masked_current", CI);

            auto XLowerBits = BinaryOperator::CreateAnd(X, FFFF, "lower_bits_of_packed", CI);
            auto NewBitsToWrite = BinaryOperator::CreateShl(XLowerBits, Shift, "new_bits_to_write", CI);
            auto ValueToXor = BinaryOperator::CreateXor(MaskedCurrent, NewBitsToWrite, "value_to_xor", CI);

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

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf2(Module &M) {
  bool Changed = false;

  const std::vector<const char *> Map = {
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

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The value to store.
          auto Arg0 = CI->getOperand(0);

          // The index argument from vstore_half.
          auto Arg1 = CI->getOperand(1);

          // The pointer argument from vstore_half.
          auto Arg2 = CI->getOperand(2);

          auto IntTy = Type::getInt32Ty(M.getContext());
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewPointerTy = PointerType::get(
              IntTy, Arg2->getType()->getPointerAddressSpace());
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
          auto Store = new StoreInst(X, Index, CI);

          CI->replaceAllUsesWith(Store);

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

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf4(Module &M) {
  bool Changed = false;

  const std::vector<const char *> Map = {
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

  for (auto Name : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Name)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          // The value to store.
          auto Arg0 = CI->getOperand(0);

          // The index argument from vstore_half.
          auto Arg1 = CI->getOperand(1);

          // The pointer argument from vstore_half.
          auto Arg2 = CI->getOperand(2);

          auto IntTy = Type::getInt32Ty(M.getContext());
          auto Int2Ty = VectorType::get(IntTy, 2);
          auto Float2Ty = VectorType::get(Type::getFloatTy(M.getContext()), 2);
          auto NewPointerTy = PointerType::get(
              Int2Ty, Arg2->getType()->getPointerAddressSpace());
          auto NewFType = FunctionType::get(IntTy, Float2Ty, false);

          Constant *LoShuffleMask[2] = {ConstantInt::get(IntTy, 0),
                                        ConstantInt::get(IntTy, 1)};

          // Extract out the x & y components of our to store value.
          auto Lo =
              new ShuffleVectorInst(Arg0, UndefValue::get(Arg0->getType()),
                                    ConstantVector::get(LoShuffleMask), "", CI);

          Constant *HiShuffleMask[2] = {ConstantInt::get(IntTy, 2),
                                        ConstantInt::get(IntTy, 3)};

          // Extract out the z & w components of our to store value.
          auto Hi =
              new ShuffleVectorInst(Arg0, UndefValue::get(Arg0->getType()),
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
          Combine = InsertElementInst::Create(
              Combine, Y, ConstantInt::get(IntTy, 1), "", CI);

          // Cast the half* pointer to int2*.
          auto Cast = CastInst::CreatePointerCast(Arg2, NewPointerTy, "", CI);

          // Index into the correct address of the casted pointer.
          auto Index = GetElementPtrInst::Create(Int2Ty, Cast, Arg1, "", CI);

          // Store to the int2* we casted to.
          auto Store = new StoreInst(Combine, Index, CI);

          CI->replaceAllUsesWith(Store);

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

bool ReplaceOpenCLBuiltinPass::replaceReadImageF(Module &M) {
  bool Changed = false;

  const std::map<const char *, const char*> Map = {
    { "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i", "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f" },
    { "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv4_i", "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv4_f" }
  };

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

          auto FloatVecTy = VectorType::get(Type::getFloatTy(M.getContext()), Arg2->getType()->getVectorNumElements());

          auto NewFType = FunctionType::get(CI->getType(), {Arg0->getType(), Arg1->getType(), FloatVecTy}, false);

          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

          auto Cast = CastInst::Create(Instruction::SIToFP, Arg2, FloatVecTy, "", CI);

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

  const std::map<const char *, const char *> Map = {
      {"_Z10atomic_incPU3AS1Vi", "spirv.atomic_inc"},
      {"_Z10atomic_incPU3AS1Vj", "spirv.atomic_inc"},
      {"_Z10atomic_decPU3AS1Vi", "spirv.atomic_dec"},
      {"_Z10atomic_decPU3AS1Vj", "spirv.atomic_dec"},
      {"_Z14atomic_cmpxchgPU3AS1Viii", "spirv.atomic_compare_exchange"},
      {"_Z14atomic_cmpxchgPU3AS1Vjjj", "spirv.atomic_compare_exchange"}};

  for (auto Pair : Map) {
    // If we find a function with the matching name.
    if (auto F = M.getFunction(Pair.first)) {
      SmallVector<Instruction *, 4> ToRemoves;

      // Walk the users of the function.
      for (auto &U : F->uses()) {
        if (auto CI = dyn_cast<CallInst>(U.getUser())) {
          auto FType = F->getFunctionType();
          SmallVector<Type *, 5> ParamTypes;

          // The pointer type.
          ParamTypes.push_back(FType->getParamType(0));

          auto IntTy = Type::getInt32Ty(M.getContext());

          // The memory scope type.
          ParamTypes.push_back(IntTy);

          // The memory semantics type.
          ParamTypes.push_back(IntTy);

          if (2 < CI->getNumArgOperands()) {
            // The unequal memory semantics type.
            ParamTypes.push_back(IntTy);

            // The value type.
            ParamTypes.push_back(FType->getParamType(2));

            // The comparator type.
            ParamTypes.push_back(FType->getParamType(1));
          } else if (1 < CI->getNumArgOperands()) {
            // The value type.
            ParamTypes.push_back(FType->getParamType(1));
          }

          auto NewFType =
              FunctionType::get(FType->getReturnType(), ParamTypes, false);
          auto NewF = M.getOrInsertFunction(Pair.second, NewFType);

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

          auto NewCI = CallInst::Create(NewF, Params, "", CI);

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
      {"_Z10atomic_addPU3AS1Vii", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_addPU3AS1Vjj", llvm::AtomicRMWInst::Add},
      {"_Z10atomic_subPU3AS1Vii", llvm::AtomicRMWInst::Sub},
      {"_Z10atomic_subPU3AS1Vjj", llvm::AtomicRMWInst::Sub},
      {"_Z11atomic_xchgPU3AS1Vii", llvm::AtomicRMWInst::Xchg},
      {"_Z11atomic_xchgPU3AS1Vjj", llvm::AtomicRMWInst::Xchg},
      {"_Z10atomic_minPU3AS1Vii", llvm::AtomicRMWInst::Min},
      {"_Z10atomic_minPU3AS1Vjj", llvm::AtomicRMWInst::UMin},
      {"_Z10atomic_maxPU3AS1Vii", llvm::AtomicRMWInst::Max},
      {"_Z10atomic_maxPU3AS1Vjj", llvm::AtomicRMWInst::UMax},
      {"_Z10atomic_andPU3AS1Vii", llvm::AtomicRMWInst::And},
      {"_Z10atomic_andPU3AS1Vjj", llvm::AtomicRMWInst::And},
      {"_Z9atomic_orPU3AS1Vii", llvm::AtomicRMWInst::Or},
      {"_Z9atomic_orPU3AS1Vjj", llvm::AtomicRMWInst::Or},
      {"_Z10atomic_xorPU3AS1Vii", llvm::AtomicRMWInst::Xor},
      {"_Z10atomic_xorPU3AS1Vjj", llvm::AtomicRMWInst::Xor}};

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
  bool Changed = false;

  // If we find a function with the matching name.
  if (auto F = M.getFunction("_Z5crossDv4_fS_")) {
    SmallVector<Instruction *, 4> ToRemoves;

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto FloatTy = Type::getFloatTy(M.getContext());

    Constant *DownShuffleMask[3] = {
        ConstantInt::get(IntTy, 0), ConstantInt::get(IntTy, 1),
        ConstantInt::get(IntTy, 2)};

    Constant *UpShuffleMask[4] = {
        ConstantInt::get(IntTy, 0), ConstantInt::get(IntTy, 1),
        ConstantInt::get(IntTy, 2), ConstantInt::get(IntTy, 3)};

    Constant *FloatVec[3] = {
      ConstantFP::get(FloatTy, 0.0f), UndefValue::get(FloatTy), UndefValue::get(FloatTy)
    };

    // Walk the users of the function.
    for (auto &U : F->uses()) {
      if (auto CI = dyn_cast<CallInst>(U.getUser())) {
        auto Vec4Ty = CI->getArgOperand(0)->getType();
        auto Arg0 = new ShuffleVectorInst(CI->getArgOperand(0), UndefValue::get(Vec4Ty), ConstantVector::get(DownShuffleMask), "", CI);
        auto Arg1 = new ShuffleVectorInst(CI->getArgOperand(1), UndefValue::get(Vec4Ty), ConstantVector::get(DownShuffleMask), "", CI);
        auto Vec3Ty = Arg0->getType();

        auto NewFType =
            FunctionType::get(Vec3Ty, {Vec3Ty, Vec3Ty}, false);

        auto Cross3Func = M.getOrInsertFunction("_Z5crossDv3_fS_", NewFType);

        auto DownResult = CallInst::Create(Cross3Func, {Arg0, Arg1}, "", CI);

        auto Result = new ShuffleVectorInst(DownResult, ConstantVector::get(FloatVec), ConstantVector::get(UpShuffleMask), "", CI);

        CI->replaceAllUsesWith(Result);

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
  using QuadType = std::tuple<const char *, const char *, const char *, const char *>;
  auto make_quad = [](const char *a, const char *b, const char *c,
                      const char *d) {
    return std::tuple<const char *, const char *, const char *, const char *>(
        a, b, c, d);
  };
  const std::vector<QuadType> Functions = {
      make_quad("_Z5fractfPf", "_Z5floorff", "_Z4fminff", "clspv.fract.f"),
      make_quad("_Z5fractDv2_fPS_", "_Z5floorDv2_f", "_Z4fminDv2_ff", "clspv.fract.v2f"),
      make_quad("_Z5fractDv3_fPS_", "_Z5floorDv3_f", "_Z4fminDv3_ff", "clspv.fract.v3f"),
      make_quad("_Z5fractDv4_fPS_", "_Z5floorDv4_f", "_Z4fminDv4_ff", "clspv.fract.v4f"),
  };

  for (auto& quad : Functions) {
    const StringRef fract_name(std::get<0>(quad));

    // If we find a function with the matching name.
    if (auto F = M.getFunction(fract_name)) {
      if (F->use_begin() == F->use_end())
        continue;

      // We have some uses.
      Changed = true;

      auto& Context = M.getContext();

      const StringRef floor_name(std::get<1>(quad));
      const StringRef fmin_name(std::get<2>(quad));
      const StringRef clspv_fract_name(std::get<3>(quad));

      // This is either float or a float vector.  All the float-like
      // types are this type.
      auto result_ty = F->getReturnType();

      Function* fmin_fn = M.getFunction(fmin_name);
      if (!fmin_fn) {
        // Make the fmin function.
        FunctionType* fn_ty = FunctionType::get(result_ty, {result_ty, result_ty}, false);
        fmin_fn = cast<Function>(M.getOrInsertFunction(fmin_name, fn_ty));
        fmin_fn->addFnAttr(Attribute::ReadNone);
        fmin_fn->setCallingConv(CallingConv::SPIR_FUNC);
      }

      Function* floor_fn = M.getFunction(floor_name);
      if (!floor_fn) {
        // Make the floor function.
        FunctionType* fn_ty = FunctionType::get(result_ty, {result_ty}, false);
        floor_fn = cast<Function>(M.getOrInsertFunction(floor_name, fn_ty));
        floor_fn->addFnAttr(Attribute::ReadNone);
        floor_fn->setCallingConv(CallingConv::SPIR_FUNC);
      }

      Function* clspv_fract_fn = M.getFunction(clspv_fract_name);
      if (!clspv_fract_fn) {
        // Make the clspv_fract function.
        FunctionType* fn_ty = FunctionType::get(result_ty, {result_ty}, false);
        clspv_fract_fn = cast<Function>(M.getOrInsertFunction(clspv_fract_name, fn_ty));
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
          auto fract_result = Builder.CreateCall(fmin_fn, {fract_intermediate, just_under_one});

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
