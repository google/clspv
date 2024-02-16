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
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "Constants.h"
#include "DefineOpenCLWorkItemBuiltinsPass.h"
#include "PushConstant.h"
#include "Types.h"

using namespace llvm;
using namespace clspv;

namespace {
constexpr auto enqueued_local_size_mangled_name =
    "_Z23get_enqueued_local_sizej";
constexpr auto enqueued_num_sub_groups_mangled_name =
    "_Z27get_enqueued_num_sub_groupsv";
constexpr auto global_id_mangled_name = "_Z13get_global_idj";
constexpr auto global_linear_id_mangled_name = "_Z20get_global_linear_idv";
constexpr auto global_offset_mangled_name = "_Z17get_global_offsetj";
constexpr auto global_size_mangled_name = "_Z15get_global_sizej";
constexpr auto group_id_mangled_name = "_Z12get_group_idj";
constexpr auto local_id_mangled_name = "_Z12get_local_idj";
constexpr auto local_linear_id_mangled_name = "_Z19get_local_linear_idv";
constexpr auto local_size_mangled_name = "_Z14get_local_sizej";
constexpr auto max_sub_group_size_mangled_name = "_Z22get_max_sub_group_sizev";
constexpr auto num_groups_mangled_name = "_Z14get_num_groupsj";
constexpr auto work_dim_mangled_name = "_Z12get_work_dimv";

Value *inBoundsDimensionCondition(IRBuilder<> &Builder, Value *Dim) {
  // Vulkan has 3 dimensions for work-items, but the OpenCL API is written
  // such that it could have more. We have to check whether the value provided
  // was less than 3...
  return Builder.CreateICmp(CmpInst::ICMP_ULT, Dim, Builder.getInt32(3));
}

Value *inBoundsDimensionIndex(IRBuilder<> &Builder, Value *Dim) {
  auto Cond = inBoundsDimensionCondition(Builder, Dim);
  // Select dimension 0 if the requested dimension was greater than
  // 2, otherwise return the requested dimension.
  return Builder.CreateSelect(Cond, Dim, Builder.getInt32(0));
}

Value *inBoundsDimensionOrDefaultValue(IRBuilder<> &Builder, Value *Dim,
                                       Value *Val, int DefaultValue) {
  auto Cond = inBoundsDimensionCondition(Builder, Dim);
  return Builder.CreateSelect(Cond, Val, Builder.getInt32(DefaultValue));
}

// Retrieve the function if it's needed directly or by a dependent
Function *getFunctionIfNeeded(Module &M, StringRef Name,
                              ArrayRef<StringRef> Dependents,
                              FunctionType *FType) {
  Function *F = M.getFunction(Name);
  if (F)
    return F; // function is used directly

  for (auto &Dependent : Dependents) {
    auto D = M.getFunction(Dependent);
    if (D) {
      // function must be inserted for use by dependent
      F = cast<Function>(M.getOrInsertFunction(Name, FType).getCallee());
      F->setIsNewDbgInfoFormat(true);
      F->setCallingConv(CallingConv::SPIR_FUNC);
      return F;
    }
  }
  return nullptr;
}
} // namespace

PreservedAnalyses
DefineOpenCLWorkItemBuiltinsPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  defineGlobalOffsetBuiltin(M);
  defineGlobalIDBuiltin(M);

  defineMappedBuiltin(
      M, local_size_mangled_name, clspv::WorkgroupSizeVariableName(), 1,
      clspv::WorkgroupSizeAddressSpace(), {local_linear_id_mangled_name});
  defineMappedBuiltin(
      M, local_id_mangled_name, clspv::LocalInvocationIdVariableName(), 0,
      clspv::LocalInvocationIdAddressSpace(), {local_linear_id_mangled_name});
  defineNumGroupsBuiltin(M);
  defineGroupIDBuiltin(M);
  defineGlobalSizeBuiltin(M);
  defineWorkDimBuiltin(M);
  defineEnqueuedLocalSizeBuiltin(M);
  defineMaxSubGroupSizeBuiltin(M);
  defineEnqueuedNumSubGroupsBuiltin(M);
  addWorkgroupSizeIfRequired(M);

  defineGlobalLinearIDBuiltin(M);
  defineLocalLinearIDBuiltin(M);

  return PA;
}

