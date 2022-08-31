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

#ifndef _CLSPV_LIB_THREE_ELEMENT_VECTOR_LOWERING_PASS_H
#define _CLSPV_LIB_THREE_ELEMENT_VECTOR_LOWERING_PASS_H

namespace clspv {
struct ThreeElementVectorLoweringPass
    : llvm::PassInfoMixin<ThreeElementVectorLoweringPass>,
      llvm::InstVisitor<ThreeElementVectorLoweringPass, llvm::Value *> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  // Implementation details for InstVisitor.

  using Visitor =
      llvm::InstVisitor<ThreeElementVectorLoweringPass, llvm::Value *>;
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

  /// Get a vector of 4 elements equivalent for this type, if it uses a vector
  /// of 3 elements. Returns nullptr if no lowering is required.
  llvm::Type *getEquivalentType(llvm::Type *Ty);

  /// Implementation details of getEquivalentType.
  llvm::Type *getEquivalentTypeImpl(llvm::Type *Ty);

  /// Return the equivalent type for @p Ty or @p Ty if no lowering is needed.
  llvm::Type *getEquivalentTypeOrSelf(llvm::Type *Ty) {
    auto *EquivalentTy = getEquivalentType(Ty);
    return EquivalentTy ? EquivalentTy : Ty;
  }

private:
  // High-level implementation details of runOnModule.

  /// Look for bitcast of vec3 inside the function
  bool vec3BitcastInFunction(llvm::Function &F);

  /// Returns whether the vec3 should be transform into vec4
  bool vec3ShouldBeLowered(llvm::Module &M);

  /// Lower all global variables in the module.
  bool runOnGlobals(llvm::Module &M);

  /// Lower the given function.
  bool runOnFunction(llvm::Function &F);

  /// In order not to overflow, we need to copy elements one by one when
  /// CopyMemory arguments are transformed from vec3 to vec4.
  llvm::Value *
  convertOpCopyMemoryOperation(llvm::CallInst &VectorCall,
                               llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Map the call @p CI to an OpenCL builtin function or an LLVM intrinsic to
  /// the same calls but reworking the args and the return value.
  llvm::Value *convertBuiltinCall(llvm::CallInst &CI,
                                  llvm::Type *EquivalentReturnTy,
                                  llvm::ArrayRef<llvm::Value *> EquivalentArgs);
  /// Replace all instructions that have vector of size 3 to vector of size 4.
  /// This will run at the end of the pass and before cleaning dead
  /// instructions. It was needed as opaque pointers will depend on inferring
  /// the types from other instructions so we should keep instructions change to
  /// the end of the pass pipeline.
  void replaceAllVec3Instances();
  /// Map the call @p CI to an OpenCL builtin function or an LLVM intrinsic to
  /// a calls with vec4 without reworking the args and the return value.
  llvm::Value *
  convertSIMDBuiltinCall(llvm::CallInst &CI, llvm::Type *EquivalentReturnTy,
                         llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  // Map calls of Spirv Operators builtin that cannot be convert using
  // convertBuiltinCall or convertSIMDBuiltinCall
  llvm::Value *
  convertSpirvOpBuiltinCall(llvm::CallInst &CI, llvm::Type *EquivalentReturnTy,
                            llvm::ArrayRef<llvm::Value *> EquivalentArgs);

  /// Create an alternative version of @p F that doesn't have vec3 as parameter
  /// or return types.
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
  /// A map between 3 elements vector types and their equivalent representation.
  llvm::DenseMap<llvm::Type *, llvm::Type *> TypeMap;

  /// Opaque pointer type cache.
  llvm::DenseMap<llvm::Value *, llvm::Type *> type_cache_;

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
};
} // namespace clspv

#endif // _CLSPV_LIB_THREE_ELEMENT_VECTOR_LOWERING_PASS_H
