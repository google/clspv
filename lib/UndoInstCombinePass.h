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

#include "llvm/ADT/UniqueVector.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

#ifndef _CLSPV_LIB_UNDO_INST_COMBINE_PASS_H
#define _CLSPV_LIB_UNDO_INST_COMBINE_PASS_H

namespace clspv {
struct UndoInstCombinePass : llvm::PassInfoMixin<UndoInstCombinePass> {
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

private:
  bool runOnFunction(llvm::Function &F);

  // Undoes wide vector casts that are used in an extract, for example:
  //  %cast = bitcast <4 x i32> %src to <16 x i8>
  //  %extract = extractelement <16 x i8> %cast, i32 4
  //
  // With:
  //  %extract = extractelement <4 x i32> %src, i32 1
  //  %trunc = trunc i32 %extract to i8
  //
  // Also handles casts that get loaded, for example:
  //  %cast = bitcast <3 x i32>* %src to <6 x i16>*
  //  %load = load <6 x i16>, <6 x i16>* %cast
  //  %extract = extractelement <6 x i16> %load, i32 0
  //
  // With:
  //  %load = load <3 x i32>, <3 x i32>* %src
  //  %extract = extractelement <3 x i32> %load, i32 0
  //  %trunc = trunc i32 %extract to i16
  bool UndoWideVectorExtractCast(llvm::Instruction *inst);

  // Undoes wide vector casts that are used in a shuffle, for example:
  //  %cast = bitcast <4 x i32> %src to <16 x i8>
  //  %s = shufflevector <16 x i8> %cast, <16 x i8> undef,
  //                       <2 x i8> <i32 4, i32 8>
  //
  // With:
  //  %extract0 = <4 x i32> %src, i32 1
  //  %trunc0 = trunc i32 %extract0 to i8
  //  %insert0 = insertelement <2 x i8> zeroinitializer, i8 %trunc0, i32 0
  //  %extract1 = <4 x i32> %src, i32 2
  //  %trunc1 = trunc i32 %extract1 to i8
  //  %insert1 = insertelement <2 x i8> %insert0, i8 %trunc1, i32 1
  //
  // Also handles shuffles casted through a load, for example:
  //  %cast = bitcast <3 x i32>* %src to <6 x i16>
  //  %load = load <6 x i16>* %cast
  //  %shuffle = shufflevector <6 x i16> %load, <6 x i16> undef,
  //                            <2 x i32> <i32 2, i32 4>
  //
  // With:
  //  %load = load <3 x i32>, <3 x i32>* %src
  //  %ex0 = extractelement <3 x i32> %load, i32 1
  //  %trunc0 = trunc i32 %ex0 to i16
  //  %in0 = insertelement <2 x i16> zeroinitializer, i16 %trunc0, i32 0
  //  %ex1 = extractelement <3 x i32> %load, i32 2
  //  %trunc1 = trunc i32 %ex1 to i16
  //  %in1 = insertelement <2 x i16> %in0, i16 %trunc1, i32 1
  bool UndoWideVectorShuffleCast(llvm::Instruction *inst);

  llvm::UniqueVector<llvm::Value *> potentially_dead_;
  std::vector<llvm::Instruction *> dead_;
};
} // namespace clspv

#endif // _CLSPV_LIB_UNDO_INST_COMBINE_PASS_H
