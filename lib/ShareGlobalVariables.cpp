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

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"

using namespace llvm;

namespace {

cl::opt<bool> ShowSGV("show-sgv", cl::init(false), cl::Hidden,
                      cl::desc("Show share global variables details"));

class ShareGlobalVariablesPass final : public ModulePass {
public:
  typedef DenseMap<Function *, SmallVector<Function *, 4>> EntryPointMap;

  static char ID;
  ShareGlobalVariablesPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Maps functions to entry points that can call them including themselves.
  void MapEntryPoints(Module &M);

  // Traces the callable functions from |function| and maps them to
  // |entry_point|.
  void TraceFunction(Function *function, Function *entry_point);

  // Attempts to share global variables. Returns true if any variables are
  // shared.  Shares variables of the same type that are used by
  // non-intersecting sets of kernels.
  bool ShareGlobals(Module &M);

  // Collects the entry points that can reach |value| into |user_entry_points|.
  void CollectUserEntryPoints(Value *value,
                              UniqueVector<Function *> *user_entry_points);

  // Returns true if there is an intersection between the |user_functions| and
  // |other_entry_points|.
  bool HasSharedEntryPoints(const DenseSet<Function *> &user_functions,
                            const UniqueVector<Function *> &other_entry_points);

  EntryPointMap function_to_entry_points_;
};

char ShareGlobalVariablesPass::ID = 0;
static RegisterPass<ShareGlobalVariablesPass> X("ShareGlobalVariablesPass",
                                                "Share global variables");

} // namespace

namespace clspv {
ModulePass *createShareGlobalVariablesPass() {
  return new ShareGlobalVariablesPass();
}
} // namespace clspv

namespace {

bool ShareGlobalVariablesPass::runOnModule(Module &M) {
  bool Changed = false;

  if (clspv::Option::ShareGlobalVariables()) {
    MapEntryPoints(M);
    Changed = ShareGlobals(M);
  }

  return Changed;
}

void ShareGlobalVariablesPass::MapEntryPoints(Module &M) {
  // TODO: this could be more efficient if it memoized results for non-kernel
  // functions.
  for (auto &func : M) {
    if (func.isDeclaration() ||
        func.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    TraceFunction(&func, &func);
  }
}

void ShareGlobalVariablesPass::TraceFunction(Function *function,
                                             Function *entry_point) {
  function_to_entry_points_[function].push_back(entry_point);

  for (auto &BB : *function) {
    for (auto &I : BB) {
      if (auto call = dyn_cast<CallInst>(&I)) {
        Function *callee = call->getCalledFunction();
        if (!callee->isDeclaration())
          TraceFunction(callee, entry_point);
      }
    }
  }
}

bool ShareGlobalVariablesPass::ShareGlobals(Module &M) {
  // Greedily attempts to share global variables.
  // TODO: this should be analysis driven to aid direct resource access more
  // directly.
  bool Changed = false;
  DenseMap<Value *, UniqueVector<Function *>> global_entry_points;
  for (auto &G : M.globals()) {
    auto &entry_points = global_entry_points[&G];
    CollectUserEntryPoints(&G, &entry_points);
  }

  for (auto global = M.global_begin(); global != M.global_end(); ++global) {
    if (global->getType()->getPointerAddressSpace() !=
        clspv::AddressSpace::Local)
      continue;

    if (global->user_empty())
      continue;

    auto &entry_points = global_entry_points[&*global];
    DenseSet<Function *> user_functions;
    for (auto entry_point : entry_points) {
      user_functions.insert(entry_point);
    }

    auto next = global;
    ++next;
    for (; next != M.global_end(); ++next) {
      if (global->getType() != next->getType())
        continue;
      if (next->user_empty())
        continue;

      auto &other_entry_points = global_entry_points[&*next];
      if (!HasSharedEntryPoints(user_functions, other_entry_points)) {
        if (ShowSGV) {
          outs() << "SGV: Combining globals\n"
                 << "  " << *global << "\n"
                 << "  " << *next << "\n";
        }
        next->replaceAllUsesWith(&*global);
        // Don't need to update |entry_points| because we won't revisit this
        // global variable after the outer loop iteration.
        for (auto fn : other_entry_points) {
          user_functions.insert(fn);
        }
        Changed = true;
      }
    }
  }

  return Changed;
}

void ShareGlobalVariablesPass::CollectUserEntryPoints(
    Value *value, UniqueVector<Function *> *user_entry_points) {
  if (auto I = dyn_cast<Instruction>(value)) {
    Function *function = I->getParent()->getParent();
    auto &entry_points = function_to_entry_points_[function];
    for (auto fn : entry_points) {
      user_entry_points->insert(fn);
    }

    return;
  }

  for (auto user : value->users()) {
    CollectUserEntryPoints(user, user_entry_points);
  }
}

bool ShareGlobalVariablesPass::HasSharedEntryPoints(
    const DenseSet<Function *> &user_functions,
    const UniqueVector<Function *> &other_entry_points) {
  for (auto fn : other_entry_points) {
    if (user_functions.count(fn))
      return true;
  }

  return false;
}
} // namespace