GlobalVariable *DefineOpenCLWorkItemBuiltinsPass::createGlobalVariable(
    Module &M, StringRef GlobalVarName, Type *Ty,
    AddressSpace::Type AddrSpace) {
  auto GV = new GlobalVariable(
      M, Ty, false, GlobalValue::ExternalLinkage, nullptr, GlobalVarName,
      nullptr, GlobalValue::ThreadLocalMode::NotThreadLocal, AddrSpace);

  GV->setInitializer(Constant::getNullValue(Ty));

  return GV;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineMappedBuiltin(
    Module &M, StringRef FuncName, StringRef GlobalVarName,
    unsigned DefaultValue, AddressSpace::Type AddrSpace,
    ArrayRef<StringRef> dependents) {

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  IntegerType *SizeT =
      clspv::PointersAre64Bit(M) ? IntegerType::get(M.getContext(), 64) : IT;
  auto FType = FunctionType::get(SizeT, IT, false);
  Function *F = getFunctionIfNeeded(M, FuncName, dependents, FType);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  VectorType *VT = FixedVectorType::get(IT, 3);

  GlobalVariable *GV = createGlobalVariable(M, GlobalVarName, VT, AddrSpace);

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);

  Value *Result = nullptr;
  if (GlobalVarName == "__spirv_WorkgroupSize") {
    // Ugly hack to work around implementation bugs.
    // Load the whole vector and extract the result
    Value *LoadVec = Builder.CreateLoad(GV->getValueType(), GV);
    Result = Builder.CreateExtractElement(LoadVec, InBoundsDim);
  } else {
    Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
    Value *GEP = Builder.CreateGEP(VT, GV, Indices);
    Result = Builder.CreateLoad(IT, GEP);
  }

  Value *Select2 =
      inBoundsDimensionOrDefaultValue(Builder, Dim, Result, DefaultValue);

  Select2 = Builder.CreateZExt(Select2, SizeT);
  Builder.CreateRet(Select2);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalIDBuiltin(Module &M) {
  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  IntegerType *I64T = IntegerType::get(M.getContext(), 64);
  auto FType =
      FunctionType::get(clspv::PointersAre64Bit(M) ? I64T : IT, IT, false);

  Function *F = getFunctionIfNeeded(M, global_id_mangled_name,
                                    {global_linear_id_mangled_name}, FType);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  VectorType *VT = FixedVectorType::get(IT, 3);

  GlobalVariable *GV = createGlobalVariable(M, "__spirv_GlobalInvocationId", VT,
                                            AddressSpace::Input);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);

  Value *Result = nullptr;
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
  Value *GEP = Builder.CreateGEP(GV->getValueType(), GV, Indices);
  Result = Builder.CreateLoad(IT, GEP);

  auto GidBase = inBoundsDimensionOrDefaultValue(Builder, Dim, Result, 0);

  // The underlying GlobalInvocationId will always be 32-bit, but this needs
  // to be promoted when size_t is 64-bit.
  if (clspv::PointersAre64Bit(M)) {
    GidBase = Builder.CreateZExt(GidBase, I64T);
  }

  Value *Ret = GidBase;
  if (clspv::Option::NonUniformNDRangeSupported()) {
    auto Ptr = GetPushConstantPointer(BB, clspv::PushConstant::RegionOffset);
    auto DimPtr = Builder.CreateInBoundsGEP(VT, Ptr, Indices);
    auto Size = Builder.CreateLoad(IT, DimPtr);
    auto RegOff = inBoundsDimensionOrDefaultValue(Builder, Dim, Size, 0);
    if (clspv::PointersAre64Bit(M)) {
      RegOff = Builder.CreateZExt(RegOff, I64T);
    }
    Ret = Builder.CreateAdd(Ret, RegOff);
  } else {
    // If we have a global offset we need to add it
    if (clspv::Option::GlobalOffset() ||
        clspv::Option::GlobalOffsetPushConstant()) {
      auto Goff =
          Builder.CreateCall(M.getFunction(global_offset_mangled_name), Dim);
      Goff->setCallingConv(CallingConv::SPIR_FUNC);
      Ret = Builder.CreateAdd(Ret, Goff);
    }
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalSizeBuiltin(Module &M) {
  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  IntegerType *SizeT =
      clspv::PointersAre64Bit(M) ? IntegerType::get(M.getContext(), 64) : IT;
  auto FType = FunctionType::get(SizeT, IT, false);
  Function *F = getFunctionIfNeeded(M, global_size_mangled_name,
                                    {global_linear_id_mangled_name}, FType);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};

  Value *GlobalSize;
  if (clspv::Option::NonUniformNDRangeSupported()) {
    auto Ptr = GetPushConstantPointer(BB, clspv::PushConstant::GlobalSize);
    auto Ty = GetPushConstantType(M, clspv::PushConstant::GlobalSize);
    auto DimPtr = Builder.CreateInBoundsGEP(Ty, Ptr, Indices);
    GlobalSize = Builder.CreateLoad(Ty->getScalarType(), DimPtr);
  } else {
    IntegerType *IT = IntegerType::get(M.getContext(), 32);
    VectorType *VT = FixedVectorType::get(IT, 3);

    // Global size uses two builtin variables that might already have been
    // created.
    StringRef WorkgroupSize = "__spirv_WorkgroupSize";
    StringRef NumWorkgroups = "__spirv_NumWorkgroups";

    GlobalVariable *WGS = M.getGlobalVariable(WorkgroupSize);

    // If the module does not already have workgroup size.
    if (nullptr == WGS) {
      WGS = createGlobalVariable(M, WorkgroupSize, VT,
                                 AddressSpace::ModuleScopePrivate);
    }

    GlobalVariable *NWG = M.getGlobalVariable(NumWorkgroups);

    // If the module does not already have num workgroups.
    if (nullptr == NWG) {
      NWG = createGlobalVariable(M, NumWorkgroups, VT, AddressSpace::Input);
    }

    // Load the workgroup size.
    Value *GEP = Builder.CreateGEP(VT, WGS, Indices);
    Value *LoadWGS = Builder.CreateLoad(IT, GEP);

    // And the number of workgroups.
    GEP = Builder.CreateGEP(VT, NWG, Indices);
    Value *LoadNWG = Builder.CreateLoad(IT, GEP);

    // We multiply the workgroup size by the number of workgroups to calculate
    // the global size.
    GlobalSize = Builder.CreateMul(LoadWGS, LoadNWG);
  }

  GlobalSize = inBoundsDimensionOrDefaultValue(Builder, Dim, GlobalSize, 1);

  if (clspv::PointersAre64Bit(M)) {
    GlobalSize =
        Builder.CreateZExt(GlobalSize, IntegerType::get(M.getContext(), 64));
  }

  Builder.CreateRet(GlobalSize);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineNumGroupsBuiltin(Module &M) {

  Function *F = M.getFunction(num_groups_mangled_name);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  Value *NumGroupsVarPtr;
  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  VectorType *VT = FixedVectorType::get(IT, 3);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};

  if (clspv::Option::NonUniformNDRangeSupported()) {
    NumGroupsVarPtr =
        GetPushConstantPointer(BB, clspv::PushConstant::NumWorkgroups);
  } else {
    NumGroupsVarPtr = createGlobalVariable(M, "__spirv_NumWorkgroups", VT,
                                           AddressSpace::Input);
  }

  auto NumGroupsPtr = Builder.CreateInBoundsGEP(VT, NumGroupsVarPtr, Indices);
  auto NumGroups = Builder.CreateLoad(IT, NumGroupsPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, NumGroups, 1);

  if (clspv::PointersAre64Bit(M)) {
    Ret = Builder.CreateZExt(Ret, IntegerType::get(M.getContext(), 64));
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGroupIDBuiltin(Module &M) {

  Function *F = M.getFunction(group_id_mangled_name);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  VectorType *VT = FixedVectorType::get(IT, 3);
  auto RegionGroupIDVarPtr =
      createGlobalVariable(M, "__spirv_WorkgroupId", VT, AddressSpace::Input);

  auto RegionGroupIDPtr =
      Builder.CreateInBoundsGEP(VT, RegionGroupIDVarPtr, Indices);
  auto RegionGroupID = Builder.CreateLoad(IT, RegionGroupIDPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, RegionGroupID, 0);

  if (clspv::Option::NonUniformNDRangeSupported()) {
    auto RegionGroupOffsetVarPtr =
        GetPushConstantPointer(BB, clspv::PushConstant::RegionGroupOffset);
    auto RegionGroupOffsetPtr =
        Builder.CreateInBoundsGEP(VT, RegionGroupOffsetVarPtr, Indices);
    auto RegionGroupOffsetVal = Builder.CreateLoad(IT, RegionGroupOffsetPtr);
    auto RegionGroupOffset =
        inBoundsDimensionOrDefaultValue(Builder, Dim, RegionGroupOffsetVal, 0);

    Ret = Builder.CreateAdd(Ret, RegionGroupOffset);
  }

  if (clspv::PointersAre64Bit(M)) {
    Ret = Builder.CreateZExt(Ret, IntegerType::get(M.getContext(), 64));
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalOffsetBuiltin(Module &M) {
  auto Int32Ty = IntegerType::get(M.getContext(), 32);
  auto Int64Ty = IntegerType::get(M.getContext(), 64);
  auto FRetType = clspv::PointersAre64Bit(M) ? Int64Ty : Int32Ty;
  auto FType = FunctionType::get(FRetType, Int32Ty, false);

  Function *F = getFunctionIfNeeded(
      M, global_offset_mangled_name,
      {global_id_mangled_name, global_linear_id_mangled_name}, FType);

  // Only define get_global_offset when it is used or the option is enabled
  // and get_global_id is used (since it is used in global ID calculations).
  if (F == nullptr) {
    return false;
  }

  bool isSupportEnabled = clspv::Option::GlobalOffset() ||
                          clspv::Option::GlobalOffsetPushConstant();

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  Value *Ret;
  if (isSupportEnabled) {
    auto Dim = &*F->arg_begin();
    auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
    Value *gep = nullptr;
    auto *VecTy = FixedVectorType::get(Int32Ty, 3);
    const bool uses_push_constant =
        clspv::ShouldDeclareGlobalOffsetPushConstant(M);
    if (uses_push_constant) {
      Value *Indices[] = {InBoundsDim};
      gep = GetPushConstantPointer(BB, clspv::PushConstant::GlobalOffset,
                                   Indices);
    } else {
      StringRef name = "__spirv_GlobalOffset";
      auto offset_var = createGlobalVariable(M, name, VecTy,
                                             AddressSpace::ModuleScopePrivate);
      Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
      gep = Builder.CreateInBoundsGEP(VecTy, offset_var, Indices);
    }
    auto load = Builder.CreateLoad(Int32Ty, gep);
    Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, load, 0);
  } else {
    // Get global offset is easy for us as it only returns 0.
    Ret =
        clspv::PointersAre64Bit(M) ? Builder.getInt64(0) : Builder.getInt32(0);
  }

  if (clspv::PointersAre64Bit(M)) {
    Ret = Builder.CreateZExt(Ret, IntegerType::get(M.getContext(), 64));
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalLinearIDBuiltin(Module &M) {
  Function *F = M.getFunction(global_linear_id_mangled_name);

  // Only define get_global_linear_id when it is used.
  if (F == nullptr) {
    return false;
  }

  bool useGlobalOffset = clspv::Option::GlobalOffset() ||
                         clspv::Option::GlobalOffsetPushConstant();
  auto GlobalOffsetFunc =
      useGlobalOffset ? M.getFunction(global_offset_mangled_name) : nullptr;
  assert(useGlobalOffset == (GlobalOffsetFunc != nullptr) &&
         "if useGlobalOffset is enabled it should have been created by now "
         "(since global_linear_id is a dependent of get_global_offset).");

  auto GlobalIdFunc = M.getFunction(global_id_mangled_name);
  auto GlobalSizeFunc = M.getFunction(global_size_mangled_name);

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  llvm::ConstantInt *Zero = Builder.getInt32(0);
  llvm::ConstantInt *One = Builder.getInt32(1);
  llvm::ConstantInt *Two = Builder.getInt32(2);

  auto addCallingConv = [](llvm::CallInst *call) {
    call->setCallingConv(CallingConv::SPIR_FUNC);
  };

  auto getDimSize = [&](llvm::ConstantInt *Dim) -> llvm::Value * {
    auto GID = Builder.CreateCall(GlobalIdFunc, Dim);
    addCallingConv(GID);
    if (useGlobalOffset) {
      auto Offset = Builder.CreateCall(GlobalOffsetFunc, Dim);
      addCallingConv(Offset);
      return Builder.CreateSub(GID, Offset);
    }
    return GID;
  };

  auto Dim0 = getDimSize(Zero);
  auto Dim1 = getDimSize(One);
  auto Dim2 = getDimSize(Two);

  auto GSize0 = Builder.CreateCall(GlobalSizeFunc, Zero);
  addCallingConv(GSize0);
  auto GSize1 = Builder.CreateCall(GlobalSizeFunc, One);
  addCallingConv(GSize1);

  // both get_global_id and get_global_offset default to 0 when the dimension is
  // >= get_work_dim(), so there is no need for branching here
  auto SecondDim = Builder.CreateMul(Dim1, GSize0);
  auto ThirdDim = Builder.CreateMul(Dim2, Builder.CreateMul(GSize0, GSize1));
  auto Sum = Builder.CreateAdd(ThirdDim, Builder.CreateAdd(SecondDim, Dim0));

  Builder.CreateRet(Sum);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineLocalLinearIDBuiltin(Module &M) {
  Function *F = M.getFunction(local_linear_id_mangled_name);

  // Only define get_local_linear_id when it is used.
  if (F == nullptr) {
    return false;
  }

  auto LocalIdFunc = M.getFunction(local_id_mangled_name);
  auto LocalSizeFunc = M.getFunction(local_size_mangled_name);

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  llvm::ConstantInt *Zero = Builder.getInt32(0);
  llvm::ConstantInt *One = Builder.getInt32(1);
  llvm::ConstantInt *Two = Builder.getInt32(2);

  auto addCallingConv = [](llvm::CallInst *call) {
    call->setCallingConv(CallingConv::SPIR_FUNC);
  };

  auto LID0 = Builder.CreateCall(LocalIdFunc, Zero);
  addCallingConv(LID0);
  auto LID1 = Builder.CreateCall(LocalIdFunc, One);
  addCallingConv(LID1);
  auto LID2 = Builder.CreateCall(LocalIdFunc, Two);
  addCallingConv(LID2);

  auto LSize0 = Builder.CreateCall(LocalSizeFunc, Zero);
  addCallingConv(LSize0);
  auto LSize1 = Builder.CreateCall(LocalSizeFunc, One);
  addCallingConv(LSize1);

  // get_local_id defaults to 0 when the dimension is >= get_work_dim(), so
  // there is no need for branching here
  auto SecondDim = Builder.CreateMul(LID1, LSize0);
  auto ThirdDim = Builder.CreateMul(LID2, Builder.CreateMul(LSize0, LSize1));
  auto Sum = Builder.CreateAdd(ThirdDim, Builder.CreateAdd(SecondDim, LID0));

  Builder.CreateRet(Sum);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineWorkDimBuiltin(Module &M) {
  Function *F = M.getFunction(work_dim_mangled_name);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  if (clspv::Option::WorkDim()) {
    IntegerType *IT = IntegerType::get(M.getContext(), 32);
    StringRef name = "__spirv_WorkDim";
    auto work_dim_var =
        createGlobalVariable(M, name, IT, AddressSpace::ModuleScopePrivate);
    auto load = Builder.CreateLoad(IT, work_dim_var);
    Builder.CreateRet(load);
  } else {
    // Get work dim is easy for us as it only returns 3.
    Builder.CreateRet(Builder.getInt32(3));
  }

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineEnqueuedLocalSizeBuiltin(
    Module &M) {

  auto Int32Ty = IntegerType::get(M.getContext(), 32);
  auto Int64Ty = IntegerType::get(M.getContext(), 64);
  auto FRetTy = clspv::PointersAre64Bit(M) ? Int64Ty : Int32Ty;
  auto FType = FunctionType::get(FRetTy, Int32Ty, false);
  Function *F =
      getFunctionIfNeeded(M, enqueued_local_size_mangled_name,
                          {enqueued_num_sub_groups_mangled_name}, FType);

  if (nullptr == F)
    return false;

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
  auto Ptr = GetPushConstantPointer(BB, clspv::PushConstant::EnqueuedLocalSize);
  auto *Ty = GetPushConstantType(M, clspv::PushConstant::EnqueuedLocalSize);
  auto DimPtr = Builder.CreateInBoundsGEP(Ty, Ptr, Indices);
  auto Size = Builder.CreateLoad(Ty->getScalarType(), DimPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, Size, 1);

  if (clspv::PointersAre64Bit(M)) {
    Ret = Builder.CreateZExt(Ret, Int64Ty);
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineMaxSubGroupSizeBuiltin(Module &M) {

  auto Int32Ty = IntegerType::get(M.getContext(), 32);
  auto FType = FunctionType::get(Int32Ty, false);
  Function *F =
      getFunctionIfNeeded(M, max_sub_group_size_mangled_name,
                          {enqueued_num_sub_groups_mangled_name}, FType);

  if (nullptr == F)
    return false;

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  StringRef name = "__spirv_SubgroupMaxSize";
  auto var =
      createGlobalVariable(M, name, IT, AddressSpace::ModuleScopePrivate);
  auto ret = Builder.CreateLoad(IT, var);
  Builder.CreateRet(ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineEnqueuedNumSubGroupsBuiltin(
    Module &M) {

  Function *F = M.getFunction(enqueued_num_sub_groups_mangled_name);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto FELS = M.getFunction(enqueued_local_size_mangled_name);

  Value *ELS0 = Builder.CreateCall(FELS, Builder.getInt32(0));
  cast<CallInst>(ELS0)->setCallingConv(CallingConv::SPIR_FUNC);
  Value *ELS1 = Builder.CreateCall(FELS, Builder.getInt32(1));
  cast<CallInst>(ELS1)->setCallingConv(CallingConv::SPIR_FUNC);
  Value *ELS2 = Builder.CreateCall(FELS, Builder.getInt32(2));
  cast<CallInst>(ELS2)->setCallingConv(CallingConv::SPIR_FUNC);

  auto ELS = Builder.CreateMul(ELS0, ELS1);
  ELS = Builder.CreateMul(ELS, ELS2);

  // get_enqueued_local size returns size_t but this builtin and
  // get_max_sub_group_size return uint, so truncate if needed
  if (clspv::PointersAre64Bit(M)) {
    ELS = Builder.CreateTrunc(ELS, Builder.getInt32Ty());
  }

  auto MaxSubgroupSize =
      Builder.CreateCall(M.getFunction(max_sub_group_size_mangled_name));
  MaxSubgroupSize->setCallingConv(CallingConv::SPIR_FUNC);

  auto ELSRoundedUp = Builder.CreateAdd(ELS, MaxSubgroupSize);
  ELSRoundedUp = Builder.CreateSub(ELSRoundedUp, Builder.getInt32(1));

  auto Ret = Builder.CreateUDiv(ELSRoundedUp, MaxSubgroupSize);

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::addWorkgroupSizeIfRequired(Module &M) {
  StringRef WorkgroupSize = "__spirv_WorkgroupSize";

  // If the module doesn't already have workgroup size.
  if (nullptr == M.getGlobalVariable(WorkgroupSize)) {
    for (auto &F : M) {
      if (F.getCallingConv() != llvm::CallingConv::SPIR_KERNEL) {
        continue;
      }

      // If this kernel does not have the reqd_work_group_size metadata, we need
      // to output the workgroup size variable.
      if (nullptr == F.getMetadata("reqd_work_group_size") ||
          clspv::Option::NonUniformNDRangeSupported()) {
        IntegerType *IT = IntegerType::get(M.getContext(), 32);
        VectorType *VT = FixedVectorType::get(IT, 3);
        createGlobalVariable(M, WorkgroupSize, VT,
                             AddressSpace::ModuleScopePrivate);
        return true;
      }
    }
  }

  return false;
}
