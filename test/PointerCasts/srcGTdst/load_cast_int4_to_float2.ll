; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 1
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i32 [[shl]], 2
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[shl]], 3
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i32>, ptr addrspace(1) %0, i32 [[shr]], i32 [[and]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add i32 [[and]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i32>, ptr addrspace(1) %0, i32 [[shr]], i32 [[add]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(1) [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> poison, i32 [[ld0]], i32 0
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i32> [[in0]], i32 [[ld1]], i32 1
; CHECK: bitcast <2 x i32> [[in1]] to <2 x float>
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <4 x i32>, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds <2 x float>, ptr addrspace(1) %0, i32 %i
  %1 = load <2 x float>, ptr addrspace(1) %arrayidx, align 8
  store <2 x float> %1, ptr addrspace(1) %a, align 8
  ret void
}


