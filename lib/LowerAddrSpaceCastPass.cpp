// Copyright 2023 The Clspv Authors. All rights reserved.
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

#include "LowerAddrSpaceCastPass.h"
#include "BitcastUtils.h"
#include "Builtins.h"
#include "Constants.h"
#include "Types.h"
#include "clspv/AddressSpace.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Transforms/Utils/Local.h"

using namespace llvm;

#define DEBUG_TYPE "LowerAddrSpaceCast"

namespace {

using PartitionCallback = std::function<void(Instruction *)>;

/// Partition the @p Instructions based on their liveness.
void partitionInstructions(ArrayRef<WeakTrackingVH> Instructions,
                           PartitionCallback OnDead,
                           PartitionCallback OnAlive) {
  for (auto OldValueHandle : Instructions) {
    // Handle situations when the weak handle is no longer valid.
    if (!OldValueHandle.pointsToAliveValue()) {
      continue; // Nothing else to do for this handle.
    }

    auto *OldInstruction = cast<Instruction>(OldValueHandle);
    bool Dead = OldInstruction->use_empty();
    if (Dead) {
      OnDead(OldInstruction);
    } else {
      OnAlive(OldInstruction);
    }
  }
}

bool isGenericPTy(Type *Ty) {
  return Ty && Ty->isPointerTy() &&
         Ty->getPointerAddressSpace() == clspv::AddressSpace::Generic;
}
} // namespace

PreservedAnalyses clspv::LowerAddrSpaceCastPass::run(Module &M,
                                                     ModuleAnalysisManager &) {
  PreservedAnalyses PA;

  for (auto &F : M.functions()) {
    BitcastUtils::RemoveCstExprFromFunction(&F);
    runOnFunction(F);
  }
  cleanModule(M);

  return PA;
}

