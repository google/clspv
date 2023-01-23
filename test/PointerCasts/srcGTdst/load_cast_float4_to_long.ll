; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 1
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[shl]], 2
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shl]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(1) %0, i32 [[shr]], i32 [[and]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[and]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x float>, ptr addrspace(1) %0, i32 [[shr]], i32 [[add]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> undef, float [[ld0]], i32 0
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x float> [[in0]], float [[ld1]], i32 1
; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast <2 x float> [[in1]] to i64

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <4 x float>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds i64, ptr addrspace(1) %0, i32 %i
  %1 = load i64, ptr addrspace(1) %arrayidx, align 8
  store i64 %1, ptr addrspace(1) %a, align 8
  ret void
}


