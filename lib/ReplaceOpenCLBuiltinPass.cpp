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
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "spirv/unified1/spirv.hpp"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "Builtins.h"
#include "Constants.h"
#include "Passes.h"
#include "SPIRVOp.h"
#include "Types.h"

using namespace clspv;
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

Type *getIntOrIntVectorTyForCast(LLVMContext &C, Type *Ty) {
  Type *IntTy = Type::getIntNTy(C, Ty->getScalarSizeInBits());
  if (auto vec_ty = dyn_cast<VectorType>(Ty)) {
    IntTy = FixedVectorType::get(IntTy,
                                 vec_ty->getElementCount().getKnownMinValue());
  }
  return IntTy;
}

Value *MemoryOrderSemantics(Value *order, bool is_global,
                            Instruction *InsertBefore,
                            spv::MemorySemanticsMask base_semantics) {
  enum AtomicMemoryOrder : uint32_t {
    kMemoryOrderRelaxed = 0,
    kMemoryOrderAcquire = 2,
    kMemoryOrderRelease = 3,
    kMemoryOrderAcqRel = 4,
    kMemoryOrderSeqCst = 5
  };

  IRBuilder<> builder(InsertBefore);

  // Constants for OpenCL C 2.0 memory_order.
  const auto relaxed = builder.getInt32(AtomicMemoryOrder::kMemoryOrderRelaxed);
  const auto acquire = builder.getInt32(AtomicMemoryOrder::kMemoryOrderAcquire);
  const auto release = builder.getInt32(AtomicMemoryOrder::kMemoryOrderRelease);
  const auto acq_rel = builder.getInt32(AtomicMemoryOrder::kMemoryOrderAcqRel);

  // Constants for SPIR-V ordering memory semantics.
  const auto RelaxedSemantics = builder.getInt32(spv::MemorySemanticsMaskNone);
  const auto AcquireSemantics =
      builder.getInt32(spv::MemorySemanticsAcquireMask);
  const auto ReleaseSemantics =
      builder.getInt32(spv::MemorySemanticsReleaseMask);
  const auto AcqRelSemantics =
      builder.getInt32(spv::MemorySemanticsAcquireReleaseMask);

  // Constants for SPIR-V storage class semantics.
  const auto UniformSemantics =
      builder.getInt32(spv::MemorySemanticsUniformMemoryMask);
  const auto WorkgroupSemantics =
      builder.getInt32(spv::MemorySemanticsWorkgroupMemoryMask);

  // Instead of sequentially consistent, use acquire, release or acquire
  // release semantics.
  Value *base_order = nullptr;
  switch (base_semantics) {
  case spv::MemorySemanticsAcquireMask:
    base_order = AcquireSemantics;
    break;
  case spv::MemorySemanticsReleaseMask:
    base_order = ReleaseSemantics;
    break;
  default:
    base_order = AcqRelSemantics;
    break;
  }

  Value *storage = is_global ? UniformSemantics : WorkgroupSemantics;
  if (order == nullptr)
    return builder.CreateOr({storage, base_order});

  auto is_relaxed = builder.CreateICmpEQ(order, relaxed);
  auto is_acquire = builder.CreateICmpEQ(order, acquire);
  auto is_release = builder.CreateICmpEQ(order, release);
  auto is_acq_rel = builder.CreateICmpEQ(order, acq_rel);
  auto semantics =
      builder.CreateSelect(is_relaxed, RelaxedSemantics, base_order);
  semantics = builder.CreateSelect(is_acquire, AcquireSemantics, semantics);
  semantics = builder.CreateSelect(is_release, ReleaseSemantics, semantics);
  semantics = builder.CreateSelect(is_acq_rel, AcqRelSemantics, semantics);
  return builder.CreateOr({storage, semantics});
}

Value *MemoryScope(Value *scope, bool is_global, Instruction *InsertBefore) {
  enum AtomicMemoryScope : uint32_t {
    kMemoryScopeWorkItem = 0,
    kMemoryScopeWorkGroup = 1,
    kMemoryScopeDevice = 2,
    kMemoryScopeAllSVMDevices = 3, // not supported
    kMemoryScopeSubGroup = 4
  };

  IRBuilder<> builder(InsertBefore);

  // Constants for OpenCL C 2.0 memory_scope.
  const auto work_item =
      builder.getInt32(AtomicMemoryScope::kMemoryScopeWorkItem);
  const auto work_group =
      builder.getInt32(AtomicMemoryScope::kMemoryScopeWorkGroup);
  const auto sub_group =
      builder.getInt32(AtomicMemoryScope::kMemoryScopeSubGroup);
  const auto device = builder.getInt32(AtomicMemoryScope::kMemoryScopeDevice);

  // Constants for SPIR-V memory scopes.
  const auto InvocationScope = builder.getInt32(spv::ScopeInvocation);
  const auto WorkgroupScope = builder.getInt32(spv::ScopeWorkgroup);
  const auto DeviceScope = builder.getInt32(spv::ScopeDevice);
  const auto SubgroupScope = builder.getInt32(spv::ScopeSubgroup);

  auto base_scope = is_global ? DeviceScope : WorkgroupScope;
  if (scope == nullptr)
    return base_scope;

  auto is_work_item = builder.CreateICmpEQ(scope, work_item);
  auto is_work_group = builder.CreateICmpEQ(scope, work_group);
  auto is_sub_group = builder.CreateICmpEQ(scope, sub_group);
  auto is_device = builder.CreateICmpEQ(scope, device);

  scope = builder.CreateSelect(is_work_item, InvocationScope, base_scope);
  scope = builder.CreateSelect(is_work_group, WorkgroupScope, scope);
  scope = builder.CreateSelect(is_sub_group, SubgroupScope, scope);
  scope = builder.CreateSelect(is_device, DeviceScope, scope);

  return scope;
}

bool replaceCallsWithValue(Function &F,
                           std::function<Value *(CallInst *)> Replacer) {

  bool Changed = false;

  SmallVector<Instruction *, 4> ToRemoves;

  // Walk the users of the function.
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {

      auto NewValue = Replacer(CI);

      if (NewValue != nullptr) {
        CI->replaceAllUsesWith(NewValue);

        // Lastly, remember to remove the user.
        ToRemoves.push_back(CI);
      }
    }
  }

  Changed = !ToRemoves.empty();

  // And cleanup the calls we don't use anymore.
  for (auto V : ToRemoves) {
    V->eraseFromParent();
  }

  return Changed;
}

struct ReplaceOpenCLBuiltinPass final : public ModulePass {
  static char ID;
  ReplaceOpenCLBuiltinPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

private:
  bool runOnFunction(Function &F);
  bool replaceAbs(Function &F);
  bool replaceAbsDiff(Function &F, bool is_signed);
  bool replaceCopysign(Function &F);
  bool replaceRecip(Function &F);
  bool replaceDivide(Function &F);
  bool replaceDot(Function &F);
  bool replaceFmod(Function &F);
  bool replaceExp10(Function &F, const std::string &basename);
  bool replaceLog10(Function &F, const std::string &basename);
  bool replaceLog1p(Function &F);
  bool replaceBarrier(Function &F, bool subgroup = false);
  bool replaceMemFence(Function &F, uint32_t semantics);
  bool replacePrefetch(Function &F);
  bool replaceRelational(Function &F, CmpInst::Predicate P);
  bool replaceIsInfAndIsNan(Function &F, spv::Op SPIRVOp, int32_t isvec);
  bool replaceIsFinite(Function &F);
  bool replaceAllAndAny(Function &F, spv::Op SPIRVOp);
  bool replaceUpsample(Function &F);
  bool replaceRotate(Function &F);
  bool replaceConvert(Function &F, bool SrcIsSigned, bool DstIsSigned);
  bool replaceMulHi(Function &F, bool is_signed, bool is_mad = false);
  bool replaceSelect(Function &F);
  bool replaceBitSelect(Function &F);
  bool replaceStep(Function &F, bool is_smooth);
  bool replaceSignbit(Function &F, bool is_vec);
  bool replaceMul(Function &F, bool is_float, bool is_mad);
  bool replaceVloadHalf(Function &F, const std::string &name, int vec_size);
  bool replaceVloadHalf(Function &F);
  bool replaceVloadHalf2(Function &F);
  bool replaceVloadHalf4(Function &F);
  bool replaceClspvVloadaHalf2(Function &F);
  bool replaceClspvVloadaHalf4(Function &F);
  bool replaceVstoreHalf(Function &F, int vec_size);
  bool replaceVstoreHalf(Function &F);
  bool replaceVstoreHalf2(Function &F);
  bool replaceVstoreHalf4(Function &F);
  bool replaceHalfReadImage(Function &F);
  bool replaceHalfWriteImage(Function &F);
  bool replaceSampledReadImageWithIntCoords(Function &F);
  bool replaceAtomics(Function &F, spv::Op Op);
  bool replaceAtomics(Function &F, llvm::AtomicRMWInst::BinOp Op);
  bool replaceAtomicLoad(Function &F);
  bool replaceExplicitAtomics(Function &F, spv::Op Op,
                              spv::MemorySemanticsMask semantics =
                                  spv::MemorySemanticsAcquireReleaseMask);
  bool replaceAtomicCompareExchange(Function &);
  bool replaceCross(Function &F);
  bool replaceFract(Function &F, int vec_size);
  bool replaceVload(Function &F);
  bool replaceVstore(Function &F);
  bool replaceAddSubSat(Function &F, bool is_signed, bool is_add);
  bool replaceHadd(Function &F, bool is_signed,
                   Instruction::BinaryOps join_opcode);
  bool replaceCountZeroes(Function &F, bool leading);
  bool replaceMadSat(Function &F, bool is_signed);
  bool replaceOrdered(Function &F, bool is_ordered);
  bool replaceIsNormal(Function &F);
  bool replaceFDim(Function &F);

  // Caches struct types for { |type|, |type| }. This prevents
  // getOrInsertFunction from introducing a bitcasts between structs with
  // identical contents.
  Type *GetPairStruct(Type *type);

  DenseMap<Type *, Type *> PairStructMap;
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
  std::list<Function *> func_list;
  for (auto &F : M.getFunctionList()) {
    // process only function declarations
    if (F.isDeclaration() && runOnFunction(F)) {
      func_list.push_front(&F);
    }
  }
  if (func_list.size() != 0) {
    // recursively convert functions, but first remove dead
    for (auto *F : func_list) {
      if (F->use_empty()) {
        F->eraseFromParent();
      }
    }
    runOnModule(M);
    return true;
  }
  return false;
}

