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
#include "Passes.h"
#include "PushConstant.h"

using namespace llvm;
using namespace clspv;

#define DEBUG_TYPE "defineopenclworkitembuiltins"

namespace {
struct DefineOpenCLWorkItemBuiltinsPass final : public ModulePass {
  static char ID;
  DefineOpenCLWorkItemBuiltinsPass() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;

  GlobalVariable *createGlobalVariable(Module &M, StringRef GlobalVarName,
                                       Type *Ty, AddressSpace::Type AddrSpace);

  bool defineMappedBuiltin(Module &M, StringRef FuncName,
                           StringRef GlobalVarName, unsigned DefaultValue,
                           AddressSpace::Type AddrSpace = AddressSpace::Input);

  bool defineGlobalIDBuiltin(Module &M);
  bool defineNumGroupsBuiltin(Module &M);
  bool defineGroupIDBuiltin(Module &M);
  bool defineGlobalSizeBuiltin(Module &M);
  bool defineGlobalOffsetBuiltin(Module &M);
  bool defineWorkDimBuiltin(Module &M);
  bool defineEnqueuedLocalSizeBuiltin(Module &M);

  bool addWorkgroupSizeIfRequired(Module &M);
};
} // namespace

char DefineOpenCLWorkItemBuiltinsPass::ID = 0;
INITIALIZE_PASS(DefineOpenCLWorkItemBuiltinsPass,
                "DefineOpenCLWorkItemBuiltins",
                "Define OpenCL Work-Item Builtins Pass", false, false)

namespace clspv {
ModulePass *createDefineOpenCLWorkItemBuiltinsPass() {
  return new DefineOpenCLWorkItemBuiltinsPass();
}
} // namespace clspv

