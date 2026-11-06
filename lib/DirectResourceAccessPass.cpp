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

#include <algorithm>
#include <climits>
#include <map>
#include <set>
#include <utility>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"

#include "clspv/Option.h"

#include "ArgKind.h"
#include "Builtins.h"
#include "CallGraphOrderedFunctions.h"
#include "Constants.h"
#include "DirectResourceAccessPass.h"
#include "Types.h"

using namespace llvm;

#define DEBUG_TYPE "directresourceaccess"

namespace {

cl::opt<bool> ShowDRA("show-dra", cl::init(false), cl::Hidden,
                      cl::desc("Show direct resource access details"));

Value *SelectPointerArrayElement(LoadInst *ld, Value *idx,
                                 ArrayRef<Value *> elems) {
  if (!idx)
    return elems[0];
  if (auto *cst = dyn_cast<ConstantInt>(idx))
    return elems[std::clamp<int64_t>(cst->getSExtValue(), 0, elems.size() - 1)];
  IRBuilder<> B(ld);
  Value *sel = elems[0];
  for (size_t k = 1; k < elems.size(); ++k) {
    Value *cmp = B.CreateICmpEQ(idx, ConstantInt::get(idx->getType(), k));
    sel = B.CreateSelect(cmp, elems[k], sel);
  }
  return sel;
}

// Replaces loads from |container| with the corresponding element from |elems|
// (using a SelectInst chain for dynamic indices) and erases dead loads/GEPs.
void ReplaceLoadsFromPointerArray(Value *container, ArrayRef<Value *> elems) {
  SmallVector<std::pair<Value *, Value *>, 8> worklist{{container, nullptr}};
  SmallVector<LoadInst *, 8> loads_to_erase;
  SmallVector<GetElementPtrInst *, 8> geps;

  while (!worklist.empty()) {
    auto [curr, curr_idx] = worklist.pop_back_val();
    for (User *usr : curr->users()) {
      if (auto *ld = dyn_cast<LoadInst>(usr)) {
        ld->replaceAllUsesWith(SelectPointerArrayElement(ld, curr_idx, elems));
        loads_to_erase.push_back(ld);
      } else if (auto *gep = dyn_cast<GetElementPtrInst>(usr)) {
        geps.push_back(gep);
        Value *next_idx = gep->hasAllZeroIndices()
                              ? curr_idx
                              : gep->getOperand(gep->getNumOperands() - 1);
        worklist.push_back({gep, next_idx});
      }
    }
  }

  for (LoadInst *ld : loads_to_erase)
    ld->eraseFromParent();
  for (auto *gep : llvm::reverse(geps)) {
    if (gep->use_empty())
      gep->eraseFromParent();
  }
}

void RecordPointerArrayStore(StoreInst *st, int64_t idx,
                             SmallVectorImpl<Value *> &elems) {
  if (idx < 0 || static_cast<size_t>(idx) >= elems.size())
    return;
  Value *val = st->getValueOperand();
  if (!isa<ConstantPointerNull>(val) && !isa<UndefValue>(val))
    elems[idx] = val;
}

// Populates |elems| with the pointer values stored into each slot of |alloca|.
void CollectPointerArrayElements(AllocaInst *alloca, ArrayType *arr_ty,
                                 const DataLayout &DL,
                                 SmallVectorImpl<Value *> &elems) {
  auto *elem_ptr_ty = cast<PointerType>(arr_ty->getElementType());
  int64_t ptr_size = DL.getTypeAllocSize(elem_ptr_ty);
  elems.assign(arr_ty->getNumElements(), ConstantPointerNull::get(elem_ptr_ty));

  for (User *usr : alloca->users()) {
    if (auto *st = dyn_cast<StoreInst>(usr)) {
      if (st->getPointerOperand() == alloca)
        RecordPointerArrayStore(st, 0, elems);
    } else if (auto *gep = dyn_cast<GetElementPtrInst>(usr)) {
      APInt offset(DL.getIndexSizeInBits(gep->getPointerAddressSpace()), 0);
      if (!gep->accumulateConstantOffset(DL, offset))
        continue;
      int64_t idx = offset.getSExtValue() / ptr_size;
      for (User *gep_usr : gep->users()) {
        if (auto *st = dyn_cast<StoreInst>(gep_usr)) {
          if (st->getPointerOperand() == gep)
            RecordPointerArrayStore(st, idx, elems);
        }
      }
    }
  }
}

// Erases |root| and its stores/GEPs/lifetime intrinsics if it does not escape.
void EraseDeadPointerArrayUsers(Value *root) {
  SmallVector<Value *, 8> worklist{root};
  SmallVector<Instruction *, 16> leaf_insts;
  SmallVector<Instruction *, 16> addr_insts;
  while (!worklist.empty()) {
    Value *v = worklist.pop_back_val();
    for (User *usr : v->users()) {
      if (auto *st = dyn_cast<StoreInst>(usr)) {
        if (st->getValueOperand() == v)
          return;
        leaf_insts.push_back(st);
      } else if (auto *ii = dyn_cast<IntrinsicInst>(usr)) {
        if (!ii->isLifetimeStartOrEnd())
          return;
        leaf_insts.push_back(ii);
      } else if (isa<GetElementPtrInst>(usr) || isa<BitCastInst>(usr)) {
        auto *inst = cast<Instruction>(usr);
        addr_insts.push_back(inst);
        worklist.push_back(inst);
      } else {
        return;
      }
    }
  }
  for (Instruction *inst : leaf_insts)
    inst->eraseFromParent();
  for (Instruction *inst : llvm::reverse(addr_insts)) {
    if (inst->use_empty())
      inst->eraseFromParent();
  }
  if (auto *alloca = dyn_cast<AllocaInst>(root); alloca && alloca->use_empty())
    alloca->eraseFromParent();
}

// Lowers local alloca arrays of resource pointers to direct resource accesses.
void RewritePointerArrayAccesses(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<AllocaInst *, 8> all_ptr_allocas;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *alloca = dyn_cast<AllocaInst>(&I);
        if (!alloca)
          continue;
        auto *arr_ty = dyn_cast<ArrayType>(alloca->getAllocatedType());
        if (!arr_ty || !arr_ty->getElementType()->isPointerTy() ||
            arr_ty->getNumElements() == 0)
          continue;

        SmallVector<Value *, 8> elems;
        CollectPointerArrayElements(alloca, arr_ty, DL, elems);
        ReplaceLoadsFromPointerArray(alloca, elems);
        all_ptr_allocas.push_back(alloca);
      }
    }
  }

  for (AllocaInst *alloca : all_ptr_allocas)
    EraseDeadPointerArrayUsers(alloca);
}

} // namespace