bool ReplaceOpenCLBuiltinPass::runOnFunction(Function &F) {
  auto &FI = Builtins::Lookup(&F);
  switch (FI.getType()) {
  case Builtins::kAbs:
    if (!FI.getParameter(0).is_signed) {
      return replaceAbs(F);
    }
    break;
  case Builtins::kAbsDiff:
    return replaceAbsDiff(F, FI.getParameter(0).is_signed);

  case Builtins::kAddSat:
    return replaceAddSubSat(F, FI.getParameter(0).is_signed, true);

  case Builtins::kClz:
    return replaceCountZeroes(F, true);

  case Builtins::kCtz:
    return replaceCountZeroes(F, false);

  case Builtins::kHadd:
    return replaceHadd(F, FI.getParameter(0).is_signed, Instruction::And);
  case Builtins::kRhadd:
    return replaceHadd(F, FI.getParameter(0).is_signed, Instruction::Or);

  case Builtins::kCopysign:
    return replaceCopysign(F);

  case Builtins::kHalfRecip:
  case Builtins::kNativeRecip:
    return replaceRecip(F);

  case Builtins::kHalfDivide:
  case Builtins::kNativeDivide:
    return replaceDivide(F);

  case Builtins::kDot:
    return replaceDot(F);

  case Builtins::kExp10:
  case Builtins::kHalfExp10:
  case Builtins::kNativeExp10:
    return replaceExp10(F, FI.getName());

  case Builtins::kLog10:
  case Builtins::kHalfLog10:
  case Builtins::kNativeLog10:
    return replaceLog10(F, FI.getName());

  case Builtins::kLog1p:
    return replaceLog1p(F);

  case Builtins::kFdim:
    return replaceFDim(F);

  case Builtins::kFmod:
    return replaceFmod(F);

  case Builtins::kBarrier:
  case Builtins::kWorkGroupBarrier:
    return replaceBarrier(F);

  case Builtins::kSubGroupBarrier:
    return replaceBarrier(F, true);

  case Builtins::kMemFence:
    return replaceMemFence(F, spv::MemorySemanticsAcquireReleaseMask);
  case Builtins::kReadMemFence:
    return replaceMemFence(F, spv::MemorySemanticsAcquireMask);
  case Builtins::kWriteMemFence:
    return replaceMemFence(F, spv::MemorySemanticsReleaseMask);

    // Relational
  case Builtins::kIsequal:
    return replaceRelational(F, CmpInst::FCMP_OEQ);
  case Builtins::kIsgreater:
    return replaceRelational(F, CmpInst::FCMP_OGT);
  case Builtins::kIsgreaterequal:
    return replaceRelational(F, CmpInst::FCMP_OGE);
  case Builtins::kIsless:
    return replaceRelational(F, CmpInst::FCMP_OLT);
  case Builtins::kIslessequal:
    return replaceRelational(F, CmpInst::FCMP_OLE);
  case Builtins::kIsnotequal:
    return replaceRelational(F, CmpInst::FCMP_UNE);
  case Builtins::kIslessgreater:
    return replaceRelational(F, CmpInst::FCMP_ONE);

  case Builtins::kIsordered:
    return replaceOrdered(F, true);

  case Builtins::kIsunordered:
    return replaceOrdered(F, false);

  case Builtins::kIsinf: {
    bool is_vec = FI.getParameter(0).vector_size != 0;
    return replaceIsInfAndIsNan(F, spv::OpIsInf, is_vec ? -1 : 1);
  }
  case Builtins::kIsnan: {
    bool is_vec = FI.getParameter(0).vector_size != 0;
    return replaceIsInfAndIsNan(F, spv::OpIsNan, is_vec ? -1 : 1);
  }

  case Builtins::kIsfinite:
    return replaceIsFinite(F);

  case Builtins::kAll: {
    bool is_vec = FI.getParameter(0).vector_size != 0;
    return replaceAllAndAny(F, !is_vec ? spv::OpNop : spv::OpAll);
  }
  case Builtins::kAny: {
    bool is_vec = FI.getParameter(0).vector_size != 0;
    return replaceAllAndAny(F, !is_vec ? spv::OpNop : spv::OpAny);
  }

  case Builtins::kIsnormal:
    return replaceIsNormal(F);

  case Builtins::kUpsample:
    return replaceUpsample(F);

  case Builtins::kRotate:
    return replaceRotate(F);

  case Builtins::kConvert:
    return replaceConvert(F, FI.getParameter(0).is_signed,
                          FI.getReturnType().is_signed);

  // OpenCL 2.0 explicit atomics have different default scopes and semantics
  // than legacy atomic functions.
  case Builtins::kAtomicLoad:
  case Builtins::kAtomicLoadExplicit:
    return replaceAtomicLoad(F);
  case Builtins::kAtomicStore:
  case Builtins::kAtomicStoreExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicStore,
                                  spv::MemorySemanticsReleaseMask);
  case Builtins::kAtomicExchange:
  case Builtins::kAtomicExchangeExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicExchange);
  case Builtins::kAtomicFetchAdd:
  case Builtins::kAtomicFetchAddExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicIAdd);
  case Builtins::kAtomicFetchSub:
  case Builtins::kAtomicFetchSubExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicISub);
  case Builtins::kAtomicFetchOr:
  case Builtins::kAtomicFetchOrExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicOr);
  case Builtins::kAtomicFetchXor:
  case Builtins::kAtomicFetchXorExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicXor);
  case Builtins::kAtomicFetchAnd:
  case Builtins::kAtomicFetchAndExplicit:
    return replaceExplicitAtomics(F, spv::OpAtomicAnd);
  case Builtins::kAtomicFetchMin:
  case Builtins::kAtomicFetchMinExplicit:
    return replaceExplicitAtomics(F, FI.getParameter(1).is_signed
                                         ? spv::OpAtomicSMin
                                         : spv::OpAtomicUMin);
  case Builtins::kAtomicFetchMax:
  case Builtins::kAtomicFetchMaxExplicit:
    return replaceExplicitAtomics(F, FI.getParameter(1).is_signed
                                         ? spv::OpAtomicSMax
                                         : spv::OpAtomicUMax);
  // Weak compare exchange is generated as strong compare exchange.
  case Builtins::kAtomicCompareExchangeWeak:
  case Builtins::kAtomicCompareExchangeWeakExplicit:
  case Builtins::kAtomicCompareExchangeStrong:
  case Builtins::kAtomicCompareExchangeStrongExplicit:
    return replaceAtomicCompareExchange(F);

  // Legacy atomic functions.
  case Builtins::kAtomicInc:
    return replaceAtomics(F, spv::OpAtomicIIncrement);
  case Builtins::kAtomicDec:
    return replaceAtomics(F, spv::OpAtomicIDecrement);
  case Builtins::kAtomicCmpxchg:
    return replaceAtomics(F, spv::OpAtomicCompareExchange);
  case Builtins::kAtomicAdd:
    return replaceAtomics(F, llvm::AtomicRMWInst::Add);
  case Builtins::kAtomicSub:
    return replaceAtomics(F, llvm::AtomicRMWInst::Sub);
  case Builtins::kAtomicXchg:
    return replaceAtomics(F, llvm::AtomicRMWInst::Xchg);
  case Builtins::kAtomicMin:
    return replaceAtomics(F, FI.getParameter(0).is_signed
                                 ? llvm::AtomicRMWInst::Min
                                 : llvm::AtomicRMWInst::UMin);
  case Builtins::kAtomicMax:
    return replaceAtomics(F, FI.getParameter(0).is_signed
                                 ? llvm::AtomicRMWInst::Max
                                 : llvm::AtomicRMWInst::UMax);
  case Builtins::kAtomicAnd:
    return replaceAtomics(F, llvm::AtomicRMWInst::And);
  case Builtins::kAtomicOr:
    return replaceAtomics(F, llvm::AtomicRMWInst::Or);
  case Builtins::kAtomicXor:
    return replaceAtomics(F, llvm::AtomicRMWInst::Xor);

  case Builtins::kCross:
    if (FI.getParameter(0).vector_size == 4) {
      return replaceCross(F);
    }
    break;

  case Builtins::kFract:
    if (FI.getParameterCount()) {
      return replaceFract(F, FI.getParameter(0).vector_size);
    }
    break;

  case Builtins::kMadHi:
    return replaceMulHi(F, FI.getParameter(0).is_signed, true);
  case Builtins::kMulHi:
    return replaceMulHi(F, FI.getParameter(0).is_signed, false);

  case Builtins::kMadSat:
    return replaceMadSat(F, FI.getParameter(0).is_signed);

  case Builtins::kMad:
  case Builtins::kMad24:
    return replaceMul(F, FI.getParameter(0).type_id == llvm::Type::FloatTyID,
                      true);
  case Builtins::kMul24:
    return replaceMul(F, FI.getParameter(0).type_id == llvm::Type::FloatTyID,
                      false);

  case Builtins::kSelect:
    return replaceSelect(F);

  case Builtins::kBitselect:
    return replaceBitSelect(F);

  case Builtins::kVload:
    return replaceVload(F);

  case Builtins::kVloadaHalf:
  case Builtins::kVloadHalf:
    return replaceVloadHalf(F, FI.getName(), FI.getParameter(0).vector_size);

  case Builtins::kVstore:
    return replaceVstore(F);

  case Builtins::kVstoreHalf:
  case Builtins::kVstoreaHalf:
    return replaceVstoreHalf(F, FI.getParameter(0).vector_size);

  case Builtins::kSmoothstep: {
    int vec_size = FI.getLastParameter().vector_size;
    if (FI.getParameter(0).vector_size == 0 && vec_size != 0) {
      return replaceStep(F, true);
    }
    break;
  }
  case Builtins::kStep: {
    int vec_size = FI.getLastParameter().vector_size;
    if (FI.getParameter(0).vector_size == 0 && vec_size != 0) {
      return replaceStep(F, false);
    }
    break;
  }

  case Builtins::kSignbit:
    return replaceSignbit(F, FI.getParameter(0).vector_size != 0);

  case Builtins::kSubSat:
    return replaceAddSubSat(F, FI.getParameter(0).is_signed, false);

  case Builtins::kReadImageh:
    return replaceHalfReadImage(F);
  case Builtins::kReadImagef:
  case Builtins::kReadImagei:
  case Builtins::kReadImageui: {
    if (FI.getParameter(1).isSampler() &&
        FI.getParameter(2).type_id == llvm::Type::IntegerTyID) {
      return replaceSampledReadImageWithIntCoords(F);
    }
    break;
  }

  case Builtins::kWriteImageh:
    return replaceHalfWriteImage(F);

  case Builtins::kPrefetch:
    return replacePrefetch(F);

  default:
    break;
  }

  return false;
}

Type *ReplaceOpenCLBuiltinPass::GetPairStruct(Type *type) {
  auto iter = PairStructMap.find(type);
  if (iter != PairStructMap.end())
    return iter->second;

  auto new_struct = StructType::get(type->getContext(), {type, type});
  PairStructMap[type] = new_struct;
  return new_struct;
}

bool ReplaceOpenCLBuiltinPass::replaceAbs(Function &F) {
  return replaceCallsWithValue(F,
                               [](CallInst *CI) { return CI->getOperand(0); });
}

