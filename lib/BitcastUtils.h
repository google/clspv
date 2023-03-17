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

#ifndef _CLSPV_LIB_BITCAST_UTILS_PASS_H
#define _CLSPV_LIB_BITCAST_UTILS_PASS_H

#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace BitcastUtils {

size_t SizeInBits(const DataLayout &DL, Type *Ty);
size_t SizeInBits(IRBuilder<> &builder, Type *Ty);

Type *GetEleType(Type *Ty);
unsigned GetNumEle(Type *Ty);

void ExtractFromArray(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values,
                      bool isPackedStructSource = false,
                      unsigned DstTySize = 0);
void ExtractFromVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values);
void BitcastIntoVector(IRBuilder<> &Builder, SmallVector<Value *, 8> &Values,
                       unsigned NumElePerVec, Type *Ty);
void ConvertInto(Type *Ty, IRBuilder<> &Builder,
                 SmallVector<Value *, 8> &Values);

bool RemoveCstExprFromFunction(Function *F);

bool IsImplicitCasts(Module &M, DenseMap<Value *, Type *> &type_cache,
                     Instruction &I, Value *&source, Type *&source_ty,
                     Type *&dest_ty, bool ReplacePhysicalPointerBitcasts);

SmallVector<size_t, 4> getEleTypesBitWidths(Type *Ty, const DataLayout &DL,
                                            Type *BaseTy);
SmallVector<size_t, 4> getEleTypesBitWidths(Type *Ty, const DataLayout &DL);

Type *GetIndexTy(IRBuilder<> &Builder);
ConstantInt *GetIndexTyConst(IRBuilder<> &Builder, uint64_t C);

Value *CreateDiv(IRBuilder<> &Builder, unsigned div, Value *Val);
Value *CreateMul(IRBuilder<> &Builder, unsigned mul, Value *Val);
Value *CreateRem(IRBuilder<> &Builder, unsigned rem, Value *Val);

bool FindAliasingContainedType(Type *ContainingTy, Type *TargetTy, int &Steps,
                               bool &PerfectMatch, const DataLayout &DL);
} // namespace BitcastUtils

#endif // _CLSPV_LIB_BITCAST_UTILS_PASS_H
