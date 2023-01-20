; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x i32> %0 to <4 x half>
; CHECK: [[shuffle0:%[^ ]+]] = shufflevector <4 x half> [[bitcast]], <4 x half> poison, <2 x i32> <i32 0, i32 1>
; CHECK: [[shuffle1:%[^ ]+]] = shufflevector <4 x half> [[bitcast]], <4 x half> poison, <2 x i32> <i32 2, i32 3>
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[shr]]
; CHECK: store <2 x half> [[shuffle0]], ptr addrspace(1) [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, ptr addrspace(1) %1, i32 [[add]]
; CHECK: store <2 x half> [[shuffle1]], ptr addrspace(1) [[gep]]
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load <2 x i32>, ptr addrspace(1) %b, align 8
  %1 = getelementptr <2 x half>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds <2 x i32>, ptr addrspace(1) %1, i32 %i
  store <2 x i32> %0, ptr addrspace(1) %arrayidx, align 8
  ret void
}

