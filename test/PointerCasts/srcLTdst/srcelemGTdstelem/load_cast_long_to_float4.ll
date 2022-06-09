; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i32 %i, 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, i64 addrspace(1)* %a, i32 [[shl]]
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i64, i64 addrspace(1)* [[gep]]
; CHECK: [[add0:%[a-zA-Z0-9_.]+]] = add i32 [[shl]], 1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr i64, i64 addrspace(1)* %a, i32 [[add0]]
; CHECK: [[ld1:%[a-zA-Z0-9_.]+]] = load i64, i64 addrspace(1)* [[gep]]
; CHECK: [[in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x i64> undef, i64 [[ld0]], i32 0
; CHECK: [[in1:%[a-zA-Z0-9_.]+]] = insertelement <2 x i64> [[in0]], i64 [[ld1]], i32 1
; CHECK: bitcast <2 x i64> [[in1]] to <4 x float>
define spir_kernel void @foo(i64 addrspace(1)* %a, <4 x float> addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast i64 addrspace(1)* %a to <4 x float> addrspace(1)*
  %arrayidx = getelementptr inbounds <4 x float>, <4 x float> addrspace(1)* %0, i32 %i
  %1 = load <4 x float>, <4 x float> addrspace(1)* %arrayidx, align 8
  store <4 x float> %1, <4 x float> addrspace(1)* %b, align 8
  ret void
}


