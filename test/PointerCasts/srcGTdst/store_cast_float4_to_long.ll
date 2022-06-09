; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:  [[shr:%[^ ]+]] = lshr i32 [[shl]], 2
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl]], 3
; CHECK:  [[bitcast:%[^ ]+]] = bitcast i64 %0 to <2 x float>
; CHECK:  [[extract0:%[^ ]+]] = extractelement <2 x float> [[bitcast]], i64 0
; CHECK:  [[extract1:%[^ ]+]] = extractelement <2 x float> [[bitcast]], i64 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[shr]], i32 [[and]]
; CHECK:  store float [[extract0]], float addrspace(1)* [[gep]], align 4
; CHECK:  [[add:%[^ ]+]] = add i32 [[and]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[shr]], i32 [[add]]
; CHECK:  store float [[extract1]], float addrspace(1)* [[gep]], align 4

define spir_kernel void @foo(i64 addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load i64, i64 addrspace(1)* %a, align 8
  %1 = bitcast <4 x float> addrspace(1)* %b to i64 addrspace(1)*
  %arrayidx = getelementptr inbounds i64, i64 addrspace(1)* %1, i32 %i
  store i64 %0, i64 addrspace(1)* %arrayidx, align 8
  ret void
}


