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

#include "ArgKind.h"
#include "Passes.h"
#include "clspv/AddressSpace.h"
#include "clspv/Option.h"

using namespace llvm;

namespace {

cl::opt<bool> ShowSMSV("show-smsv", cl::init(false), cl::Hidden,
                       cl::desc("Show share module scope variables details"));

class ShareModuleScopeVariablesPass final : public ModulePass {
public:
  typedef DenseMap<Function *, UniqueVector<Function *>> EntryPointMap;

  static char ID;
  ShareModuleScopeVariablesPass() : ModulePass(ID) {}
  bool runOnModule(Module &M) override;

private:
  // Maps functions to entry points that can call them including themselves.
  void MapEntryPoints(Module &M);

  // Traces the callable functions from |function| and maps them to
  // |entry_point|.
  void TraceFunction(Function *function, Function *entry_point);

  // Attempts to share module scope variables. Returns true if any variables are
  // shared.  Shares variables of the same type that are used by
  // non-intersecting sets of kernels.
  bool ShareModuleScopeVariables(Module &M);

  // Collects the entry points that can reach |value| into |user_entry_points|.
  void CollectUserEntryPoints(Value *value,
                              UniqueVector<Function *> *user_entry_points);

  // Returns true if there is an intersection between the |user_functions| and
  // |other_entry_points|.
  bool HasSharedEntryPoints(const DenseSet<Function *> &user_functions,
                            const UniqueVector<Function *> &other_entry_points);

  EntryPointMap function_to_entry_points_;
};

} // namespace

char ShareModuleScopeVariablesPass::ID = 0;
INITIALIZE_PASS(ShareModuleScopeVariablesPass, "ShareModuleScopeVariablesPass",
                "Share module scope variables", false, false)

namespace clspv {
ModulePass *createShareModuleScopeVariablesPass() {
  return new ShareModuleScopeVariablesPass();
}
} // namespace clspv

namespace {

bool ShareModuleScopeVariablesPass::runOnModule(Module &M) {
  bool Changed = false;

  if (clspv::Option::ShareModuleScopeVariables()) {
    MapEntryPoints(M);
    Changed = ShareModuleScopeVariables(M);
  }

  return Changed;
}

void ShareModuleScopeVariablesPass::MapEntryPoints(Module &M) {
  // TODO: this could be more efficient if it memoized results for non-kernel
  // functions.
  for (auto &func : M) {
    if (func.isDeclaration() ||
        func.getCallingConv() != CallingConv::SPIR_KERNEL)
      continue;

    TraceFunction(&func, &func);
  }
}

void ShareModuleScopeVariablesPass::TraceFunction(Function *function,
                                                  Function *entry_point) {
  function_to_entry_points_[function].insert(entry_point);

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

bool ShareModuleScopeVariablesPass::ShareModuleScopeVariables(Module &M) {
  // Greedily attempts to share global variables.
  // TODO: this should be analysis driven to aid direct resource access more
  // directly.
  bool Changed = false;
  DenseMap<Value *, UniqueVector<Function *>> global_entry_points;
  for (auto &G : M.globals()) {
    if (!clspv::IsLocalPtr(G.getType()))
      continue;

    auto &entry_points = global_entry_points[&G];
    CollectUserEntryPoints(&G, &entry_points);
  }

  SmallVector<GlobalVariable *, 8> dead_globals;
  for (auto global = M.global_begin(); global != M.global_end(); ++global) {
    if (!clspv::IsLocalPtr(global->getType()))
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
        if (ShowSMSV) {
          outs() << "SMSV: Combining module scope variables\n"
                 << "  " << *global << "\n"
                 << "  " << *next << "\n";
        }
        next->replaceAllUsesWith(&*global);
        // Don't need to update |entry_points| because we won't revisit this
        // global variable after the outer loop iteration.
        for (auto fn : other_entry_points) {
          user_functions.insert(fn);
        }
        dead_globals.push_back(&*next);
        Changed = true;
      }
    }
  }

  // Remove the unused variables that were merged.
  for (auto GV : dead_globals) {
    GV->eraseFromParent();
  }

  return Changed;
}

void ShareModuleScopeVariablesPass::CollectUserEntryPoints(
    Value *value, UniqueVector<Function *> *user_entry_points) {
  if (auto I = dyn_cast<Instruction>(value)) {
    Function *function = I->getParent()->getParent();
    auto &entry_points = function_to_entry_points_[function];
    for (auto fn : entry_points) {
      user_entry_points->insert(fn);
    }

    // We're looking for the first use inside a function to identify the entry
    // points. Mutations beyond that point do not prevent sharing so we do not
    // consider them.
    return;
  }

  for (auto user : value->users()) {
    CollectUserEntryPoints(user, user_entry_points);
  }
}

bool ShareModuleScopeVariablesPass::HasSharedEntryPoints(
    const DenseSet<Function *> &user_functions,
    const UniqueVector<Function *> &other_entry_points) {
  for (auto fn : other_entry_points) {
    if (user_functions.count(fn))
      return true;
  }

  return false;
}
} // namespace