bool ReplaceOpenCLBuiltinPass::replaceAbsDiff(Function &F, bool is_signed) {
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto XValue = CI->getOperand(0);
    auto YValue = CI->getOperand(1);

    IRBuilder<> Builder(CI);
    auto XmY = Builder.CreateSub(XValue, YValue);
    auto YmX = Builder.CreateSub(YValue, XValue);

    Value *Cmp = nullptr;
    if (is_signed) {
      Cmp = Builder.CreateICmpSGT(YValue, XValue);
    } else {
      Cmp = Builder.CreateICmpUGT(YValue, XValue);
    }

    return Builder.CreateSelect(Cmp, YmX, XmY);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceCopysign(Function &F) {
  return replaceCallsWithValue(F, [&F](CallInst *Call) {
    const auto x = Call->getArgOperand(0);
    const auto y = Call->getArgOperand(1);
    auto intrinsic = Intrinsic::getDeclaration(
        F.getParent(), Intrinsic::copysign, Call->getType());
    return CallInst::Create(intrinsic->getFunctionType(), intrinsic, {x, y}, "",
                            Call);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceRecip(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *CI) {
    // Recip has one arg.
    auto Arg = CI->getOperand(0);
    auto Cst1 = ConstantFP::get(Arg->getType(), 1.0);
    return BinaryOperator::Create(Instruction::FDiv, Cst1, Arg, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceDivide(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);
    return BinaryOperator::Create(Instruction::FDiv, Op0, Op1, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceDot(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);

    Value *V = nullptr;
    if (Op0->getType()->isVectorTy()) {
      V = clspv::InsertSPIRVOp(CI, spv::OpDot, {Attribute::ReadNone},
                               CI->getType(), {Op0, Op1});
    } else {
      V = BinaryOperator::Create(Instruction::FMul, Op0, Op1, "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceExp10(Function &F,
                                            const std::string &basename) {
  // convert to natural
  auto slen = basename.length() - 2;
  std::string NewFName = basename.substr(0, slen);
  NewFName =
      Builtins::GetMangledFunctionName(NewFName.c_str(), F.getFunctionType());

  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto NewF = M.getOrInsertFunction(NewFName, F.getFunctionType());

    auto Arg = CI->getOperand(0);

    // Constant of the natural log of 10 (ln(10)).
    const double Ln10 =
        2.302585092994045684017991454684364207601101488628772976033;

    auto Mul = BinaryOperator::Create(
        Instruction::FMul, ConstantFP::get(Arg->getType(), Ln10), Arg, "", CI);

    return CallInst::Create(NewF, Mul, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceFmod(Function &F) {
  // OpenCL fmod(x,y) is x - y * trunc(x/y)
  // The sign for a non-zero result is taken from x.
  // (Try an example.)
  // So translate to FRem
  return replaceCallsWithValue(F, [](CallInst *CI) {
    auto Op0 = CI->getOperand(0);
    auto Op1 = CI->getOperand(1);
    return BinaryOperator::Create(Instruction::FRem, Op0, Op1, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceLog10(Function &F,
                                            const std::string &basename) {
  // convert to natural
  auto slen = basename.length() - 2;
  std::string NewFName = basename.substr(0, slen);
  NewFName =
      Builtins::GetMangledFunctionName(NewFName.c_str(), F.getFunctionType());

  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto NewF = M.getOrInsertFunction(NewFName, F.getFunctionType());

    auto Arg = CI->getOperand(0);

    // Constant of the reciprocal of the natural log of 10 (ln(10)).
    const double Ln10 =
        0.434294481903251827651128918916605082294397005803666566114;

    auto NewCI = CallInst::Create(NewF, Arg, "", CI);

    return BinaryOperator::Create(Instruction::FMul,
                                  ConstantFP::get(Arg->getType(), Ln10), NewCI,
                                  "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceLog1p(Function &F) {
  // convert to natural
  std::string NewFName =
      Builtins::GetMangledFunctionName("log", F.getFunctionType());

  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto NewF = M.getOrInsertFunction(NewFName, F.getFunctionType());

    auto Arg = CI->getOperand(0);

    auto ArgP1 = BinaryOperator::Create(
        Instruction::FAdd, ConstantFP::get(Arg->getType(), 1.0), Arg, "", CI);

    return CallInst::Create(NewF, ArgP1, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceBarrier(Function &F, bool subgroup) {

  enum {
    CLK_LOCAL_MEM_FENCE = 0x01,
    CLK_GLOBAL_MEM_FENCE = 0x02,
    CLK_IMAGE_MEM_FENCE = 0x04
  };

  return replaceCallsWithValue(F, [subgroup](CallInst *CI) {
    auto Arg = CI->getOperand(0);

    // We need to map the OpenCL constants to the SPIR-V equivalents.
    const auto LocalMemFence =
        ConstantInt::get(Arg->getType(), CLK_LOCAL_MEM_FENCE);
    const auto GlobalMemFence =
        ConstantInt::get(Arg->getType(), CLK_GLOBAL_MEM_FENCE);
    const auto ImageMemFence =
        ConstantInt::get(Arg->getType(), CLK_IMAGE_MEM_FENCE);
    const auto ConstantAcquireRelease = ConstantInt::get(
        Arg->getType(), spv::MemorySemanticsAcquireReleaseMask);
    const auto ConstantScopeDevice =
        ConstantInt::get(Arg->getType(), spv::ScopeDevice);
    const auto ConstantScopeWorkgroup =
        ConstantInt::get(Arg->getType(), spv::ScopeWorkgroup);
    const auto ConstantScopeSubgroup =
        ConstantInt::get(Arg->getType(), spv::ScopeSubgroup);

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

    // OpenCL 2.0
    // Map CLK_IMAGE_MEM_FENCE to MemorySemanticsImageMemoryMask.
    const auto ImageMemFenceMask =
        BinaryOperator::Create(Instruction::And, ImageMemFence, Arg, "", CI);
    const auto ImageShiftAmount =
        clz(spv::MemorySemanticsImageMemoryMask) - clz(CLK_IMAGE_MEM_FENCE);
    const auto MemorySemanticsImage = BinaryOperator::Create(
        Instruction::Shl, ImageMemFenceMask,
        ConstantInt::get(Arg->getType(), ImageShiftAmount), "", CI);

    // And combine the above together, also adding in
    // MemorySemanticsSequentiallyConsistentMask.
    auto MemorySemantics1 =
        BinaryOperator::Create(Instruction::Or, MemorySemanticsWorkgroup,
                               ConstantAcquireRelease, "", CI);
    auto MemorySemantics2 = BinaryOperator::Create(
        Instruction::Or, MemorySemanticsUniform, MemorySemanticsImage, "", CI);
    auto MemorySemantics = BinaryOperator::Create(
        Instruction::Or, MemorySemantics1, MemorySemantics2, "", CI);

    // If the memory scope is not specified explicitly, it is either Subgroup
    // or Workgroup depending on the type of barrier.
    Value *MemoryScope =
        subgroup ? ConstantScopeSubgroup : ConstantScopeWorkgroup;
    if (CI->data_operands_size() > 1) {
      enum {
        CL_MEMORY_SCOPE_WORKGROUP = 0x1,
        CL_MEMORY_SCOPE_DEVICE = 0x2,
        CL_MEMORY_SCOPE_SUBGROUP = 0x4
      };
      // The call was given an explicit memory scope.
      const auto MemoryScopeSubgroup =
          ConstantInt::get(Arg->getType(), CL_MEMORY_SCOPE_SUBGROUP);
      const auto MemoryScopeDevice =
          ConstantInt::get(Arg->getType(), CL_MEMORY_SCOPE_DEVICE);

      auto Cmp =
          CmpInst::Create(Instruction::ICmp, CmpInst::ICMP_EQ,
                          MemoryScopeSubgroup, CI->getOperand(1), "", CI);
      MemoryScope = SelectInst::Create(Cmp, ConstantScopeSubgroup,
                                       ConstantScopeWorkgroup, "", CI);
      Cmp = CmpInst::Create(Instruction::ICmp, CmpInst::ICMP_EQ,
                            MemoryScopeDevice, CI->getOperand(1), "", CI);
      MemoryScope =
          SelectInst::Create(Cmp, ConstantScopeDevice, MemoryScope, "", CI);
    }

    // Lastly, the Execution Scope is either Workgroup or Subgroup depending on
    // the type of barrier;
    const auto ExecutionScope =
        subgroup ? ConstantScopeSubgroup : ConstantScopeWorkgroup;

    return clspv::InsertSPIRVOp(CI, spv::OpControlBarrier,
                                {Attribute::NoDuplicate, Attribute::Convergent},
                                CI->getType(),
                                {ExecutionScope, MemoryScope, MemorySemantics});
  });
}

bool ReplaceOpenCLBuiltinPass::replaceMemFence(Function &F,
                                               uint32_t semantics) {

  return replaceCallsWithValue(F, [&](CallInst *CI) {
    enum {
      CLK_LOCAL_MEM_FENCE = 0x01,
      CLK_GLOBAL_MEM_FENCE = 0x02,
      CLK_IMAGE_MEM_FENCE = 0x04,
    };

    auto Arg = CI->getOperand(0);

    // We need to map the OpenCL constants to the SPIR-V equivalents.
    const auto LocalMemFence =
        ConstantInt::get(Arg->getType(), CLK_LOCAL_MEM_FENCE);
    const auto GlobalMemFence =
        ConstantInt::get(Arg->getType(), CLK_GLOBAL_MEM_FENCE);
    const auto ImageMemFence =
        ConstantInt::get(Arg->getType(), CLK_IMAGE_MEM_FENCE);
    const auto ConstantMemorySemantics =
        ConstantInt::get(Arg->getType(), semantics);
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

    // OpenCL 2.0
    // Map CLK_IMAGE_MEM_FENCE to MemorySemanticsImageMemoryMask.
    const auto ImageMemFenceMask =
        BinaryOperator::Create(Instruction::And, ImageMemFence, Arg, "", CI);
    const auto ImageShiftAmount =
        clz(spv::MemorySemanticsImageMemoryMask) - clz(CLK_IMAGE_MEM_FENCE);
    const auto MemorySemanticsImage = BinaryOperator::Create(
        Instruction::Shl, ImageMemFenceMask,
        ConstantInt::get(Arg->getType(), ImageShiftAmount), "", CI);

    // And combine the above together, also adding in
    // |semantics|.
    auto MemorySemantics1 =
        BinaryOperator::Create(Instruction::Or, MemorySemanticsWorkgroup,
                               ConstantMemorySemantics, "", CI);
    auto MemorySemantics2 = BinaryOperator::Create(
        Instruction::Or, MemorySemanticsUniform, MemorySemanticsImage, "", CI);
    auto MemorySemantics = BinaryOperator::Create(
        Instruction::Or, MemorySemantics1, MemorySemantics2, "", CI);

    // Memory Scope is always workgroup.
    const auto MemoryScope = ConstantScopeWorkgroup;

    return clspv::InsertSPIRVOp(CI, spv::OpMemoryBarrier,
                                {Attribute::Convergent}, CI->getType(),
                                {MemoryScope, MemorySemantics});
  });
}

bool ReplaceOpenCLBuiltinPass::replacePrefetch(Function &F) {
  bool Changed = false;

  SmallVector<Instruction *, 4> ToRemoves;

  // Find all calls to the function
  for (auto &U : F.uses()) {
    if (auto CI = dyn_cast<CallInst>(U.getUser())) {
      ToRemoves.push_back(CI);
    }
  }

  Changed = !ToRemoves.empty();

  // Delete them
  for (auto V : ToRemoves) {
    V->eraseFromParent();
  }

  return Changed;
}

bool ReplaceOpenCLBuiltinPass::replaceRelational(Function &F,
                                                 CmpInst::Predicate P) {
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The predicate to use in the CmpInst.
    auto Predicate = P;

    auto Arg1 = CI->getOperand(0);
    auto Arg2 = CI->getOperand(1);

    const auto Cmp =
        CmpInst::Create(Instruction::FCmp, Predicate, Arg1, Arg2, "", CI);
    if (isa<VectorType>(F.getReturnType()))
      return CastInst::Create(Instruction::SExt, Cmp, CI->getType(), "", CI);
    return CastInst::Create(Instruction::ZExt, Cmp, CI->getType(), "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceIsInfAndIsNan(Function &F,
                                                    spv::Op SPIRVOp,
                                                    int32_t C) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    const auto CITy = CI->getType();

    // The value to return for true.
    auto TrueValue = ConstantInt::getSigned(CITy, C);

    // The value to return for false.
    auto FalseValue = Constant::getNullValue(CITy);

    Type *CorrespondingBoolTy = Type::getInt1Ty(M.getContext());
    if (auto CIVecTy = dyn_cast<VectorType>(CITy)) {
      CorrespondingBoolTy =
          FixedVectorType::get(Type::getInt1Ty(M.getContext()),
                               CIVecTy->getElementCount().getKnownMinValue());
    }

    auto NewCI = clspv::InsertSPIRVOp(CI, SPIRVOp, {Attribute::ReadNone},
                                      CorrespondingBoolTy, {CI->getOperand(0)});

    return SelectInst::Create(NewCI, TrueValue, FalseValue, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceIsFinite(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto &C = M.getContext();
    auto Val = CI->getOperand(0);
    auto ValTy = Val->getType();
    auto RetTy = CI->getType();

    // Get a suitable integer type to represent the number
    auto IntTy = getIntOrIntVectorTyForCast(C, ValTy);

    // Create Mask
    auto ScalarSize = ValTy->getScalarSizeInBits();
    Value *InfMask = nullptr;
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
    Value *RetTrue = nullptr;
    if (ValTy->isVectorTy()) {
      RetTrue = ConstantInt::getSigned(RetTy, -1);
    } else {
      RetTrue = ConstantInt::get(RetTy, 1);
    }
    return Builder.CreateSelect(Cmp, RetFalse, RetTrue);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAllAndAny(Function &F, spv::Op SPIRVOp) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto Arg = CI->getOperand(0);

    Value *V = nullptr;

    // If the argument is a 32-bit int, just use a shift
    if (Arg->getType() == Type::getInt32Ty(M.getContext())) {
      V = BinaryOperator::Create(Instruction::LShr, Arg,
                                 ConstantInt::get(Arg->getType(), 31), "", CI);
    } else {
      // The value for zero to compare against.
      const auto ZeroValue = Constant::getNullValue(Arg->getType());

      // The value to return for true.
      const auto TrueValue = ConstantInt::get(CI->getType(), 1);

      // The value to return for false.
      const auto FalseValue = Constant::getNullValue(CI->getType());

      const auto Cmp = CmpInst::Create(Instruction::ICmp, CmpInst::ICMP_SLT,
                                       Arg, ZeroValue, "", CI);

      Value *SelectSource = nullptr;

      // If we have a function to call, call it!
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
    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceUpsample(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    // Get arguments
    auto HiValue = CI->getOperand(0);
    auto LoValue = CI->getOperand(1);

    // Don't touch overloads that aren't in OpenCL C
    auto HiType = HiValue->getType();
    auto LoType = LoValue->getType();

    if (HiType != LoType) {
      return nullptr;
    }

    if (!HiType->isIntOrIntVectorTy()) {
      return nullptr;
    }

    if (HiType->getScalarSizeInBits() * 2 !=
        CI->getType()->getScalarSizeInBits()) {
      return nullptr;
    }

    if ((HiType->getScalarSizeInBits() != 8) &&
        (HiType->getScalarSizeInBits() != 16) &&
        (HiType->getScalarSizeInBits() != 32)) {
      return nullptr;
    }

    if (auto HiVecType = dyn_cast<VectorType>(HiType)) {
      unsigned NumElements = HiVecType->getElementCount().getKnownMinValue();
      if ((NumElements != 2) && (NumElements != 3) && (NumElements != 4) &&
          (NumElements != 8) && (NumElements != 16)) {
        return nullptr;
      }
    }

    // Convert both operands to the result type
    auto HiCast = CastInst::CreateZExtOrBitCast(HiValue, CI->getType(), "", CI);
    auto LoCast = CastInst::CreateZExtOrBitCast(LoValue, CI->getType(), "", CI);

    // Shift high operand
    auto ShiftAmount =
        ConstantInt::get(CI->getType(), HiType->getScalarSizeInBits());
    auto HiShifted =
        BinaryOperator::Create(Instruction::Shl, HiCast, ShiftAmount, "", CI);

    // OR both results
    return BinaryOperator::Create(Instruction::Or, HiShifted, LoCast, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceRotate(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    // Get arguments
    auto SrcValue = CI->getOperand(0);
    auto RotAmount = CI->getOperand(1);

    // Don't touch overloads that aren't in OpenCL C
    auto SrcType = SrcValue->getType();
    auto RotType = RotAmount->getType();

    if ((SrcType != RotType) || (CI->getType() != SrcType)) {
      return nullptr;
    }

    if (!SrcType->isIntOrIntVectorTy()) {
      return nullptr;
    }

    if ((SrcType->getScalarSizeInBits() != 8) &&
        (SrcType->getScalarSizeInBits() != 16) &&
        (SrcType->getScalarSizeInBits() != 32) &&
        (SrcType->getScalarSizeInBits() != 64)) {
      return nullptr;
    }

    if (auto SrcVecType = dyn_cast<VectorType>(SrcType)) {
      unsigned NumElements = SrcVecType->getElementCount().getKnownMinValue();
      if ((NumElements != 2) && (NumElements != 3) && (NumElements != 4) &&
          (NumElements != 8) && (NumElements != 16)) {
        return nullptr;
      }
    }

    // Replace with LLVM's funnel shift left intrinsic because it is more
    // generic than rotate.
    Function *intrinsic =
        Intrinsic::getDeclaration(F.getParent(), Intrinsic::fshl, SrcType);
    return CallInst::Create(intrinsic->getFunctionType(), intrinsic,
                            {SrcValue, SrcValue, RotAmount}, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceConvert(Function &F, bool SrcIsSigned,
                                              bool DstIsSigned) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    Value *V = nullptr;
    // Get arguments
    auto SrcValue = CI->getOperand(0);

    // Don't touch overloads that aren't in OpenCL C
    auto SrcType = SrcValue->getType();
    auto DstType = CI->getType();

    if ((SrcType->isVectorTy() && !DstType->isVectorTy()) ||
        (!SrcType->isVectorTy() && DstType->isVectorTy())) {
      return V;
    }

    if (auto SrcVecType = dyn_cast<VectorType>(SrcType)) {
      unsigned SrcNumElements =
          SrcVecType->getElementCount().getKnownMinValue();
      unsigned DstNumElements =
          cast<VectorType>(DstType)->getElementCount().getKnownMinValue();
      if (SrcNumElements != DstNumElements) {
        return V;
      }

      if ((SrcNumElements != 2) && (SrcNumElements != 3) &&
          (SrcNumElements != 4) && (SrcNumElements != 8) &&
          (SrcNumElements != 16)) {
        return V;
      }
    }

    bool SrcIsFloat = SrcType->getScalarType()->isFloatingPointTy();
    bool DstIsFloat = DstType->getScalarType()->isFloatingPointTy();

    bool SrcIsInt = SrcType->isIntOrIntVectorTy();
    bool DstIsInt = DstType->isIntOrIntVectorTy();

    if (SrcType == DstType && DstIsSigned == SrcIsSigned) {
      // Unnecessary cast operation.
      V = SrcValue;
    } else if (SrcIsFloat && DstIsFloat) {
      V = CastInst::CreateFPCast(SrcValue, DstType, "", CI);
    } else if (SrcIsFloat && DstIsInt) {
      if (DstIsSigned) {
        V = CastInst::Create(Instruction::FPToSI, SrcValue, DstType, "", CI);
      } else {
        V = CastInst::Create(Instruction::FPToUI, SrcValue, DstType, "", CI);
      }
    } else if (SrcIsInt && DstIsFloat) {
      if (SrcIsSigned) {
        V = CastInst::Create(Instruction::SIToFP, SrcValue, DstType, "", CI);
      } else {
        V = CastInst::Create(Instruction::UIToFP, SrcValue, DstType, "", CI);
      }
    } else if (SrcIsInt && DstIsInt) {
      V = CastInst::CreateIntegerCast(SrcValue, DstType, SrcIsSigned, "", CI);
    } else {
      // Not something we're supposed to handle, just move on
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceMulHi(Function &F, bool is_signed,
                                            bool is_mad) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    Value *V = nullptr;
    // Get arguments
    auto AValue = CI->getOperand(0);
    auto BValue = CI->getOperand(1);
    auto CValue = CI->getOperand(2);

    // Don't touch overloads that aren't in OpenCL C
    auto AType = AValue->getType();
    auto BType = BValue->getType();
    auto CType = CValue->getType();

    if ((AType != BType) || (CI->getType() != AType) ||
        (is_mad && (AType != CType))) {
      return V;
    }

    if (!AType->isIntOrIntVectorTy()) {
      return V;
    }

    if ((AType->getScalarSizeInBits() != 8) &&
        (AType->getScalarSizeInBits() != 16) &&
        (AType->getScalarSizeInBits() != 32) &&
        (AType->getScalarSizeInBits() != 64)) {
      return V;
    }

    if (auto AVecType = dyn_cast<VectorType>(AType)) {
      unsigned NumElements = AVecType->getElementCount().getKnownMinValue();
      if ((NumElements != 2) && (NumElements != 3) && (NumElements != 4) &&
          (NumElements != 8) && (NumElements != 16)) {
        return V;
      }
    }

    // Our SPIR-V op returns a struct, create a type for it
    auto ExMulRetType = GetPairStruct(AType);

    // Select the appropriate signed/unsigned SPIR-V op
    spv::Op opcode = is_signed ? spv::OpSMulExtended : spv::OpUMulExtended;

    // Call the SPIR-V op
    auto Call = clspv::InsertSPIRVOp(CI, opcode, {Attribute::ReadNone},
                                     ExMulRetType, {AValue, BValue});

    // Get the high part of the result
    unsigned Idxs[] = {1};
    V = ExtractValueInst::Create(Call, Idxs, "", CI);

    // If we're handling a mad_hi, add the third argument to the result
    if (is_mad) {
      V = BinaryOperator::Create(Instruction::Add, V, CValue, "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceSelect(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    // Get arguments
    auto FalseValue = CI->getOperand(0);
    auto TrueValue = CI->getOperand(1);
    auto PredicateValue = CI->getOperand(2);

    // Don't touch overloads that aren't in OpenCL C
    auto FalseType = FalseValue->getType();
    auto TrueType = TrueValue->getType();
    auto PredicateType = PredicateValue->getType();

    if (FalseType != TrueType) {
      return nullptr;
    }

    if (!PredicateType->isIntOrIntVectorTy()) {
      return nullptr;
    }

    if (!FalseType->isIntOrIntVectorTy() &&
        !FalseType->getScalarType()->isFloatingPointTy()) {
      return nullptr;
    }

    if (FalseType->isVectorTy() && !PredicateType->isVectorTy()) {
      return nullptr;
    }

    if (FalseType->getScalarSizeInBits() !=
        PredicateType->getScalarSizeInBits()) {
      return nullptr;
    }

    if (auto FalseVecType = dyn_cast<VectorType>(FalseType)) {
      unsigned NumElements = FalseVecType->getElementCount().getKnownMinValue();
      if (NumElements != cast<VectorType>(PredicateType)
                             ->getElementCount()
                             .getKnownMinValue()) {
        return nullptr;
      }

      if ((NumElements != 2) && (NumElements != 3) && (NumElements != 4) &&
          (NumElements != 8) && (NumElements != 16)) {
        return nullptr;
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
    return SelectInst::Create(Cmp, TrueValue, FalseValue, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceBitSelect(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    Value *V = nullptr;
    if (CI->getNumOperands() != 4) {
      return V;
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
      return V;
    }

    if (auto TrueVecType = dyn_cast<VectorType>(TrueType)) {
      if (!TrueType->getScalarType()->isFloatingPointTy() &&
          !TrueType->getScalarType()->isIntegerTy()) {
        return V;
      }
      unsigned NumElements = TrueVecType->getElementCount().getKnownMinValue();
      if ((NumElements != 2) && (NumElements != 3) && (NumElements != 4) &&
          (NumElements != 8) && (NumElements != 16)) {
        return V;
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
      BitType = getIntOrIntVectorTyForCast(F.getContext(), OpType);

      // Then bitcast all operands
      PredicateValue =
          CastInst::CreateZExtOrBitCast(PredicateValue, BitType, "", CI);
      FalseValue = CastInst::CreateZExtOrBitCast(FalseValue, BitType, "", CI);
      TrueValue = CastInst::CreateZExtOrBitCast(TrueValue, BitType, "", CI);

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
    auto BitsFalse = BinaryOperator::Create(Instruction::And, NotPredicateValue,
                                            FalseValue, "", CI);
    auto BitsTrue = BinaryOperator::Create(Instruction::And, PredicateValue,
                                           TrueValue, "", CI);

    V = BinaryOperator::Create(Instruction::Or, BitsFalse, BitsTrue, "", CI);

    // If we were dealing with a floating point type, we must bitcast
    // the result back to that
    if (OpType->getScalarType()->isFloatingPointTy()) {
      V = CastInst::CreateZExtOrBitCast(V, OpType, "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceStep(Function &F, bool is_smooth) {
  // convert to vector versions
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    SmallVector<Value *, 2> ArgsToSplat = {CI->getOperand(0)};
    Value *VectorArg = nullptr;

    // First figure out which function we're dealing with
    if (is_smooth) {
      ArgsToSplat.push_back(CI->getOperand(1));
      VectorArg = CI->getOperand(2);
    } else {
      VectorArg = CI->getOperand(1);
    }

    // Splat arguments that need to be
    SmallVector<Value *, 2> SplatArgs;
    auto VecType = cast<VectorType>(VectorArg->getType());

    for (auto arg : ArgsToSplat) {
      Value *NewVectorArg = UndefValue::get(VecType);
      for (auto i = 0; i < VecType->getElementCount().getKnownMinValue(); i++) {
        auto index = ConstantInt::get(Type::getInt32Ty(M.getContext()), i);
        NewVectorArg =
            InsertElementInst::Create(NewVectorArg, arg, index, "", CI);
      }
      SplatArgs.push_back(NewVectorArg);
    }

    // Replace the call with the vector/vector flavour
    SmallVector<Type *, 3> NewArgTypes(ArgsToSplat.size() + 1, VecType);
    const auto NewFType = FunctionType::get(CI->getType(), NewArgTypes, false);

    std::string NewFName = Builtins::GetMangledFunctionName(
        is_smooth ? "smoothstep" : "step", NewFType);

    const auto NewF = M.getOrInsertFunction(NewFName, NewFType);

    SmallVector<Value *, 3> NewArgs;
    for (auto arg : SplatArgs) {
      NewArgs.push_back(arg);
    }
    NewArgs.push_back(VectorArg);

    return CallInst::Create(NewF, NewArgs, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceSignbit(Function &F, bool is_vec) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    auto Arg = CI->getOperand(0);
    auto Op = is_vec ? Instruction::AShr : Instruction::LShr;

    auto Bitcast = CastInst::CreateZExtOrBitCast(Arg, CI->getType(), "", CI);

    return BinaryOperator::Create(Op, Bitcast,
                                  ConstantInt::get(CI->getType(), 31), "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceMul(Function &F, bool is_float,
                                          bool is_mad) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    // The multiply instruction to use.
    auto MulInst = is_float ? Instruction::FMul : Instruction::Mul;

    SmallVector<Value *, 8> Args(CI->arg_begin(), CI->arg_end());

    Value *V = BinaryOperator::Create(MulInst, CI->getArgOperand(0),
                                      CI->getArgOperand(1), "", CI);

    if (is_mad) {
      // The add instruction to use.
      auto AddInst = is_float ? Instruction::FAdd : Instruction::Add;

      V = BinaryOperator::Create(AddInst, V, CI->getArgOperand(2), "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVstore(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    Value *V = nullptr;
    auto data = CI->getOperand(0);

    auto data_type = data->getType();
    if (!data_type->isVectorTy())
      return V;

    auto vec_data_type = cast<VectorType>(data_type);

    auto elems = vec_data_type->getElementCount().getKnownMinValue();
    if (elems != 2 && elems != 3 && elems != 4 && elems != 8 && elems != 16)
      return V;

    auto offset = CI->getOperand(1);
    auto ptr = CI->getOperand(2);
    auto ptr_type = ptr->getType();
    auto pointee_type = ptr_type->getPointerElementType();
    if (pointee_type != vec_data_type->getElementType())
      return V;

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
      V = builder.CreateStore(extract, gep);
    }
    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVload(Function &F) {
  return replaceCallsWithValue(F, [&](CallInst *CI) -> llvm::Value * {
    Value *V = nullptr;
    auto ret_type = F.getReturnType();
    if (!ret_type->isVectorTy())
      return V;

    auto vec_ret_type = cast<VectorType>(ret_type);

    auto elems = vec_ret_type->getElementCount().getKnownMinValue();
    if (elems != 2 && elems != 3 && elems != 4 && elems != 8 && elems != 16)
      return V;

    auto offset = CI->getOperand(0);
    auto ptr = CI->getOperand(1);
    auto ptr_type = ptr->getType();
    auto pointee_type = ptr_type->getPointerElementType();
    if (pointee_type != vec_ret_type->getElementType())
      return V;

    // Avoid pointer casts. Instead generate the correct number of loads
    // and rely on drivers to coalesce appropriately.
    IRBuilder<> builder(CI);
    auto elems_const = builder.getInt32(elems);
    V = UndefValue::get(ret_type);
    auto adjust = builder.CreateMul(offset, elems_const);
    for (auto i = 0; i < elems; ++i) {
      auto idx = builder.getInt32(i);
      auto add = builder.CreateAdd(adjust, idx);
      auto gep = builder.CreateGEP(ptr, add);
      auto load = builder.CreateLoad(gep);
      V = builder.CreateInsertElement(V, load, i);
    }
    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf(Function &F,
                                                const std::string &name,
                                                int vec_size) {
  bool is_clspv_version = !name.compare(0, 8, "__clspv_");
  if (!vec_size) {
    // deduce vec_size from last character of name (e.g. vload_half4)
    vec_size = std::atoi(&name.back());
  }
  switch (vec_size) {
  case 2:
    return is_clspv_version ? replaceClspvVloadaHalf2(F) : replaceVloadHalf2(F);
  case 4:
    return is_clspv_version ? replaceClspvVloadaHalf4(F) : replaceVloadHalf4(F);
  case 0:
    if (!is_clspv_version) {
      return replaceVloadHalf(F);
    }
  default:
    llvm_unreachable("Unsupported vload_half vector size");
    break;
  }
  return false;
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The index argument from vload_half.
    auto Arg0 = CI->getOperand(0);

    // The pointer argument from vload_half.
    auto Arg1 = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = clspv::UnpackFunction();

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    Value *V = nullptr;

    bool supports_16bit_storage = true;
    switch (Arg1->getType()->getPointerAddressSpace()) {
    case clspv::AddressSpace::Global:
      supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
          clspv::Option::StorageClass::kSSBO);
      break;
    case clspv::AddressSpace::Constant:
      if (clspv::Option::ConstantArgsInUniformBuffer())
        supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
            clspv::Option::StorageClass::kUBO);
      else
        supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
            clspv::Option::StorageClass::kSSBO);
      break;
    default:
      // Clspv will emit the Float16 capability if the half type is
      // encountered. That capability covers private and local addressspaces.
      break;
    }

    if (supports_16bit_storage) {
      auto ShortTy = Type::getInt16Ty(M.getContext());
      auto ShortPointerTy =
          PointerType::get(ShortTy, Arg1->getType()->getPointerAddressSpace());

      // Cast the half* pointer to short*.
      auto Cast = CastInst::CreatePointerCast(Arg1, ShortPointerTy, "", CI);

      // Index into the correct address of the casted pointer.
      auto Index = GetElementPtrInst::Create(ShortTy, Cast, Arg0, "", CI);

      // Load from the short* we casted to.
      auto Load = new LoadInst(ShortTy, Index, "", CI);

      // ZExt the short -> int.
      auto ZExt = CastInst::CreateZExtOrBitCast(Load, IntTy, "", CI);

      // Get our float2.
      auto Call = CallInst::Create(NewF, ZExt, "", CI);

      // Extract out the bottom element which is our float result.
      V = ExtractElementInst::Create(Call, ConstantInt::get(IntTy, 0), "", CI);
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

      auto IntPointerTy =
          PointerType::get(IntTy, Arg1->getType()->getPointerAddressSpace());

      // Cast the base pointer to int*.
      // In a valid call (according to assumptions), this should get
      // optimized away in the simplify GEP pass.
      auto Cast = CastInst::CreatePointerCast(Arg1, IntPointerTy, "", CI);

      auto One = ConstantInt::get(IntTy, 1);
      auto IndexIsOdd = BinaryOperator::CreateAnd(Arg0, One, "", CI);
      auto IndexIntoI32 = BinaryOperator::CreateLShr(Arg0, One, "", CI);

      // Index into the correct address of the casted pointer.
      auto Ptr = GetElementPtrInst::Create(IntTy, Cast, IndexIntoI32, "", CI);

      // Load from the int* we casted to.
      auto Load = new LoadInst(IntTy, Ptr, "", CI);

      // Get our float2.
      auto Call = CallInst::Create(NewF, Load, "", CI);

      // Extract out the float result, where the element number is
      // determined by whether the original index was even or odd.
      V = ExtractElementInst::Create(Call, IndexIsOdd, "", CI);
    }
    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf2(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The index argument from vload_half.
    auto Arg0 = CI->getOperand(0);

    // The pointer argument from vload_half.
    auto Arg1 = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(IntTy, Arg1->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    // Cast the half* pointer to int*.
    auto Cast = CastInst::CreatePointerCast(Arg1, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(IntTy, Cast, Arg0, "", CI);

    // Load from the int* we casted to.
    auto Load = new LoadInst(IntTy, Index, "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = clspv::UnpackFunction();

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get our float2.
    return CallInst::Create(NewF, Load, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVloadHalf4(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The index argument from vload_half.
    auto Arg0 = CI->getOperand(0);

    // The pointer argument from vload_half.
    auto Arg1 = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = FixedVectorType::get(IntTy, 2);
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(Int2Ty, Arg1->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    // Cast the half* pointer to int2*.
    auto Cast = CastInst::CreatePointerCast(Arg1, NewPointerTy, "", CI);

    // Index into the correct address of the casted pointer.
    auto Index = GetElementPtrInst::Create(Int2Ty, Cast, Arg0, "", CI);

    // Load from the int2* we casted to.
    auto Load = new LoadInst(Int2Ty, Index, "", CI);

    // Extract each element from the loaded int2.
    auto X =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0), "", CI);
    auto Y =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1), "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = clspv::UnpackFunction();

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

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf2(Function &F) {

  // Replace __clspv_vloada_half2(uint Index, global uint* Ptr) with:
  //
  //    %u = load i32 %ptr
  //    %fxy = call <2 x float> Unpack2xHalf(u)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto Index = CI->getOperand(0);
    auto Ptr = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    auto IndexedPtr = GetElementPtrInst::Create(IntTy, Ptr, Index, "", CI);
    auto Load = new LoadInst(IntTy, IndexedPtr, "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = clspv::UnpackFunction();

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Get our final float2.
    return CallInst::Create(NewF, Load, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceClspvVloadaHalf4(Function &F) {

  // Replace __clspv_vloada_half4(uint Index, global uint2* Ptr) with:
  //
  //    %u2 = load <2 x i32> %ptr
  //    %u2xy = extractelement %u2, 0
  //    %u2zw = extractelement %u2, 1
  //    %fxy = call <2 x float> Unpack2xHalf(uint)
  //    %fzw = call <2 x float> Unpack2xHalf(uint)
  //    %result = shufflevector %fxy %fzw <4 x i32> <0, 1, 2, 3>
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto Index = CI->getOperand(0);
    auto Ptr = CI->getOperand(1);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = FixedVectorType::get(IntTy, 2);
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(Float2Ty, IntTy, false);

    auto IndexedPtr = GetElementPtrInst::Create(Int2Ty, Ptr, Index, "", CI);
    auto Load = new LoadInst(Int2Ty, IndexedPtr, "", CI);

    // Extract each element from the loaded int2.
    auto X =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 0), "", CI);
    auto Y =
        ExtractElementInst::Create(Load, ConstantInt::get(IntTy, 1), "", CI);

    // Our intrinsic to unpack a float2 from an int.
    auto SPIRVIntrinsic = clspv::UnpackFunction();

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

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf(Function &F, int vec_size) {
  switch (vec_size) {
  case 0:
    return replaceVstoreHalf(F);
  case 2:
    return replaceVstoreHalf2(F);
  case 4:
    return replaceVstoreHalf4(F);
  default:
    llvm_unreachable("Unsupported vstore_half vector size");
    break;
  }
  return false;
}

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewFType = FunctionType::get(IntTy, Float2Ty, false);
    auto One = ConstantInt::get(IntTy, 1);

    // Our intrinsic to pack a float2 to an int.
    auto SPIRVIntrinsic = clspv::PackFunction();

    auto NewF = M.getOrInsertFunction(SPIRVIntrinsic, NewFType);

    // Insert our value into a float2 so that we can pack it.
    auto TempVec = InsertElementInst::Create(
        UndefValue::get(Float2Ty), Arg0, ConstantInt::get(IntTy, 0), "", CI);

    // Pack the float2 -> half2 (in an int).
    auto X = CallInst::Create(NewF, TempVec, "", CI);

    bool supports_16bit_storage = true;
    switch (Arg2->getType()->getPointerAddressSpace()) {
    case clspv::AddressSpace::Global:
      supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
          clspv::Option::StorageClass::kSSBO);
      break;
    case clspv::AddressSpace::Constant:
      if (clspv::Option::ConstantArgsInUniformBuffer())
        supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
            clspv::Option::StorageClass::kUBO);
      else
        supports_16bit_storage = clspv::Option::Supports16BitStorageClass(
            clspv::Option::StorageClass::kSSBO);
      break;
    default:
      // Clspv will emit the Float16 capability if the half type is
      // encountered. That capability covers private and local addressspaces.
      break;
    }

    Value *V = nullptr;
    if (supports_16bit_storage) {
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
      V = new StoreInst(Trunc, Index, CI);
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
      auto CurrentValue = new LoadInst(IntTy, OutPtr, "current_value", CI);
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

      // Return a Nop so the old Call is removed
      Function *donothing = Intrinsic::getDeclaration(&M, Intrinsic::donothing);
      V = CallInst::Create(donothing, {}, "", CI);
    }

    return V;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf2(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
    auto NewPointerTy =
        PointerType::get(IntTy, Arg2->getType()->getPointerAddressSpace());
    auto NewFType = FunctionType::get(IntTy, Float2Ty, false);

    // Our intrinsic to pack a float2 to an int.
    auto SPIRVIntrinsic = clspv::PackFunction();

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

bool ReplaceOpenCLBuiltinPass::replaceVstoreHalf4(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The value to store.
    auto Arg0 = CI->getOperand(0);

    // The index argument from vstore_half.
    auto Arg1 = CI->getOperand(1);

    // The pointer argument from vstore_half.
    auto Arg2 = CI->getOperand(2);

    auto IntTy = Type::getInt32Ty(M.getContext());
    auto Int2Ty = FixedVectorType::get(IntTy, 2);
    auto Float2Ty = FixedVectorType::get(Type::getFloatTy(M.getContext()), 2);
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
    auto SPIRVIntrinsic = clspv::PackFunction();

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

bool ReplaceOpenCLBuiltinPass::replaceHalfReadImage(Function &F) {
  // convert half to float
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    SmallVector<Type *, 3> types;
    SmallVector<Value *, 3> args;
    for (auto i = 0; i < CI->getNumArgOperands(); ++i) {
      types.push_back(CI->getArgOperand(i)->getType());
      args.push_back(CI->getArgOperand(i));
    }

    auto NewFType =
        FunctionType::get(FixedVectorType::get(Type::getFloatTy(M.getContext()),
                                               cast<VectorType>(CI->getType())
                                                   ->getElementCount()
                                                   .getKnownMinValue()),
                          types, false);

    std::string NewFName =
        Builtins::GetMangledFunctionName("read_imagef", NewFType);

    auto NewF = M.getOrInsertFunction(NewFName, NewFType);

    auto NewCI = CallInst::Create(NewF, args, "", CI);

    // Convert to the half type.
    return CastInst::CreateFPCast(NewCI, CI->getType(), "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceHalfWriteImage(Function &F) {
  // convert half to float
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    SmallVector<Type *, 3> types(3);
    SmallVector<Value *, 3> args(3);

    // Image
    types[0] = CI->getArgOperand(0)->getType();
    args[0] = CI->getArgOperand(0);

    // Coord
    types[1] = CI->getArgOperand(1)->getType();
    args[1] = CI->getArgOperand(1);

    // Data
    types[2] =
        FixedVectorType::get(Type::getFloatTy(M.getContext()),
                             cast<VectorType>(CI->getArgOperand(2)->getType())
                                 ->getElementCount()
                                 .getKnownMinValue());

    auto NewFType =
        FunctionType::get(Type::getVoidTy(M.getContext()), types, false);

    std::string NewFName =
        Builtins::GetMangledFunctionName("write_imagef", NewFType);

    auto NewF = M.getOrInsertFunction(NewFName, NewFType);

    // Convert data to the float type.
    auto Cast = CastInst::CreateFPCast(CI->getArgOperand(2), types[2], "", CI);
    args[2] = Cast;

    return CallInst::Create(NewF, args, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceSampledReadImageWithIntCoords(
    Function &F) {
  // convert read_image with int coords to float coords
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    // The image.
    auto Arg0 = CI->getOperand(0);

    // The sampler.
    auto Arg1 = CI->getOperand(1);

    // The coordinate (integer type that we can't handle).
    auto Arg2 = CI->getOperand(2);

    uint32_t dim = clspv::ImageDimensionality(Arg0->getType());
    uint32_t components =
        dim + (clspv::IsArrayImageType(Arg0->getType()) ? 1 : 0);
    Type *float_ty = nullptr;
    if (components == 1) {
      float_ty = Type::getFloatTy(M.getContext());
    } else {
      float_ty = FixedVectorType::get(Type::getFloatTy(M.getContext()),
                                      cast<VectorType>(Arg2->getType())
                                          ->getElementCount()
                                          .getKnownMinValue());
    }

    auto NewFType = FunctionType::get(
        CI->getType(), {Arg0->getType(), Arg1->getType(), float_ty}, false);

    std::string NewFName = F.getName().str();
    NewFName[NewFName.length() - 1] = 'f';

    auto NewF = M.getOrInsertFunction(NewFName, NewFType);

    auto Cast = CastInst::Create(Instruction::SIToFP, Arg2, float_ty, "", CI);

    return CallInst::Create(NewF, {Arg0, Arg1, Cast}, "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAtomics(Function &F, spv::Op Op) {
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto IntTy = Type::getInt32Ty(F.getContext());

    // We need to map the OpenCL constants to the SPIR-V equivalents.
    const auto ConstantScopeDevice = ConstantInt::get(IntTy, spv::ScopeDevice);
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

    return clspv::InsertSPIRVOp(CI, Op, {}, CI->getType(), Params);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAtomics(Function &F,
                                              llvm::AtomicRMWInst::BinOp Op) {
  return replaceCallsWithValue(F, [&](CallInst *CI) {
    auto align = F.getParent()->getDataLayout().getABITypeAlign(
        CI->getArgOperand(1)->getType());
    return new AtomicRMWInst(Op, CI->getArgOperand(0), CI->getArgOperand(1),
                             align, AtomicOrdering::SequentiallyConsistent,
                             SyncScope::System, CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceCross(Function &F) {
  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {
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
    auto NewFName = Builtins::GetMangledFunctionName("cross", NewFType);

    auto Cross3Func = M.getOrInsertFunction(NewFName, NewFType);

    auto DownResult = CallInst::Create(Cross3Func, {Arg0, Arg1}, "", CI);

    return new ShuffleVectorInst(DownResult, ConstantVector::get(FloatVec),
                                 ConstantVector::get(UpShuffleMask), "", CI);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceFract(Function &F, int vec_size) {
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
  //       %glsl_ext Nmin %fract_intermediate %just_under_1

  using std::string;

  // Mapping from the fract builtin to the floor, fmin, and clspv.fract builtins
  // we need.  The clspv.fract builtin is the same as GLSL.std.450 Fract.

  Module &M = *F.getParent();
  return replaceCallsWithValue(F, [&](CallInst *CI) {

    // This is either float or a float vector.  All the float-like
    // types are this type.
    auto result_ty = F.getReturnType();

    std::string fmin_name = Builtins::GetMangledFunctionName("fmin", result_ty);
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

    std::string floor_name =
        Builtins::GetMangledFunctionName("floor", result_ty);
    Function *floor_fn = M.getFunction(floor_name);
    if (!floor_fn) {
      // Make the floor function.
      FunctionType *fn_ty = FunctionType::get(result_ty, {result_ty}, false);
      floor_fn =
          cast<Function>(M.getOrInsertFunction(floor_name, fn_ty).getCallee());
      floor_fn->addFnAttr(Attribute::ReadNone);
      floor_fn->setCallingConv(CallingConv::SPIR_FUNC);
    }

    std::string clspv_fract_name =
        Builtins::GetMangledFunctionName("clspv.fract", result_ty);
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
      llvm_unreachable("Unhandled float type when processing fract builtin");
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
          cast<VectorType>(result_ty)->getElementCount(), just_under_one);
    }

    IRBuilder<> Builder(CI);

    auto arg = CI->getArgOperand(0);
    auto ptr = CI->getArgOperand(1);

    // Compute floor result and store it.
    auto floor = Builder.CreateCall(floor_fn, {arg});
    Builder.CreateStore(floor, ptr);

    auto fract_intermediate = Builder.CreateCall(clspv_fract_fn, arg);
    auto fract_result =
        Builder.CreateCall(fmin_fn, {fract_intermediate, just_under_one});

    return fract_result;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceHadd(Function &F, bool is_signed,
                                           Instruction::BinaryOps join_opcode) {
  return replaceCallsWithValue(F, [is_signed, join_opcode](CallInst *Call) {
    // a_shr = a >> 1
    // b_shr = b >> 1
    // add1 = a_shr + b_shr
    // join = a |join_opcode| b
    // and = join & 1
    // add = add1 + and
    const auto a = Call->getArgOperand(0);
    const auto b = Call->getArgOperand(1);
    IRBuilder<> builder(Call);
    Value *a_shift, *b_shift;
    if (is_signed) {
      a_shift = builder.CreateAShr(a, 1);
      b_shift = builder.CreateAShr(b, 1);
    } else {
      a_shift = builder.CreateLShr(a, 1);
      b_shift = builder.CreateLShr(b, 1);
    }
    auto add = builder.CreateAdd(a_shift, b_shift);
    auto join = BinaryOperator::Create(join_opcode, a, b, "", Call);
    auto constant_one = ConstantInt::get(a->getType(), 1);
    auto and_bit = builder.CreateAnd(join, constant_one);
    return builder.CreateAdd(add, and_bit);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAddSubSat(Function &F, bool is_signed,
                                                bool is_add) {
  return replaceCallsWithValue(F, [&F, this, is_signed,
                                   is_add](CallInst *Call) {
    auto ty = Call->getType();
    auto a = Call->getArgOperand(0);
    auto b = Call->getArgOperand(1);
    IRBuilder<> builder(Call);
    if (is_signed) {
      unsigned bitwidth = ty->getScalarSizeInBits();
      if (bitwidth < 32) {
        unsigned extended_width = bitwidth << 1;
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
      // carr/borrow.
      spv::Op op = is_add ? spv::OpIAddCarry : spv::OpISubBorrow;
      auto clamp_value =
          is_add ? Constant::getAllOnesValue(ty) : Constant::getNullValue(ty);
      auto struct_ty = GetPairStruct(ty);
      auto call =
          InsertSPIRVOp(Call, op, {Attribute::ReadNone}, struct_ty, {a, b});
      auto add_sub = builder.CreateExtractValue(call, {0});
      auto carry_borrow = builder.CreateExtractValue(call, {1});
      auto cmp = builder.CreateICmpEQ(carry_borrow, Constant::getNullValue(ty));
      return builder.CreateSelect(cmp, add_sub, clamp_value);
    }
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAtomicLoad(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *Call) {
    auto pointer = Call->getArgOperand(0);
    // Clang emits an address space cast to the generic address space. Skip the
    // cast and use the input directly.
    if (auto cast = dyn_cast<AddrSpaceCastOperator>(pointer)) {
      pointer = cast->getPointerOperand();
    }
    Value *order_arg =
        Call->getNumArgOperands() > 1 ? Call->getArgOperand(1) : nullptr;
    Value *scope_arg =
        Call->getNumArgOperands() > 2 ? Call->getArgOperand(2) : nullptr;
    bool is_global = pointer->getType()->getPointerAddressSpace() ==
                     clspv::AddressSpace::Global;
    auto order = MemoryOrderSemantics(order_arg, is_global, Call,
                                      spv::MemorySemanticsAcquireMask);
    auto scope = MemoryScope(scope_arg, is_global, Call);
    return InsertSPIRVOp(Call, spv::OpAtomicLoad, {Attribute::Convergent},
                         Call->getType(), {pointer, scope, order});
  });
}

bool ReplaceOpenCLBuiltinPass::replaceExplicitAtomics(
    Function &F, spv::Op Op, spv::MemorySemanticsMask semantics) {
  return replaceCallsWithValue(F, [Op, semantics](CallInst *Call) {
    auto pointer = Call->getArgOperand(0);
    // Clang emits an address space cast to the generic address space. Skip the
    // cast and use the input directly.
    if (auto cast = dyn_cast<AddrSpaceCastOperator>(pointer)) {
      pointer = cast->getPointerOperand();
    }
    Value *value = Call->getArgOperand(1);
    Value *order_arg =
        Call->getNumArgOperands() > 2 ? Call->getArgOperand(2) : nullptr;
    Value *scope_arg =
        Call->getNumArgOperands() > 3 ? Call->getArgOperand(3) : nullptr;
    bool is_global = pointer->getType()->getPointerAddressSpace() ==
                     clspv::AddressSpace::Global;
    auto scope = MemoryScope(scope_arg, is_global, Call);
    auto order = MemoryOrderSemantics(order_arg, is_global, Call, semantics);
    return InsertSPIRVOp(Call, Op, {Attribute::Convergent}, Call->getType(),
                         {pointer, scope, order, value});
  });
}

bool ReplaceOpenCLBuiltinPass::replaceAtomicCompareExchange(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *Call) {
    auto pointer = Call->getArgOperand(0);
    // Clang emits an address space cast to the generic address space. Skip the
    // cast and use the input directly.
    if (auto cast = dyn_cast<AddrSpaceCastOperator>(pointer)) {
      pointer = cast->getPointerOperand();
    }
    auto expected = Call->getArgOperand(1);
    if (auto cast = dyn_cast<AddrSpaceCastOperator>(expected)) {
      expected = cast->getPointerOperand();
    }
    auto value = Call->getArgOperand(2);
    bool is_global = pointer->getType()->getPointerAddressSpace() ==
                     clspv::AddressSpace::Global;
    Value *success_arg =
        Call->getNumArgOperands() > 3 ? Call->getArgOperand(3) : nullptr;
    Value *failure_arg =
        Call->getNumArgOperands() > 4 ? Call->getArgOperand(4) : nullptr;
    Value *scope_arg =
        Call->getNumArgOperands() > 5 ? Call->getArgOperand(5) : nullptr;
    auto scope = MemoryScope(scope_arg, is_global, Call);
    auto success = MemoryOrderSemantics(success_arg, is_global, Call,
                                        spv::MemorySemanticsAcquireReleaseMask);
    auto failure = MemoryOrderSemantics(failure_arg, is_global, Call,
                                        spv::MemorySemanticsAcquireMask);

    // If the value pointed to by |expected| equals the value pointed to by
    // |pointer|, |value| is written into |pointer|, otherwise the value in
    // |pointer| is written into |expected|. In order to avoid extra stores,
    // the basic block with the original atomic is split and the store is
    // performed in the |then| block. The condition is the inversion of the
    // comparison result.
    IRBuilder<> builder(Call);
    auto load = builder.CreateLoad(expected);
    auto cmp_xchg = InsertSPIRVOp(
        Call, spv::OpAtomicCompareExchange, {Attribute::Convergent},
        value->getType(), {pointer, scope, success, failure, value, load});
    auto cmp = builder.CreateICmpEQ(cmp_xchg, load);
    auto not_cmp = builder.CreateNot(cmp);
    auto then_branch = SplitBlockAndInsertIfThen(not_cmp, Call, false);
    builder.SetInsertPoint(then_branch);
    builder.CreateStore(cmp_xchg, expected);
    return cmp;
  });
}

bool ReplaceOpenCLBuiltinPass::replaceCountZeroes(Function &F, bool leading) {
  if (!isa<IntegerType>(F.getReturnType()->getScalarType()))
    return false;

  auto bitwidth = F.getReturnType()->getScalarSizeInBits();
  if (bitwidth > 64)
    return false;

  return replaceCallsWithValue(F, [&F, leading](CallInst *Call) {
    Function *intrinsic = Intrinsic::getDeclaration(
        F.getParent(), leading ? Intrinsic::ctlz : Intrinsic::cttz,
        Call->getType());
    const auto c_false = ConstantInt::getFalse(Call->getContext());
    return CallInst::Create(intrinsic->getFunctionType(), intrinsic,
                            {Call->getArgOperand(0), c_false}, "", Call);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceMadSat(Function &F, bool is_signed) {
  return replaceCallsWithValue(F, [&F, is_signed, this](CallInst *Call) {
    const auto ty = Call->getType();
    const auto a = Call->getArgOperand(0);
    const auto b = Call->getArgOperand(1);
    const auto c = Call->getArgOperand(2);
    IRBuilder<> builder(Call);
    if (is_signed) {
      unsigned bitwidth = Call->getType()->getScalarSizeInBits();
      if (bitwidth < 32) {
        // mul = sext(a) * sext(b)
        // add = mul + sext(c)
        // res = clamp(add, MIN, MAX)
        unsigned extended_width = bitwidth << 1;
        Type *extended_ty = IntegerType::get(F.getContext(), extended_width);
        if (auto vec_ty = dyn_cast<VectorType>(ty)) {
          extended_ty = VectorType::get(extended_ty, vec_ty->getElementCount());
        }
        auto a_sext = builder.CreateSExt(a, extended_ty);
        auto b_sext = builder.CreateSExt(b, extended_ty);
        auto c_sext = builder.CreateSExt(c, extended_ty);
        // Extended the size so no overflows occur.
        auto mul = builder.CreateMul(a_sext, b_sext, "", true, true);
        auto add = builder.CreateAdd(mul, c_sext, "", true, true);
        auto func_ty = FunctionType::get(
            extended_ty, {extended_ty, extended_ty, extended_ty}, false);
        // Don't use function type because we need signed parameters.
        std::string clamp_name = Builtins::GetMangledFunctionName("clamp");
        // The clamp values are the signed min and max of the original bitwidth
        // sign extended to the extended bitwidth.
        Constant *min = ConstantInt::get(
            Call->getContext(),
            APInt::getSignedMinValue(bitwidth).sext(extended_width));
        Constant *max = ConstantInt::get(
            Call->getContext(),
            APInt::getSignedMaxValue(bitwidth).sext(extended_width));
        if (auto vec_ty = dyn_cast<VectorType>(ty)) {
          min = ConstantVector::getSplat(vec_ty->getElementCount(), min);
          max = ConstantVector::getSplat(vec_ty->getElementCount(), max);
          unsigned vec_width = vec_ty->getElementCount().getKnownMinValue();
          if (extended_width == 32)
            clamp_name += "Dv" + std::to_string(vec_width) + "_iS_S_";
          else
            clamp_name += "Dv" + std::to_string(vec_width) + "_sS_S_";
        } else {
          if (extended_width == 32)
            clamp_name += "iii";
          else
            clamp_name += "sss";
        }
        auto callee = F.getParent()->getOrInsertFunction(clamp_name, func_ty);
        auto clamp = builder.CreateCall(callee, {add, min, max});
        return builder.CreateTrunc(clamp, ty);
      } else {
        auto struct_ty = GetPairStruct(ty);
        // Compute
        // {hi, lo} = smul_extended(a, b)
        // add = lo + c
        auto mul_ext = InsertSPIRVOp(Call, spv::OpSMulExtended,
                                     {Attribute::ReadNone}, struct_ty, {a, b});
        auto mul_lo = builder.CreateExtractValue(mul_ext, {0});
        auto mul_hi = builder.CreateExtractValue(mul_ext, {1});
        auto add = builder.CreateAdd(mul_lo, c);

        // Constants for use in the calculation.
        Constant *min = ConstantInt::get(Call->getContext(),
                                         APInt::getSignedMinValue(bitwidth));
        Constant *max = ConstantInt::get(Call->getContext(),
                                         APInt::getSignedMaxValue(bitwidth));
        Constant *max_plus_1 = ConstantInt::get(
            Call->getContext(),
            APInt::getSignedMaxValue(bitwidth) + APInt(bitwidth, 1));
        if (auto vec_ty = dyn_cast<VectorType>(ty)) {
          min = ConstantVector::getSplat(vec_ty->getElementCount(), min);
          max = ConstantVector::getSplat(vec_ty->getElementCount(), max);
          max_plus_1 =
              ConstantVector::getSplat(vec_ty->getElementCount(), max_plus_1);
        }

        auto a_xor_b = builder.CreateXor(a, b);
        auto same_sign =
            builder.CreateICmpSGT(a_xor_b, Constant::getAllOnesValue(ty));
        auto different_sign = builder.CreateNot(same_sign);
        auto hi_eq_0 = builder.CreateICmpEQ(mul_hi, Constant::getNullValue(ty));
        auto hi_ne_0 = builder.CreateNot(hi_eq_0);
        auto lo_ge_max = builder.CreateICmpUGE(mul_lo, max);
        auto c_gt_0 = builder.CreateICmpSGT(c, Constant::getNullValue(ty));
        auto c_lt_0 = builder.CreateICmpSLT(c, Constant::getNullValue(ty));
        auto add_gt_max = builder.CreateICmpUGT(add, max);
        auto hi_eq_m1 =
            builder.CreateICmpEQ(mul_hi, Constant::getAllOnesValue(ty));
        auto hi_ne_m1 = builder.CreateNot(hi_eq_m1);
        auto lo_le_max_plus_1 = builder.CreateICmpULE(mul_lo, max_plus_1);
        auto max_sub_lo = builder.CreateSub(max, mul_lo);
        auto c_lt_max_sub_lo = builder.CreateICmpULT(c, max_sub_lo);

        // Equivalent to:
        // if (((x < 0) == (y < 0)) && mul_hi != 0)
        //   return MAX
        // if (mul_hi == 0 && mul_lo >= MAX && (z > 0 || add > MAX))
        //   return MAX
        // if (((x < 0) != (y < 0)) && mul_hi != -1)
        //   return MIN
        // if (hi == -1 && mul_lo <= (MAX + 1) && (z < 0 || z < (MAX - mul_lo))
        //   return MIN
        // return add
        auto max_clamp_1 = builder.CreateAnd(same_sign, hi_ne_0);
        auto max_clamp_2 = builder.CreateOr(c_gt_0, add_gt_max);
        auto tmp = builder.CreateAnd(hi_eq_0, lo_ge_max);
        max_clamp_2 = builder.CreateAnd(tmp, max_clamp_2);
        auto max_clamp = builder.CreateOr(max_clamp_1, max_clamp_2);
        auto min_clamp_1 = builder.CreateAnd(different_sign, hi_ne_m1);
        auto min_clamp_2 = builder.CreateOr(c_lt_0, c_lt_max_sub_lo);
        tmp = builder.CreateAnd(hi_eq_m1, lo_le_max_plus_1);
        min_clamp_2 = builder.CreateAnd(tmp, min_clamp_2);
        auto min_clamp = builder.CreateOr(min_clamp_1, min_clamp_2);
        auto sel = builder.CreateSelect(min_clamp, min, add);
        return builder.CreateSelect(max_clamp, max, sel);
      }
    } else {
      // {lo, hi} = mul_extended(a, b)
      // {add, carry} = add_carry(lo, c)
      // cmp = (mul_hi | carry) == 0
      // mad_sat = cmp ? add : MAX
      auto struct_ty = GetPairStruct(ty);
      auto mul_ext = InsertSPIRVOp(Call, spv::OpUMulExtended,
                                   {Attribute::ReadNone}, struct_ty, {a, b});
      auto mul_lo = builder.CreateExtractValue(mul_ext, {0});
      auto mul_hi = builder.CreateExtractValue(mul_ext, {1});
      auto add_carry =
          InsertSPIRVOp(Call, spv::OpIAddCarry, {Attribute::ReadNone},
                        struct_ty, {mul_lo, c});
      auto add = builder.CreateExtractValue(add_carry, {0});
      auto carry = builder.CreateExtractValue(add_carry, {1});
      auto or_value = builder.CreateOr(mul_hi, carry);
      auto cmp = builder.CreateICmpEQ(or_value, Constant::getNullValue(ty));
      return builder.CreateSelect(cmp, add, Constant::getAllOnesValue(ty));
    }
  });
}

bool ReplaceOpenCLBuiltinPass::replaceOrdered(Function &F, bool is_ordered) {
  if (!isa<IntegerType>(F.getReturnType()->getScalarType()))
    return false;

  if (F.getFunctionType()->getNumParams() != 2)
    return false;

  if (F.getFunctionType()->getParamType(0) !=
      F.getFunctionType()->getParamType(1)) {
    return false;
  }

  switch (F.getFunctionType()->getParamType(0)->getScalarType()->getTypeID()) {
  case Type::FloatTyID:
  case Type::HalfTyID:
  case Type::DoubleTyID:
    break;
  default:
    return false;
  }

  // Scalar versions all return an int, while vector versions return a vector
  // of an equally sized integer types (e.g. short, int or long).
  if (isa<VectorType>(F.getReturnType())) {
    if (F.getReturnType()->getScalarSizeInBits() !=
        F.getFunctionType()->getParamType(0)->getScalarSizeInBits()) {
      return false;
    }
  } else {
    if (F.getReturnType()->getScalarSizeInBits() != 32)
      return false;
  }

  return replaceCallsWithValue(F, [is_ordered](CallInst *Call) {
    // Replace with a floating point [un]ordered comparison followed by an
    // extension.
    auto x = Call->getArgOperand(0);
    auto y = Call->getArgOperand(1);
    IRBuilder<> builder(Call);
    Value *tmp = nullptr;
    if (is_ordered) {
      // This leads to a slight inefficiency in the SPIR-V that is easy for
      // drivers to optimize where the SPIR-V for the comparison and the
      // extension could be fused to drop the inversion of the OpIsNan.
      tmp = builder.CreateFCmpORD(x, y);
    } else {
      tmp = builder.CreateFCmpUNO(x, y);
    }
    // OpenCL CTS requires that vector versions use sign extension, but scalar
    // versions use zero extension.
    if (isa<VectorType>(Call->getType()))
      return builder.CreateSExt(tmp, Call->getType());
    return builder.CreateZExt(tmp, Call->getType());
  });
}

bool ReplaceOpenCLBuiltinPass::replaceIsNormal(Function &F) {
  return replaceCallsWithValue(F, [this](CallInst *Call) {
    auto ty = Call->getType();
    auto x = Call->getArgOperand(0);
    unsigned width = x->getType()->getScalarSizeInBits();
    Type *int_ty = IntegerType::get(Call->getContext(), width);
    uint64_t abs_mask = 0x7fffffff;
    uint64_t exp_mask = 0x7f800000;
    uint64_t min_mask = 0x00800000;
    if (width == 16) {
      abs_mask = 0x7fff;
      exp_mask = 0x7c00;
      min_mask = 0x0400;
    } else if (width == 64) {
      abs_mask = 0x7fffffffffffffff;
      exp_mask = 0x7ff0000000000000;
      min_mask = 0x0010000000000000;
    }
    Constant *abs_const = ConstantInt::get(int_ty, APInt(width, abs_mask));
    Constant *exp_const = ConstantInt::get(int_ty, APInt(width, exp_mask));
    Constant *min_const = ConstantInt::get(int_ty, APInt(width, min_mask));
    if (auto vec_ty = dyn_cast<VectorType>(ty)) {
      int_ty = VectorType::get(int_ty, vec_ty->getElementCount());
      abs_const =
          ConstantVector::getSplat(vec_ty->getElementCount(), abs_const);
      exp_const =
          ConstantVector::getSplat(vec_ty->getElementCount(), exp_const);
      min_const =
          ConstantVector::getSplat(vec_ty->getElementCount(), min_const);
    }
    // Drop the sign bit and then check that the number is between
    // (exclusive) the min and max exponent values for the bit width.
    IRBuilder<> builder(Call);
    auto bitcast = builder.CreateBitCast(x, int_ty);
    auto abs = builder.CreateAnd(bitcast, abs_const);
    auto lt = builder.CreateICmpULT(abs, exp_const);
    auto ge = builder.CreateICmpUGE(abs, min_const);
    auto tmp = builder.CreateAnd(lt, ge);
    // OpenCL CTS requires that vector versions use sign extension, but scalar
    // versions use zero extension.
    if (isa<VectorType>(ty))
      return builder.CreateSExt(tmp, ty);
    return builder.CreateZExt(tmp, ty);
  });
}

bool ReplaceOpenCLBuiltinPass::replaceFDim(Function &F) {
  return replaceCallsWithValue(F, [](CallInst *Call) {
    const auto x = Call->getArgOperand(0);
    const auto y = Call->getArgOperand(1);
    IRBuilder<> builder(Call);
    auto sub = builder.CreateFSub(x, y);
    auto cmp = builder.CreateFCmpUGT(x, y);
    return builder.CreateSelect(cmp, sub,
                                Constant::getNullValue(Call->getType()));
  });
}
