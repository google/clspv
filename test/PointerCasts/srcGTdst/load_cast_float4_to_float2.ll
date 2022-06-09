; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 1
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[shl]], 2
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shl]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[shr]], i32 [[and]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load float, float addrspace(1)* [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[and]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %b, i32 [[shr]], i32 [[add]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load float, float addrspace(1)* [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> undef, float [[ld0]], i32 0
; CHECK: insertelement <2 x float> [[in0]], float [[ld1]], i32 1
define spir_kernel void @foo(<2 x float> addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <4 x float> addrspace(1)* %b to <2 x float> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x float>, <2 x float> addrspace(1)* %0, i32 %i
  %1 = load <2 x float>, <2 x float> addrspace(1)* %arrayidx, align 8
  store <2 x float> %1, <2 x float> addrspace(1)* %a, align 8
  ret void
}