Value *clspv::LowerAddrSpaceCastPass::visit(Value *V) {
  auto it = ValueMap.find(V);
  if (it != ValueMap.end()) {
    return it->second;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (I == nullptr) {
    return V;
  }

  if (auto *alloca = dyn_cast<AllocaInst>(I)) {
    if (alloca->getAllocatedType()->isPointerTy() &&
        alloca->getAllocatedType()->getPointerAddressSpace() !=
            clspv::AddressSpace::Private) {
      return visit(alloca);
    }
  }

  if (isGenericPTy(I->getType())) {
    return visit(I);
  }

  for (auto &Operand : I->operands()) {
    if (isGenericPTy(Operand->getType())) {
      return visit(I);
    }
  }

  return V;
}

llvm::Value *
clspv::LowerAddrSpaceCastPass::visitAllocaInst(llvm::AllocaInst &I) {
  IRBuilder<> B(&I);
  auto alloca = B.CreateAlloca(
      PointerType::get(I.getContext(), clspv::AddressSpace::Private),
      I.getArraySize(), I.getName());
  registerReplacement(&I, alloca);
  return alloca;
}

llvm::Value *
clspv::LowerAddrSpaceCastPass::visitAtomicRMWInst(llvm::AtomicRMWInst &I) {
  IRBuilder<> B(&I);
  auto atomic =
      B.CreateAtomicRMW(I.getOperation(), visit(I.getPointerOperand()),
                        I.getValOperand(), I.getAlign(), I.getOrdering());
  registerReplacement(&I, atomic);
  I.replaceAllUsesWith(atomic);
  return atomic;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitLoadInst(llvm::LoadInst &I) {
  IRBuilder<> B(&I);
  Type *Ty = I.getType();
  Value *Ptr = visit(I.getPointerOperand());
  if (isGenericPTy(Ty)) {
    Ty = clspv::InferType(Ptr, I.getContext(), &TypeCache);
  }
  auto load = B.CreateLoad(Ty, Ptr, I.getName());
  registerReplacement(&I, load);
  if (!isGenericPTy(I.getType())) {
    I.replaceAllUsesWith(load);
  }
  return load;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitStoreInst(llvm::StoreInst &I) {
  IRBuilder<> B(&I);
  Value *Val = visit(I.getValueOperand());
  Value *Ptr = visit(I.getPointerOperand());
  if (isa<ConstantPointerNull>(Val)) {
    Val = ConstantPointerNull::get(PointerType::get(
        I.getContext(), clspv::InferType(Ptr, I.getContext(), &TypeCache)
                            ->getPointerAddressSpace()));
  }
  auto store = B.CreateStore(Val, Ptr);
  registerReplacement(&I, store);
  return store;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitGetElementPtrInst(
    llvm::GetElementPtrInst &I) {
  IRBuilder<> B(&I);
  auto gep = B.CreateGEP(I.getSourceElementType(), visit(I.getPointerOperand()),
                         SmallVector<Value *>{I.indices()}, I.getName(),
                         I.isInBounds());
  registerReplacement(&I, gep);
  return gep;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitAddrSpaceCastInst(
    llvm::AddrSpaceCastInst &I) {
  auto ptr = visit(I.getPointerOperand());
  // Returns a pointer that points to a region in the address space if
  // "to_addrspace" can cast ptr to the address space. Otherwise it returns
  // NULL.
  if (ptr->getType() != I.getSrcTy() && ptr->getType() != I.getDestTy()) {
    ptr = ConstantPointerNull::get(cast<PointerType>(I.getType()));
  }
  if (ptr->getType() == I.getDestTy()) {
    I.replaceAllUsesWith(ptr);
  }
  registerReplacement(&I, ptr);
  return ptr;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitICmpInst(llvm::ICmpInst &I) {
  IRBuilder<> B(&I);
  Value *Op0 = visit(I.getOperand(0));
  Value *Op1 = visit(I.getOperand(1));
  if (Op0->getType() != Op1->getType()) {
    if (isa<ConstantPointerNull>(Op0)) {
      Op0 = ConstantPointerNull::get(cast<PointerType>(Op1->getType()));
    } else if (isa<ConstantPointerNull>(Op1)) {
      Op1 = ConstantPointerNull::get(cast<PointerType>(Op0->getType()));
    } else {
      llvm_unreachable("unsupported operand of icmp in loweraddrspacecast");
    }
  }

  auto icmp = B.CreateICmp(I.getPredicate(), Op0, Op1, I.getName());
  registerReplacement(&I, icmp);
  I.replaceAllUsesWith(icmp);
  return icmp;
}

llvm::Value *clspv::LowerAddrSpaceCastPass::visitCallInst(llvm::CallInst &I) {
  SmallVector<Value *, 16> EquivalentArgs;
  SmallVector<Type *, 8> EquivalentTypes;
  for (auto &ArgUse : I.args()) {
    Value *Arg = ArgUse.get();
    Value *EquivalentArg = visit(Arg);
    EquivalentArgs.push_back(EquivalentArg);
    EquivalentTypes.push_back(EquivalentArg->getType());
  }
  Function *F = I.getCalledFunction();
  assert(F && "Only function calls are supported.");

  auto FunctionTy =
      FunctionType::get(F->getReturnType(), EquivalentTypes, F->isVarArg());

  const auto &Info = clspv::Builtins::Lookup(F);
  auto fixNameSuffix = [&F](std::string Name) {
    std::string AS_pattern = "PU3AS";
    size_t AS_pattern_size = AS_pattern.size() + 1;

    auto pos = Name.find(AS_pattern);
    size_t pattern_size = AS_pattern_size;
    if (pos == std::string::npos) {
      // if AS_pattern was not found, it means that we are most probably looking
      // for a private pointer pattern
      pos = Name.find("P");
      pattern_size = strlen("P");
      if (pos == std::string::npos) {
        // if this pattern was also not found, just return the input string
        return Name;
      }
    }

    auto Name_start = pos + pattern_size;
    auto Name_end = Name.size() - Name_start;
    auto subName = Name.substr(Name_start, Name_end);

    auto FName = F->getName();
    auto FName_start = FName.find(AS_pattern) + AS_pattern_size;
    auto FName_end = FName.size() - FName_start;
    auto subFName = FName.substr(FName_start, FName_end);

    if (subName != subFName) {
      Name = Name.replace(Name_start, Name_end, subFName);
    }
    return Name;
  };

  std::string Name = Info.getName();
  if (Info.getType() == clspv::Builtins::kSpirvOp) {
    auto *opcode = dyn_cast<ConstantInt>(EquivalentArgs[0]);
    Name = Builtins::GetMangledFunctionName(Name.c_str());
    Name += ".";
    Name += std::to_string(opcode->getZExtValue());
    Name += ".";
    for (size_t i = 1; i < EquivalentTypes.size(); i++) {
      Name += Builtins::GetMangledTypeName(EquivalentTypes[i]);
    }
  } else {
    Name = fixNameSuffix(
        clspv::Builtins::GetMangledFunctionName(Name.c_str(), FunctionTy));
  }

  Module *M = I.getModule();
  auto getEquivalentFunction = [&Name, &M, &FunctionTy, this, &F]() {
    Function *eqF = M->getFunction(Name);
    if (eqF != nullptr)
      return eqF;

    eqF = FunctionMap[F];
    if (eqF != nullptr)
      return eqF;

    eqF = Function::Create(FunctionTy, F->getLinkage(), Name);
    eqF->setIsNewDbgInfoFormat(true);
    FunctionMap[F] = eqF;
    M->getFunctionList().push_front(eqF);

    return eqF;
  };
  Function *EquivalentFunction = getEquivalentFunction();
  EquivalentFunction->copyAttributesFrom(F);
  EquivalentFunction->setCallingConv(F->getCallingConv());

  IRBuilder<> B(&I);
  auto call = B.CreateCall(EquivalentFunction, EquivalentArgs);
  call->copyIRFlags(&I);
  call->copyMetadata(I);
  call->setCallingConv(I.getCallingConv());

  registerReplacement(&I, call);
  I.replaceAllUsesWith(call);
  return call;
}

Value *clspv::LowerAddrSpaceCastPass::visitIntToPtrInst(IntToPtrInst &I) {
  SmallVector<Instruction *> Uses;
  for (auto &use : I.uses()) {
    if (auto Iuse = dyn_cast<Instruction>(&use)) {
      Uses.push_back(Iuse);
    }
  }
  clspv::AddressSpace::Type AS = clspv::AddressSpace::Global;
  bool found = false;
  DenseSet<Value *> seen;
  while (!Uses.empty()) {
    auto *U = Uses.pop_back_val();
    if (seen.contains(U)) {
      continue;
    }
    seen.insert(U);
    if (auto ASCast = dyn_cast<AddrSpaceCastInst>(U)) {
      clspv::AddressSpace::Type ASCastAS =
          (clspv::AddressSpace::Type)ASCast->getDestAddressSpace();
      if (!found) {
        AS = ASCastAS;
        found = true;
      } else if (AS != ASCastAS) {
        llvm_unreachable(
            "Result of IntToPtr is casted into 2 different address space");
      }
    } else {
      for (auto &use : U->uses()) {
        if (auto Iuse = dyn_cast<Instruction>(&use)) {
          Uses.push_back(Iuse);
        }
      }
    }
  }
  IRBuilder<> B(&I);
  Value *V =
      B.CreateIntToPtr(I.getOperand(0), PointerType::get(I.getContext(), AS));
  registerReplacement(&I, V);

  return V;
}

Value *clspv::LowerAddrSpaceCastPass::visitPtrToIntInst(PtrToIntInst &I) {
  auto ptr = visit(I.getPointerOperand());

  IRBuilder<> B(&I);
  auto ptrToInt = B.CreatePtrToInt(ptr, I.getDestTy());

  registerReplacement(&I, ptrToInt);
  I.replaceAllUsesWith(ptrToInt);

  return ptrToInt;
}

static bool DependsOnPhiNode(const Value *V, const PHINode *PhiNode) {
  DenseSet<const llvm::Value *> Visited;
  if (!isa<Instruction>(V)) {
    return false;
  }

  SmallVector<const Value *, 16> Stack;
  Stack.push_back(V);

  while (!Stack.empty()) {
    const Value *Current = Stack.pop_back_val();
    if (Visited.contains(Current)) {
      continue;
    }
    Visited.insert(Current);

    if (Current == PhiNode) {
      return true;
    }

    if (const auto *Inst = dyn_cast<Instruction>(Current)) {
      for (const auto *Op : Inst->operand_values()) {
        if (!Visited.contains(Op)) {
          Stack.push_back(Op);
        }
      }
    }
  }

  return false;
}

Value *clspv::LowerAddrSpaceCastPass::visitPHINode(llvm::PHINode &I) {
  IRBuilder<> B(&I);
  unsigned N = I.getNumIncomingValues();

  // Analyse the incoming values anche check whether the types agree.
  // Ignore any incoming value that depends on the node itself, as that would
  // lead to infinite recursion. Instead, we delay processing them until
  // after we have registered the replacement.
  SmallVector<Value *, 2> Replacements(N);
  SmallVector<unsigned, 2> DependentOperands;
  Type *CommonTy = nullptr;
  bool HasCommonTy = true;

  for (unsigned j = 0; j < N; ++j) {
    auto *V = I.getIncomingValue(j);
    if (DependsOnPhiNode(V, &I)) {
      DependentOperands.push_back(j);
    } else {
      V = visit(V);
      if (HasCommonTy && !CommonTy) {
        CommonTy = V->getType();
      }
      HasCommonTy &= CommonTy == V->getType();
    }
    Replacements[j] = V;
  }

  if (!HasCommonTy) {
    // We don't have a common address space.
    llvm_unreachable("PHI nodes with different address spaces are unsupported");
  }

  auto *Phi = B.CreatePHI(CommonTy, N);

  registerReplacement(&I, Phi);

  // Now that we have registered the replacement, we can process the dependent
  // operands.
  for (auto i : DependentOperands) {
    Replacements[i] = visit(Replacements[i]);
  }

  for (unsigned i = 0; i < I.getNumIncomingValues(); ++i) {
    Phi->addIncoming(Replacements[i], I.getIncomingBlock(i));
  }

  return Phi;
}

Value *clspv::LowerAddrSpaceCastPass::visitInstruction(Instruction &I) {
#ifndef NDEBUG
  dbgs() << "Instruction not handled: " << I << '\n';
#endif
  llvm_unreachable("Missing support for instruction");
}

void clspv::LowerAddrSpaceCastPass::registerReplacement(Value *U, Value *V) {
  LLVM_DEBUG(dbgs() << "Replacement for " << *U << ": " << *V << '\n');
  assert(ValueMap.count(U) == 0 && "Value already registered");
  ValueMap.insert({U, V});
}

void clspv::LowerAddrSpaceCastPass::runOnFunction(Function &F) {
  LLVM_DEBUG(dbgs() << "Processing " << F.getName() << '\n');

  // Skip declarations.
  if (F.isDeclaration()) {
    return;
  }
  for (Instruction &I : instructions(&F)) {
    // Use the Value overload of visit to ensure cache is used.
    visit(static_cast<Value *>(&I));
  }

  cleanDeadInstructions();

  LLVM_DEBUG(dbgs() << "Final version for " << F.getName() << '\n');
  LLVM_DEBUG(dbgs() << F << '\n');
}

void clspv::LowerAddrSpaceCastPass::cleanModule(Module &M) {
  for (auto &GV : M.globals()) {
    if (GV.getName() == CLSPVBuiltinsUsed()) {
      assert(GV.use_empty());
      GV.eraseFromParent();
      break;
    }
  }
  SmallVector<Function *> ToBeRemoved;
  for (auto &F : M) {
    bool useCLSPVBuiltinsUsed = false;
    if (F.getNumUses() == 1) {
      auto C = dyn_cast<Constant>(F.user_back());
      useCLSPVBuiltinsUsed = C != nullptr && C->getNumUses() == 0;
    }
    if ((F.use_empty() || useCLSPVBuiltinsUsed) &&
        F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      ToBeRemoved.push_back(&F);
    }
  }
  for (auto F : ToBeRemoved) {
    F->eraseFromParent();
  }
}

void clspv::LowerAddrSpaceCastPass::cleanDeadInstructions() {
  // Collect all instructions that have been replaced by another one, and remove
  // them from the function. To address dependencies, use a fixed-point
  // algorithm:
  //  1. Collect the instructions that have been replaced.
  //  2. Collect among these instructions the ones which have no uses and remove
  //     them.
  //  3. Repeat step 2 until no progress is made.

  // Select instructions that were replaced by another one.
  // Ignore constants as they are not owned by the module and therefore don't
  // need to be removed.
  using WeakInstructions = SmallVector<WeakTrackingVH, 32>;
  WeakInstructions OldInstructions;
  for (const auto &Mapping : ValueMap) {
    if (Mapping.getSecond() != nullptr) {
      if (auto *OldInstruction = dyn_cast<Instruction>(Mapping.getFirst())) {
        OldInstructions.push_back(OldInstruction);
      } else {
        assert(isa<Constant>(Mapping.getFirst()) &&
               "Only Instruction and Constant are expected in ValueMap");
      }
    }
  }

  // Erase any mapping, as they won't be valid anymore.
  ValueMap.clear();

  for (bool Progress = true; Progress;) {
    std::size_t PreviousSize = OldInstructions.size();

    // Identify instructions that are actually dead and can be removed using
    // RecursivelyDeleteTriviallyDeadInstructions.
    // Use a third buffer to capture the instructions that are still alive to
    // avoid mutating OldInstructions while iterating over it.
    WeakInstructions NextBatch;
    WeakInstructions TriviallyDeads;
    partitionInstructions(
        OldInstructions,
        [&TriviallyDeads](Instruction *DeadInstruction) {
          // Additionally, manually remove from the parent instructions with
          // possible side-effect, generally speaking, such as call or alloca
          // instructions. Those are not trivially dead.
          if (isInstructionTriviallyDead(DeadInstruction)) {
            TriviallyDeads.push_back(DeadInstruction);
          } else {
            DeadInstruction->eraseFromParent();
          }
        },
        [&NextBatch](Instruction *AliveInstruction) {
          if (PHINode *Phi = dyn_cast<PHINode>(AliveInstruction)) {
            if (RecursivelyDeleteDeadPHINode(Phi)) {
              return;
            }
          }
          NextBatch.push_back(AliveInstruction);
        });

    RecursivelyDeleteTriviallyDeadInstructions(TriviallyDeads);

    // Update OldInstructions for the next iteration of the fixed-point.
    OldInstructions = std::move(NextBatch);
    Progress = (OldInstructions.size() < PreviousSize);
  }

#ifndef NDEBUG
  if (!OldInstructions.empty()) {
    dbgs() << "These values were expected to be removed:\n";
    for (auto ValueHandle : OldInstructions) {
      dbgs() << '\t' << *ValueHandle << '\n';
    }
    llvm_unreachable("Not all supposedly-dead instruction were removed!");
  }
#endif
}
