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

#include <llvm/IR/Constants.h>
#include <llvm/IR/IRBuilder.h>
#include <llvm/IR/Instructions.h>
#include <llvm/IR/Module.h>
#include <llvm/Pass.h>

#include <clspv/AddressSpace.h>

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

  bool defineMappedBuiltin(Module &M, StringRef FuncName, StringRef GlobalVarName, unsigned DefaultValue, AddressSpace::Type AddrSpace = AddressSpace::Input);

  bool defineGlobalSizeBuiltin(Module &M);

  bool defineGlobalOffsetBuiltin(Module &M);

  bool defineWorkDimBuiltin(Module &M);

  bool addWorkgroupSizeIfRequired(Module &M);
};
}

char DefineOpenCLWorkItemBuiltinsPass::ID = 0;
static RegisterPass<DefineOpenCLWorkItemBuiltinsPass>
    X("DefineOpenCLWorkItemBuiltins", "Define OpenCL Work-Item Builtins Pass");

namespace clspv {
ModulePass *createDefineOpenCLWorkItemBuiltinsPass() {
  return new DefineOpenCLWorkItemBuiltinsPass();
}
}

bool DefineOpenCLWorkItemBuiltinsPass::runOnModule(Module &M) {
  bool changed = false;

  changed |= defineMappedBuiltin(M, "_Z13get_global_idj", "__spirv_GlobalInvocationId", 0);
  changed |= defineMappedBuiltin(M, "_Z14get_local_sizej", "__spirv_WorkgroupSize", 1, AddressSpace::ModuleScopePrivate);
  changed |= defineMappedBuiltin(M, "_Z12get_local_idj", "__spirv_LocalInvocationId", 0);
  changed |= defineMappedBuiltin(M, "_Z14get_num_groupsj", "__spirv_NumWorkgroups", 1);
  changed |= defineMappedBuiltin(M, "_Z12get_group_idj", "__spirv_WorkgroupId", 0);
  changed |= defineGlobalSizeBuiltin(M);
  changed |= defineGlobalOffsetBuiltin(M);
  changed |= defineWorkDimBuiltin(M);
  changed |= addWorkgroupSizeIfRequired(M);

  return changed;
}

GlobalVariable *DefineOpenCLWorkItemBuiltinsPass::createGlobalVariable(
    Module &M, StringRef GlobalVarName, Type *Ty,
    AddressSpace::Type AddrSpace) {
  auto GV = new GlobalVariable(
      M, Ty, false, GlobalValue::CommonLinkage, nullptr, GlobalVarName, nullptr,
      GlobalValue::ThreadLocalMode::NotThreadLocal, AddrSpace);

  GV->setInitializer(Constant::getNullValue(Ty));

  return GV;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineMappedBuiltin(Module &M, StringRef FuncName, StringRef GlobalVarName, unsigned DefaultValue, AddressSpace::Type AddrSpace) {
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

  // Vulkan has 3 dimensions for work-items, but the OpenCL API is written
  // such that it could have more. We have to check whether the value provided
  // was less than 3...
  Value *Cond = Builder.CreateICmp(CmpInst::ICMP_ULT, &*F->arg_begin(),
                                   Builder.getInt32(3));
  // .. then (for our index into GV) make sure we don't go beyond the bounds
  // of GV.
  Value *Select1 =
      Builder.CreateSelect(Cond, &*F->arg_begin(), Builder.getInt32(0));

  Value* Result = nullptr;
  if (GlobalVarName == "__spirv_WorkgroupSize") {
    // Ugly hack to work around implementation bugs.
    // Load the whole vector and extract the result
    Value *LoadVec = Builder.CreateLoad(GV);
    Result = Builder.CreateExtractElement(LoadVec, Select1);
  } else {
    Value *Indices[] = {Builder.getInt32(0), Select1};
    Value *GEP = Builder.CreateGEP(GV, Indices);
    Result = Builder.CreateLoad(GEP);
  }

  // We also need to select on the result of the load, because if Cond is
  // false, we need to return the default value to the user.
  Value *Select2 =
      Builder.CreateSelect(Cond, Result, Builder.getInt32(DefaultValue));
  Builder.CreateRet(Select2);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalSizeBuiltin(Module &M) {
  Function *F = M.getFunction("_Z15get_global_sizej");

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  IntegerType *IT = IntegerType::get(M.getContext(), 32);
  VectorType *VT = VectorType::get(IT, 3);

  // Global size uses two builtin variables that might already have been created.
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

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  // Vulkan has 3 dimensions for work-items, but the OpenCL API is written
  // such that it could have more. We have to check whether the value provided
  // was less than 3...
  Value *Cond = Builder.CreateICmp(CmpInst::ICMP_ULT, &*F->arg_begin(),
                                   Builder.getInt32(3));
  // ... then (for our index into GV) make sure we don't go beyond the bounds
  // of GV.
  Value *Select1 =
      Builder.CreateSelect(Cond, &*F->arg_begin(), Builder.getInt32(0));

  Value *Indices[] = {Builder.getInt32(0), Select1};

  // Load the workgroup size.
  Value *LoadWGS = Builder.CreateLoad(Builder.CreateGEP(WGS, Indices));

  // And the number of workgroups.
  Value *LoadNWG = Builder.CreateLoad(Builder.CreateGEP(NWG, Indices));

  // We multiply the workgroup size by the number of workgroups to calculate the global size.
  Value *Mul = Builder.CreateMul(LoadWGS, LoadNWG);

  // We also need to select on the result of the load, because if Cond is
  // false, we need to return the default value (1) to the user.
  Value *Select2 = Builder.CreateSelect(Cond, Mul, Builder.getInt32(1));
  Builder.CreateRet(Select2);

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::defineGlobalOffsetBuiltin(Module &M) {
  Function *F = M.getFunction("_Z17get_global_offsetj");

  // If the builtin was not used in the module, don't create it!
  if (nullptr == F) {
    return false;
  }

  BasicBlock *BB = BasicBlock::Create(M.getContext(), "body", F);
  IRBuilder<> Builder(BB);

  // Get global offset is easy for us as it only returns 0.
  Builder.CreateRet(Builder.getInt32(0));

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

  // Get global offset is easy for us as it only returns 3.
  Builder.CreateRet(Builder.getInt32(3));

  return true;
}

bool DefineOpenCLWorkItemBuiltinsPass::addWorkgroupSizeIfRequired(Module &M) {
  StringRef WorkgroupSize = "__spirv_WorkgroupSize";

  // If the module already has workgroup size.
  if (nullptr == M.getGlobalVariable(WorkgroupSize)) {
    for (auto &F : M) {
      if (F.getCallingConv() != llvm::CallingConv::SPIR_KERNEL) {
        continue;
      }

      // If this kernel does not have the reqd_work_group_size metadata, we need
      // to output the workgroup size variable.
      if (nullptr == F.getMetadata("reqd_work_group_size")) {
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
