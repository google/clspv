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

// We can convert a parameter to a direct resource access if it is
// either a direct call to a clspv.resource.var.* or if it a GEP of
// such a thing (where the GEP can only have zero indices).
struct ParamInfo {
  // The base value. It is either a global variable or a resource-access
  // builtin function (clspv.resource.var.* or clspv.local.var.*).
  Value *base = nullptr;
  // The descriptor set.
  uint32_t set = 0;
  // The binding.
  uint32_t binding = 0;
  // If base is a resource, then this is the resource type.
  // If base is a pointer-to-local, then this is the array type.
  // If base is a global value, then this is the value type (the type stored
  // in the global value).
  Type *pointee_type = nullptr;
  // If the call parameter is a GEP, then this is the number of zero-indices
  // the GEP used.
  unsigned num_gep_zeroes = 0;
  // A sample call using this function argument as the resource described
  // above.
  CallInst *sample_call = nullptr;

  bool operator==(const ParamInfo &other) const {
    return base == other.base && set == other.set && binding == other.binding &&
           num_gep_zeroes == other.num_gep_zeroes;
  }
  bool operator!=(const ParamInfo &other) const { return !(*this == other); }
};

// Unpack GEPs with zeros, if we can.  Rewrite |value| as we go along.
Value *StripZeroGEPs(Value *value, unsigned *num_gep_zeroes = nullptr) {
  bool first_gep = true;
  while (auto *gep = dyn_cast<GetElementPtrInst>(value)) {
    if (!gep->hasAllZeroIndices())
      return num_gep_zeroes ? nullptr : value;
    // If not the first GEP, then ignore the "element" index (which I call
    // "slide") since that will be combined with the last index of the
    // previous GEP.
    if (num_gep_zeroes)
      *num_gep_zeroes += gep->getNumIndices() + (first_gep ? 0 : -1);
    value = gep->getPointerOperand();
    first_gep = false;
  }
  return value;
}

bool ExtractParamInfo(Value *value, ParamInfo &pi, bool allow_null = false) {
  if (allow_null &&
      (isa<ConstantPointerNull>(value) || isa<UndefValue>(value))) {
    pi = {value, 0, 0, nullptr, 0, nullptr};
    return true;
  }
  // We care about two cases:
  //     - a direct call to clspv.resource.var.*
  //     - a GEP with only zero indices, where the base pointer is
  //       direct call to @clspv.resource.var.* or clspv.local.var.*,
  //       or is a global value for a workgroup variable.
  unsigned num_gep_zeroes = 0;
  value = StripZeroGEPs(value, &num_gep_zeroes);
  if (!value)
    return false;
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
      const auto binding =
          uint32_t(dyn_cast<ConstantInt>(
                       call->getOperand(clspv::ClspvOperand::kResourceBinding))
                       ->getZExtValue());
      auto *resource_type =
          call->getOperand(clspv::ClspvOperand::kResourceDataType)->getType();
      pi = {callee, set, binding, resource_type, num_gep_zeroes, call};
      return true;
    } else if (!allow_null &&
               func_info.getType() == clspv::Builtins::kClspvLocal) {
      const uint32_t spec_id =
          uint32_t(dyn_cast<ConstantInt>(
                       call->getOperand(clspv::ClspvOperand::kWorkgroupSpecId))
                       ->getZExtValue());
      auto *array_ty =
          call->getOperand(clspv::ClspvOperand::kWorkgroupDataType)->getType();
      pi = {callee, spec_id, 0, array_ty, num_gep_zeroes, call};
      return true;
    }
  } else if (!allow_null) {
    if (auto *gv = dyn_cast<GlobalValue>(value)) {
      // This occurs when there a __local variable is declared inside a
      // function. (Are there other times?)
      pi = {value, 0, 0, gv->getValueType(), num_gep_zeroes, nullptr};
      return true;
    }
  }
  return false;
}

Value *MaterializeParamInfo(IRBuilder<> &Builder, const ParamInfo &pi) {
  Value *replacement = pi.base;
  if (auto *function = dyn_cast<Function>(replacement)) {
    // Create the call.
    SmallVector<Value *, 8> args(pi.sample_call->arg_begin(),
                                 pi.sample_call->arg_end());
    replacement = Builder.CreateCall(function, args);
    if (ShowDRA) {
      outs() << "DRA:    Replace: call " << *replacement << "\n";
    }
  }
  if (pi.num_gep_zeroes) {
    SmallVector<Value *, 3> zeroes(pi.num_gep_zeroes, Builder.getInt32(0));
    // Builder.CreateGEP is not used to avoid creating a GEPConstantExpr in the
    // case of global variables.
    replacement =
        GetElementPtrInst::Create(pi.pointee_type, replacement, zeroes);
    Builder.Insert(cast<Instruction>(replacement));
    if (ShowDRA) {
      outs() << "DRA:    Replace: gep  " << *replacement << "\n";
    }
  }
  return replacement;
}

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

