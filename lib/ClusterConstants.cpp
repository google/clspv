// Copyright 2018 The Clspv Authors. All rights reserved.
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

// Cluster module-scope __constant variables.  But only if option
// ModuleScopeConstantsInUniformBuffer is true.

#include <cassert>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

#include "ArgKind.h"
#include "Passes.h"

using namespace llvm;

#define DEBUG_TYPE "clusterconstants"

namespace {
struct ClusterModuleScopeConstantVars : public ModulePass {
  static char ID;
  ClusterModuleScopeConstantVars() : ModulePass(ID) {}

  bool runOnModule(Module &M) override;
};

} // namespace

char ClusterModuleScopeConstantVars::ID = 0;
INITIALIZE_PASS(ClusterModuleScopeConstantVars,
                "ClusterModuleScopeConstantVars",
                "Cluster module-scope __constant variables", false, false)

namespace clspv {
llvm::ModulePass *createClusterModuleScopeConstantVars() {
  return new ClusterModuleScopeConstantVars();
}
} // namespace clspv

bool ClusterModuleScopeConstantVars::runOnModule(Module &M) {
  bool Changed = false;
  LLVMContext &Context = M.getContext();

  SmallVector<GlobalVariable *, 8> global_constants;
  UniqueVector<Constant *> initializers;
  SmallVector<GlobalVariable *, 8> dead_global_constants;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.hasInitializer() && GV.getType()->getPointerAddressSpace() ==
                                   clspv::AddressSpace::Constant) {
      // Only keep live __constant variables.
      if (GV.use_empty()) {
        dead_global_constants.push_back(&GV);
      } else {
        global_constants.push_back(&GV);
        initializers.insert(GV.getInitializer());
      }
    }
  }

  for (GlobalVariable *GV : dead_global_constants) {
    Changed = true;
    GV->eraseFromParent();
  }

  if (global_constants.size() > 1 ||
      (global_constants.size() == 1 &&
       !global_constants[0]->getType()->isStructTy())) {

    Changed = true;

    // Make the struct type.
    SmallVector<Type *, 8> types;
    types.reserve(initializers.size());
    for (Value *init : initializers) {
      Type *ty = init->getType();
      types.push_back(ty);
    }
    StructType *type = StructType::get(Context, types);

    // Make the global variable.
    SmallVector<Constant *, 8> initializers_as_vec(initializers.begin(),
                                                   initializers.end());
    Constant *clustered_initializer =
        ConstantStruct::get(type, initializers_as_vec);
    GlobalVariable *clustered_gv = new GlobalVariable(
        M, type, true, GlobalValue::InternalLinkage, clustered_initializer,
        "clspv.clustered_constants", nullptr,
        GlobalValue::ThreadLocalMode::NotThreadLocal,
        clspv::AddressSpace::Constant);
    assert(clustered_gv);

    // Replace uses of the other globals with references to the members of the
    // clustered constant.
    IRBuilder<> Builder(Context);
    Value *zero = Builder.getInt32(0);
    for (GlobalVariable *GV : global_constants) {
      SmallVector<User *, 8> users(GV->users());
      for (User *user : users) {
        if (GV == user) {
          // This is the original global variable declaration.  Skip it.
        } else if (auto *inst = dyn_cast<Instruction>(user)) {
          unsigned index = initializers.idFor(GV->getInitializer()) - 1;
          Instruction *gep = GetElementPtrInst::CreateInBounds(
              clustered_gv, {zero, Builder.getInt32(index)}, "", inst);
          user->replaceUsesOfWith(GV, gep);
        } else {
          errs() << "Don't know how to handle updating user of __constant: "
                 << *user << "\n";
          llvm_unreachable("Unhandled case replacing a user of __constant");
        }
      }
    }

    // Remove the old constants.
    for (GlobalVariable *GV : global_constants) {
      GV->eraseFromParent();
    }
  }

  return Changed;
}