bool DefineOpenCLWorkItemBuiltinsPass::runOnModule(Module &M) {
  bool changed = false;

  changed |= defineGlobalOffsetBuiltin(M);
  changed |= defineGlobalIDBuiltin(M);

  changed |=
      defineMappedBuiltin(M, "_Z14get_local_sizej", "__spirv_WorkgroupSize", 1,
                          AddressSpace::ModuleScopePrivate);
  changed |= defineMappedBuiltin(M, "_Z12get_local_idj",
                                 "__spirv_LocalInvocationId", 0);
  changed |= defineNumGroupsBuiltin(M);
  changed |= defineGroupIDBuiltin(M);
  changed |= defineGlobalSizeBuiltin(M);
  changed |= defineWorkDimBuiltin(M);
  changed |= defineEnqueuedLocalSizeBuiltin(M);
  changed |= addWorkgroupSizeIfRequired(M);

  return changed;
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

namespace {
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
} // namespace

bool DefineOpenCLWorkItemBuiltinsPass::defineMappedBuiltin(
    Module &M, StringRef FuncName, StringRef GlobalVarName,
    unsigned DefaultValue, AddressSpace::Type AddrSpace) {
  Function *F = M.getFunction(FuncName);

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  VectorType *VT = VectorType::get(IT, 3);

  GlobalVariable *GV = createGlobalVariable(M, GlobalVarName, VT, AddrSpace);

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);

  Value *Result = nullptr;
  if (GlobalVarName == "__spirv_WorkgroupSize") {
    // Ugly hack to work around implementation bugs.
    // Load the whole vector and extract the result
    Value *LoadVec = Builder.CreateLoad(GV);
    Result = Builder.CreateExtractElement(LoadVec, InBoundsDim);
  } else {
    Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
    Value *GEP = Builder.CreateGEP(GV, Indices);
    Result = Builder.CreateLoad(GEP);
  }

  Value *Select2 =
      inBoundsDimensionOrDefaultValue(Builder, Dim, Result, DefaultValue);
  Builder.CreateRet(Select2);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalIDBuiltin(Module &M) {

  Function *F = M.getFunction("_Z13get_global_idj");

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  VectorType *VT = VectorType::get(IT, 3);

  GlobalVariable *GV = createGlobalVariable(M, "__spirv_GlobalInvocationId", VT,
                                            AddressSpace::Input);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);

  Value *Result = nullptr;
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
  Value *GEP = Builder.CreateGEP(GV, Indices);
  Result = Builder.CreateLoad(GEP);

  auto GidBase = inBoundsDimensionOrDefaultValue(Builder, Dim, Result, 0);

  Value *Ret = GidBase;
  if (clspv::Option::NonUniformNDRangeSupported()) {
    auto Ptr = GetPushConstantPointer(BB, clspv::PushConstant::RegionOffset);
    auto DimPtr = Builder.CreateInBoundsGEP(Ptr, Indices);
    auto Size = Builder.CreateLoad(DimPtr);
    auto RegOff = inBoundsDimensionOrDefaultValue(Builder, Dim, Size, 0);
    Ret = Builder.CreateAdd(Ret, RegOff);
  } else {
    // If we have a global offset we need to add it
    if (clspv::Option::GlobalOffset() ||
        clspv::Option::GlobalOffsetPushConstant()) {
      auto Goff =
          Builder.CreateCall(M.getFunction("_Z17get_global_offsetj"), Dim);
      Goff->setCallingConv(CallingConv::SPIR_FUNC);
      Ret = Builder.CreateAdd(Ret, Goff);
    }
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalSizeBuiltin(Module &M) {
  Function *F = M.getFunction("_Z15get_global_sizej");

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
    auto DimPtr = Builder.CreateInBoundsGEP(Ptr, Indices);
    GlobalSize = Builder.CreateLoad(DimPtr);
  } else {
    IntegerType *IT = IntegerType::get(M.getContext(), 32);
    VectorType *VT = VectorType::get(IT, 3);

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
    Value *LoadWGS = Builder.CreateLoad(Builder.CreateGEP(WGS, Indices));

    // And the number of workgroups.
    Value *LoadNWG = Builder.CreateLoad(Builder.CreateGEP(NWG, Indices));

    // We multiply the workgroup size by the number of workgroups to calculate
    // the global size.
    GlobalSize = Builder.CreateMul(LoadWGS, LoadNWG);
  }

  GlobalSize = inBoundsDimensionOrDefaultValue(Builder, Dim, GlobalSize, 1);
  Builder.CreateRet(GlobalSize);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineNumGroupsBuiltin(Module &M) {

  Function *F = M.getFunction("_Z14get_num_groupsj");

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  Value *NumGroupsVarPtr;
  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};

  if (clspv::Option::NonUniformNDRangeSupported()) {
    NumGroupsVarPtr =
        GetPushConstantPointer(BB, clspv::PushConstant::NumWorkgroups);
  } else {
    IntegerType *IT = IntegerType::get(M.getContext(), 32);
    VectorType *VT = VectorType::get(IT, 3);
    NumGroupsVarPtr = createGlobalVariable(M, "__spirv_NumWorkgroups", VT,
                                           AddressSpace::Input);
  }

  auto NumGroupsPtr = Builder.CreateInBoundsGEP(NumGroupsVarPtr, Indices);
  auto NumGroups = Builder.CreateLoad(NumGroupsPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, NumGroups, 1);
  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGroupIDBuiltin(Module &M) {

  Function *F = M.getFunction("_Z12get_group_idj");

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
  VectorType *VT = VectorType::get(IT, 3);
  auto RegionGroupIDVarPtr =
      createGlobalVariable(M, "__spirv_WorkgroupId", VT, AddressSpace::Input);

  auto RegionGroupIDPtr =
      Builder.CreateInBoundsGEP(RegionGroupIDVarPtr, Indices);
  auto RegionGroupID = Builder.CreateLoad(RegionGroupIDPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, RegionGroupID, 0);

  if (clspv::Option::NonUniformNDRangeSupported()) {
    auto RegionGroupOffsetVarPtr =
        GetPushConstantPointer(BB, clspv::PushConstant::RegionGroupOffset);
    auto RegionGroupOffsetPtr =
        Builder.CreateInBoundsGEP(RegionGroupOffsetVarPtr, Indices);
    auto RegionGroupOffsetVal = Builder.CreateLoad(RegionGroupOffsetPtr);
    auto RegionGroupOffset =
        inBoundsDimensionOrDefaultValue(Builder, Dim, RegionGroupOffsetVal, 0);

    Ret = Builder.CreateAdd(Ret, RegionGroupOffset);
  }

  Builder.CreateRet(Ret);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalOffsetBuiltin(Module &M) {
  Function *F = M.getFunction("_Z17get_global_offsetj");
  bool isSupportEnabled = clspv::Option::GlobalOffset() ||
                          clspv::Option::GlobalOffsetPushConstant();
  bool isUsedDirectly = F != nullptr;
  bool isUsedIndirectly =
      isSupportEnabled && M.getFunction("_Z13get_global_idj") != nullptr;
  bool isUsed = isUsedDirectly || isUsedIndirectly;

  // Only define get_global_offset when it is used or the option is enabled
  // and get_global_id is used (since it is used in global ID calculations).
  if (!isUsed) {
    return false;
  }

  // If get_global_offset isn't used but get_global_id is then we need to
  // declare it ourselves.
  auto &C = M.getContext();
  auto Int32Ty = IntegerType::get(C, 32);
  if (isUsedIndirectly && !isUsedDirectly) {
    auto FType = FunctionType::get(Int32Ty, Int32Ty, false);
    F = cast<Function>(
        M.getOrInsertFunction("_Z17get_global_offsetj", FType).getCallee());
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  if (isSupportEnabled) {
    auto Dim = &*F->arg_begin();
    auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
    Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
    Value *gep = nullptr;
    const bool uses_push_constant =
        clspv::ShouldDeclareGlobalOffsetPushConstant(M);
    if (uses_push_constant) {
      auto GoffPtr =
          GetPushConstantPointer(BB, clspv::PushConstant::GlobalOffset);
      gep = Builder.CreateInBoundsGEP(GoffPtr, Indices);
    } else {
      auto VecTy = VectorType::get(Int32Ty, 3);
      StringRef name = "__spirv_GlobalOffset";
      auto offset_var = createGlobalVariable(M, name, VecTy,
                                             AddressSpace::ModuleScopePrivate);
      gep = Builder.CreateInBoundsGEP(offset_var, Indices);
    }
    auto load = Builder.CreateLoad(gep);
    auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, load, 0);
    Builder.CreateRet(Ret);
  } else {
    // Get global offset is easy for us as it only returns 0.
    Builder.CreateRet(Builder.getInt32(0));
  }

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineWorkDimBuiltin(Module &M) {
  Function *F = M.getFunction("_Z12get_work_dimv");

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
    auto load = Builder.CreateLoad(work_dim_var);
    Builder.CreateRet(load);
  } else {
    // Get work dim is easy for us as it only returns 3.
    Builder.CreateRet(Builder.getInt32(3));
  }

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineEnqueuedLocalSizeBuiltin(
    Module &M) {

  Function *F = M.getFunction("_Z23get_enqueued_local_sizej");

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  auto Dim = &*F->arg_begin();
  auto InBoundsDim = inBoundsDimensionIndex(Builder, Dim);
  Value *Indices[] = {Builder.getInt32(0), InBoundsDim};
  auto Ptr = GetPushConstantPointer(BB, clspv::PushConstant::EnqueuedLocalSize);
  auto DimPtr = Builder.CreateInBoundsGEP(Ptr, Indices);
  auto Size = Builder.CreateLoad(DimPtr);
  auto Ret = inBoundsDimensionOrDefaultValue(Builder, Dim, Size, 1);
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
        VectorType *VT = VectorType::get(IT, 3);
        createGlobalVariable(M, WorkgroupSize, VT,
                             AddressSpace::ModuleScopePrivate);
        return true;
      }
    }
  }

  return false;
}