PreservedAnalyses
clspv::DirectResourceAccessPass::run(Module &M, ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  if (clspv::Option::DirectResourceAccess()) {
    auto ordered_functions = clspv::CallGraphOrderedFunctions(M);
    if (ShowDRA) {
      outs() << "DRA: Ordered functions:\n";
      for (Function *fun : ordered_functions) {
        outs() << "DRA:   " << fun->getName() << "\n";
      }
    }

    for (auto *fn : ordered_functions) {
      RewriteResourceAccesses(fn);
    }
    RewritePointerArrayAccesses(M);
  }

  return PA;
}

bool clspv::DirectResourceAccessPass::RewriteResourceAccesses(Function *fn) {
  bool Changed = false;
  int arg_index = 0;
  for (Argument &arg : fn->args()) {
    if (clspv::IsResourceType(arg.getType())) {
      if (auto PtrTy = dyn_cast<PointerType>(arg.getType())) {
        // Look for arguments that map to resources. They appear in the
        // following address spaces.
        switch (PtrTy->getPointerAddressSpace()) {
        case clspv::AddressSpace::Global:
        case clspv::AddressSpace::Constant:
        case clspv::AddressSpace::Local:
        case clspv::AddressSpace::UniformConstant:
          Changed |= RewriteAccessesForArg(fn, arg_index, arg);
          break;
        default:
          break;
        }
      } else {
        // Images and samplers.
        Changed |= RewriteAccessesForArg(fn, arg_index, arg);
      }
    }
    arg_index++;
  }
  return Changed;
}

