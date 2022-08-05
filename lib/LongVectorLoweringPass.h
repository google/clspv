// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_LONG_VECTOR_LOWERING_PASS_H
#define _CLSPV_LIB_LONG_VECTOR_LOWERING_PASS_H

namespace clspv {
struct LongVectorLoweringPass
    : llvm::PassInfoMixin<LongVectorLoweringPass>,
      llvm::InstVisitor<LongVectorLoweringPass, llvm::Value *> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Implementation details for InstVisitor.

  using Visitor = llvm::InstVisitor<LongVectorLoweringPass, llvm::Value *>;
  using Visitor::visit;
  friend Visitor;

  /// Higher-level dispatcher. This is not provided by InstVisitor.
  /// Returns nullptr if no lowering is required.
  llvm::Value *visit(llvm::Value *V);

  /// Visit Constant. This is not provided by InstVisitor.
  llvm::Value *visitConstant(llvm::Constant &Cst);

  /// Visit Unary or Binary Operator. This is not provided by InstVisitor.
  llvm::Value *visitNAryOperator(llvm::Instruction &I);

  /// InstVisitor impl, general "catch-all" function.
  llvm::Value *visitInstruction(llvm::Instruction &I);

  // InstVisitor impl, specific cases.
  llvm::Value *visitAllocaInst(llvm::AllocaInst &I);
  llvm::Value *visitBinaryOperator(llvm::BinaryOperator &I);
  llvm::Value *visitCallInst(llvm::CallInst &I);
  llvm::Value *visitCastInst(llvm::CastInst &I);
  llvm::Value *visitCmpInst(llvm::CmpInst &I);
  llvm::Value *visitExtractElementInst(llvm::ExtractElementInst &I);
  llvm::Value *visitExtractValueInst(llvm::ExtractValueInst &I);
  llvm::Value *visitGetElementPtrInst(llvm::GetElementPtrInst &I);
  llvm::Value *visitInsertElementInst(llvm::InsertElementInst &I);
  llvm::Value *visitInsertValueInst(llvm::InsertValueInst &I);
  llvm::Value *visitLoadInst(llvm::LoadInst &I);
  llvm::Value *visitPHINode(llvm::PHINode &I);
  llvm::Value *visitSelectInst(llvm::SelectInst &I);
  llvm::Value *visitShuffleVectorInst(llvm::ShuffleVectorInst &I);
  llvm::Value *visitStoreInst(llvm::StoreInst &I);
  llvm::Value *visitUnaryOperator(llvm::UnaryOperator &I);

private:
  // Helpers for lowering values.

  /// Return true if the given @p U needs to be lowered.
  ///
  /// This only looks at the types involved, not the opcodes or anything else.
  bool handlingRequired(llvm::User &U);

  /// Return the lowered version of @p U or @p U itself when no lowering is
  /// required.
  llvm::Value *visitOrSelf(llvm::Value *U) {
    auto *V = visit(U);
    return V ? V : U;
  }

  /// Register the replacement of @p U with @p V.
  ///
  /// If @p U and @p V have the same type, replace the relevant usages as well
  /// to ensure the rest of the program is using the new instructions.
  void registerReplacement(llvm::Value &U, llvm::Value &V);

private:
  // Helpers for lowering types.

  /// Get a array equivalent for this type, if it uses a long vector.
  /// Returns nullptr if no lowering is required.
  llvm::Type *getEquivalentType(llvm::Type *Ty);

  /// Implementation details of getEquivalentType.
  llvm::Type *getEquivalentTypeImpl(llvm::Type *Ty);

  /// Return the equivalent type for @p Ty or @p Ty if no lowering is needed.
  llvm::Type *getEquivalentTypeOrSelf(llvm::Type *Ty) {
    auto *EquivalentTy = getEquivalentType(Ty);
    return EquivalentTy ? EquivalentTy : Ty;
  }

  /// Rework Indices for GEP
  void reworkIndices(llvm::SmallVector<llvm::Value *, 4> &Indices,
                     llvm::Type *Ty);
  /// Rework Indices for extractvalue and insertvalue
  void reworkIndices(llvm::SmallVector<unsigned, 4> &Indices, llvm::Type *Ty);

private:
  // Hight-level implementation details of runOnModule.

  /// Lower all global variables in the module.
  bool runOnGlobals(llvm::Module &M);

  /// Lower the given function.
  bool runOnFunction(llvm::Function &F);

  /// Map the call @p CI to an OpenCL builtin function or an LLVM intrinsic to
  /// calls to its scalar version.
  llvm::Value *convertBuiltinCall(llvm::CallInst &CI,
                                  llvm::Type *EquivalentReturnTy,
                                  llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Either call convertBuiltinCall for easy to map call, or specific routine
  /// for more particular builtin (shuffle, shuffle2).
  llvm::Value *
  convertAllBuiltinCall(llvm::CallInst &CI, llvm::Type *EquivalentReturnTy,
                        llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Perform the Shuffle2 operation element per element
  llvm::Value *convertBuiltinShuffle2(llvm::CallInst &CI,
                                      llvm::Type *EquivalentReturnTy,
                                      llvm::Value *SrcA, llvm::Value *SrcB,
                                      llvm::Value *Mask);

  // Map calls of Spirv Operators builtin that cannot be convert using
  // convertBuiltinCall
  llvm::Value *
  convertSpirvOpBuiltinCall(llvm::CallInst &CI, llvm::Type *EquivalentReturnTy,
                            llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Create an alternative version of @p F that doesn't have long vectors as
  /// parameter or return types.
  /// Returns nullptr if no lowering is required.
  llvm::Function *convertUserDefinedFunction(llvm::Function &F);

  /// Create (and insert) a call to the equivalent user-defined function.
  llvm::CallInst *
  convertUserDefinedFunctionCall(llvm::CallInst &CI,
                                 llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Clears the dead instructions and others that might be rendered dead
  /// by their removal.
  void cleanDeadInstructions();

  /// Remove all long-vector functions that were lowered.
  void cleanDeadFunctions();

  /// Remove all long-vector globals that were lowered.
  void cleanDeadGlobals();

private:
  /// A map between long-vector types and their equivalent representation.
  llvm::DenseMap<llvm::Type *, llvm::Type *> TypeMap;

  /// A map between original values and their replacement.
  ///
  /// The content of this mapping is valid only for the function being visited
  /// at a given time. The keys in this mapping should be removed from the
  /// function once all instructions in the current function have been visited
  /// and transformed. Instructions are not removed from the function as they
  /// are visited because this would invalidate iterators.
  llvm::DenseMap<llvm::Value *, llvm::Value *> ValueMap;

  /// A map between functions and their replacement. This includes OpenCL
  /// builtin declarations.
  ///
  /// The keys in this mapping should be deleted when finishing processing the
  /// module.
  llvm::DenseMap<llvm::Function *, llvm::Function *> FunctionMap;

  /// A map between global variables and their replacement.
  ///
  /// The map is filled before any functions are visited, yet the original
  /// globals are not removed from the module. Their removal is deferred once
  /// all functions have been visited.
  llvm::DenseMap<llvm::GlobalVariable *, llvm::GlobalVariable *>
      GlobalVariableMap;

  const llvm::DataLayout *DL;
};
} // namespace clspv

#endif // _CLSPV_LIB_LONG_VECTOR_LOWERING_PASS_H