bool ExtractPointerArrayParamInfos(ArrayRef<Value *> elems,
                                   SmallVectorImpl<ParamInfo> &infos) {
  infos.resize(elems.size());
  for (size_t k = 0; k < elems.size(); ++k) {
    if (!ExtractParamInfo(elems[k], infos[k], /*allow_null=*/true))
      return false;
  }
  return true;
}

// Checks whether all callers of |fn| pass a pointer array with the same
// resource descriptors for |arg_index|, storing the common descriptors in
// |common|.
bool FindCommonCallerPointerArray(
    Function *fn, unsigned arg_index,
    const DenseMap<Value *, SmallVector<ParamInfo, 8>> &ptr_array_map,
    SmallVectorImpl<ParamInfo> &common) {
  bool seen_one = false;
  for (User *usr : fn->users()) {
    auto *caller = dyn_cast<CallInst>(usr);
    if (!caller)
      return false;
    Value *val = StripZeroGEPs(caller->getArgOperand(arg_index));
    auto it = ptr_array_map.find(val);
    if (it == ptr_array_map.end())
      return false;
    if (!seen_one) {
      common = it->second;
      seen_one = true;
    } else if (common != it->second) {
      return false;
    }
  }
  return seen_one;
}

bool HasLoadFromPointerArray(Value *v) {
  for (User *u : v->users()) {
    if (isa<LoadInst>(u) ||
        (isa<GetElementPtrInst>(u) && HasLoadFromPointerArray(u)))
      return true;
  }
  return false;
}

void MaterializePointerArrayForArg(Argument &arg, ArrayRef<ParamInfo> common) {
  if (!HasLoadFromPointerArray(&arg))
    return;
  Function *fn = arg.getParent();
  IRBuilder<> Builder(fn->getEntryBlock().getFirstNonPHIIt());
  SmallVector<Value *, 8> fn_elems;
  for (const ParamInfo &pi : common)
    fn_elems.push_back(MaterializeParamInfo(Builder, pi));
  ReplaceLoadsFromPointerArray(&arg, fn_elems);
}

// Propagates resource pointer arrays across private pointer parameters in
// topological call-graph order, then disconnects rewritten call arguments.
void PropagatePointerArrayArguments(
    const UniqueVector<Function *> &ordered_functions,
    DenseMap<Value *, SmallVector<ParamInfo, 8>> &ptr_array_map) {
  SmallVector<Argument *, 16> rewritten_args;
  for (Function *fn : ordered_functions) {
    if (fn->isDeclaration() ||
        fn->getCallingConv() == CallingConv::SPIR_KERNEL || fn->use_empty())
      continue;
    for (Argument &arg : fn->args()) {
      if (!arg.getType()->isPointerTy() ||
          arg.getType()->getPointerAddressSpace() !=
              clspv::AddressSpace::Private)
        continue;
      SmallVector<ParamInfo, 8> common;
      if (!FindCommonCallerPointerArray(fn, arg.getArgNo(), ptr_array_map,
                                        common))
        continue;
      ptr_array_map[&arg] = common;
      rewritten_args.push_back(&arg);
      MaterializePointerArrayForArg(arg, common);
    }
  }

  for (Argument *arg : llvm::reverse(rewritten_args)) {
    auto *null_ptr =
        ConstantPointerNull::get(cast<PointerType>(arg->getType()));
    for (User *usr : arg->getParent()->users()) {
      if (auto *caller = dyn_cast<CallInst>(usr))
        caller->setArgOperand(arg->getArgNo(), null_ptr);
    }
    EraseDeadPointerArrayUsers(arg);
  }
}

// Lowers local alloca arrays of resource pointers to direct resource accesses.
void RewritePointerArrayAccesses(
    Module &M, const UniqueVector<Function *> &ordered_functions) {
  const DataLayout &DL = M.getDataLayout();
  DenseMap<Value *, SmallVector<ParamInfo, 8>> ptr_array_map;
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

        SmallVector<ParamInfo, 8> info_vec;
        if (ExtractPointerArrayParamInfos(elems, info_vec))
          ptr_array_map[alloca] = std::move(info_vec);
      }
    }
  }

  PropagatePointerArrayArguments(ordered_functions, ptr_array_map);

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
    RewritePointerArrayAccesses(M, ordered_functions);
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
  if (fn->use_empty()) {
    return false;
  }

  // The common valid parameter info across all the callers seen so far.
  ParamInfo common = {};
  bool seen_one = false;
  for (auto &use : fn->uses()) {
    auto *caller = dyn_cast<CallInst>(use.getUser());
    if (!caller)
      return false;
    ParamInfo pi;
    if (!ExtractParamInfo(caller->getArgOperand(arg_index), pi))
      return false;
    if (!seen_one) {
      common = pi;
      seen_one = true;
    } else if (pi != common) {
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
  IRBuilder<> Builder(fn->getParent()->getContext());
  Builder.SetInsertPoint(fn->getEntryBlock().getFirstNonPHIIt());
  Value *replacement = MaterializeParamInfo(Builder, common);
  arg.replaceAllUsesWith(replacement);

  return true;
}
