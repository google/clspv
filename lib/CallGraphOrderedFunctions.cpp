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

#include <set>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"

#include "CallGraphOrderedFunctions.h"

using namespace llvm;

namespace clspv {

UniqueVector<Function *> CallGraphOrderedFunctions(Module &M) {
  // Use a topological sort.

  // Make an ordered list of all functions having bodies, with kernel entry
  // points listed first.
  UniqueVector<Function *> functions;
  SmallVector<Function *, 10> entry_points;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      functions.insert(&F);
      entry_points.push_back(&F);
    }
  }
  // Add the remaining functions.
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      functions.insert(&F);
    }
  }

  // This will be a complete set of reveresed edges, i.e. with all pairs
  // of (callee, caller).
  using Edge = std::pair<unsigned, unsigned>;
  auto make_edge = [&functions](Function *callee, Function *caller) {
    return std::pair<unsigned, unsigned>{functions.idFor(callee),
                                         functions.idFor(caller)};
  };
  std::set<Edge> reverse_edges;
  // Map each function to the functions it calls, and populate |reverse_edges|.
  std::map<Function *, SmallVector<Function *, 3>> calls_functions;
  for (Function *callee : functions) {
    for (auto &use : callee->uses()) {
      if (auto *call = dyn_cast<CallInst>(use.getUser())) {
        Function *caller = call->getParent()->getParent();
        calls_functions[caller].push_back(callee);
        reverse_edges.insert(make_edge(callee, caller));
      }
    }
  }
  // Sort the callees in module-order.  This helps us produce a deterministic
  // result.
  for (auto &pair : calls_functions) {
    auto &callees = pair.second;
    std::sort(callees.begin(), callees.end(),
              [&functions](Function *lhs, Function *rhs) {
                return functions.idFor(lhs) < functions.idFor(rhs);
              });
  }

  // Use Kahn's algorithm for topoological sort.
  UniqueVector<Function *> result;
  SmallVector<Function *, 10> work_list(entry_points.begin(),
                                        entry_points.end());
  while (!work_list.empty()) {
    Function *caller = work_list.back();
    work_list.pop_back();
    result.insert(caller);
    auto &callees = calls_functions[caller];
    for (auto *callee : callees) {
      reverse_edges.erase(make_edge(callee, caller));
      auto lower_bound = reverse_edges.lower_bound(make_edge(callee, nullptr));
      if (lower_bound == reverse_edges.end() ||
          lower_bound->first != functions.idFor(callee)) {
        // Callee has no other unvisited callers.
        work_list.push_back(callee);
      }
    }
  }
  // If reverse_edges is not empty then there was a cycle.  But we don't care
  // about that erroneous case.

  return result;
}

} // namespace clspv
