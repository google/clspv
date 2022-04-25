; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 %i, 1
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractelement <2 x float> %0, i32 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractelement <2 x float> %0, i32 1
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 %i, 1
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 [[and]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %a, i32 [[shr]], i32 [[shl]]
; CHECK: store float [[ex0]], float addrspace(1)* [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, <4 x float> addrspace(1)* %a, i32 [[shr]], i32 [[add]]
; CHECK: store float [[ex1]], float addrspace(1)* [[gep]]
define spir_kernel void @foo(<4 x float> addrspace(1)* %a, <2 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = load <2 x float>, <2 x float> addrspace(1)* %b, align 8
  %1 = bitcast <4 x float> addrspace(1)* %a to <2 x float> addrspace(1)*
  %arrayidx = getelementptr inbounds <2 x float>, <2 x float> addrspace(1)* %1, i32 %i
  store <2 x float> %0, <2 x float> addrspace(1)* %arrayidx, align 8
  ret void
}