// Rewrites, if possible, all the arg_index'th arg to all callers to 'fn',
// to replace passing the resource by pointer argument to directly accessing
// the underlying global variable for the resource.  This is only possible
// when all callers call 'fn' with the same underlying resource variable.
// Returns true if a change was made.
bool clspv::DirectResourceAccessPass::RewriteAccessesForArg(Function *fn,
                                                            int arg_index,
                                                            Argument &arg) {
  bool Changed = false;
  if (fn->use_empty()) {
    return false;
  }

  // We can convert a parameter to a direct resource access if it is
  // either a direct call to a clspv.resource.var.* or if it a GEP of
  // such a thing (where the GEP can only have zero indices).
  struct ParamInfo {
    // The base value. It is either a global variable or a resource-access
    // builtin function (clspv.resource.var.* or clspv.local.var.*).
    Value *base;
    // The descriptor set.
    uint32_t set;
    // The binding.
    uint32_t binding;
    // If base is a resource, then this is the resource type.
    // If base is a pointer-to-local, then this is the array type.
    // If base is a global value, then this is the value type (the type stored
    // in the global value).
    Type *pointee_type;
    // If the call parameter is a GEP, then this is the number of zero-indices
    // the GEP used.
    unsigned num_gep_zeroes;
    // A sample call using this function argument as the resource described
    // above.
    CallInst *sample_call;
  };

  // The common valid parameter info across all the callers seen so far.
  ParamInfo common = {};
  bool seen_one = false;

  // Tries to merge the given parameter info into |common|.  If it is the first
  // time we've tried, then save it.  Returns true if there is no conflict.
  auto merge_param_info = [&seen_one, &common](const ParamInfo &pi) {
    if (!seen_one) {
      common = pi;
      seen_one = true;
      return true;
    }
    return pi.base == common.base && pi.set == common.set &&
           pi.binding == common.binding &&
           pi.num_gep_zeroes == common.num_gep_zeroes;
  };

  for (auto &use : fn->uses()) {
    if (auto *caller = dyn_cast<CallInst>(use.getUser())) {
      Value *value = caller->getArgOperand(arg_index);
      // We care about two cases:
      //     - a direct call to clspv.resource.var.*
      //     - a GEP with only zero indices, where the base pointer is
      //       direct call to @clspv.resource.var.* or clspv.local.var.*,
      //       or is a global value for a workgroup variable.

      // Unpack GEPs with zeros, if we can.  Rewrite |value| as we go along.
      unsigned num_gep_zeroes = 0;
      bool first_gep = true;
      for (auto *gep = dyn_cast<GetElementPtrInst>(value); gep;
           gep = dyn_cast<GetElementPtrInst>(value)) {
        if (!gep->hasAllZeroIndices()) {
          return false;
        }
        // If not the first GEP, then ignore the "element" index (which I call
        // "slide") since that will be combined with the last index of the
        // previous GEP.
        num_gep_zeroes += gep->getNumIndices() + (first_gep ? 0 : -1);
        value = gep->getPointerOperand();
        first_gep = false;
      }
      if (auto *call = dyn_cast<CallInst>(value)) {
        // If the call is a call to a @clspv.resource.var.* function, then try
        // to merge it, assuming the given number of GEP zero-indices so far.
        auto *callee = call->getCalledFunction();
        auto &func_info = clspv::Builtins::Lookup(callee);
        if (func_info.getType() == clspv::Builtins::kClspvResource) {
          const auto set = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kResourceDescriptorSet))
                  ->getZExtValue());
          const auto binding = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kResourceBinding))
                  ->getZExtValue());
          auto *resource_type =
              call->getOperand(clspv::ClspvOperand::kResourceDataType)
                  ->getType();
          if (!merge_param_info(
                  {callee, set, binding, resource_type, num_gep_zeroes, call}))
            return false;
        } else if (func_info.getType() == clspv::Builtins::kClspvLocal) {
          const uint32_t spec_id = uint32_t(
              dyn_cast<ConstantInt>(
                  call->getOperand(clspv::ClspvOperand::kWorkgroupSpecId))
                  ->getZExtValue());
          auto *array_ty =
              call->getOperand(clspv::ClspvOperand::kWorkgroupDataType)
                  ->getType();
          if (!merge_param_info(
                  {callee, spec_id, 0, array_ty, num_gep_zeroes, call}))
            return false;
        } else {
          // A call but not to a resource access builtin function.
          return false;
        }
      } else if (auto *gv = dyn_cast<GlobalValue>(value)) {
        // This occurs when there a __local variable is declared inside a
        // function. (Are there other times?)
        if (!merge_param_info(
                {value, 0, 0, gv->getValueType(), num_gep_zeroes, nullptr}))
          return false;
      } else {
        // Not a call.
        return false;
      }
    } else {
      // There isn't enough commonality.  Bail out without changing anything.
      return false;
    }
  }
  if (ShowDRA) {
    if (seen_one) {
      outs() << "DRA:  Rewrite " << fn->getName() << " arg " << arg_index << " "
             << arg.getName() << ": " << common.base->getName() << " ("
             << common.set << "," << common.binding
             << ") zeroes: " << common.num_gep_zeroes << " sample-call ";
      if (common.sample_call)
        outs() << *common.sample_call << "\n";
      else
        outs() << "nullptr\n";
    }
  }

  // Now rewrite the argument, using the info in |common|.

  Changed = true;
  IRBuilder<> Builder(fn->getParent()->getContext());
  auto *zero = Builder.getInt32(0);
  Builder.SetInsertPoint(fn->getEntryBlock().getFirstNonPHIIt());

  Value *replacement = common.base;
  if (Function *function = dyn_cast<Function>(replacement)) {
    // Create the call.
    SmallVector<Value *, 8> args(common.sample_call->arg_begin(),
                                 common.sample_call->arg_end());
    replacement = Builder.CreateCall(function, args);
    if (ShowDRA) {
      outs() << "DRA:    Replace: call " << *replacement << "\n";
    }
  }
  if (common.num_gep_zeroes) {
    SmallVector<Value *, 3> zeroes;
    for (unsigned i = 0; i < common.num_gep_zeroes; i++) {
      zeroes.push_back(zero);
    }
    // Builder.CreateGEP is not used to avoid creating a GEPConstantExpr in the
    // case of global variables.
    replacement =
        GetElementPtrInst::Create(common.pointee_type, replacement, zeroes);
    Builder.Insert(cast<Instruction>(replacement));
    if (ShowDRA) {
      outs() << "DRA:    Replace: gep  " << *replacement << "\n";
    }
  }
  arg.replaceAllUsesWith(replacement);

  return Changed;
}
