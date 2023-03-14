; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: foo
; CHECK: [[load:%[^ ]+]] = load i32, ptr addrspace(1) %a, align 32
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 %i
; CHECK: store i32 [[load]], ptr addrspace(1) [[gep]], align 32

define spir_kernel void @foo(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = load i32, ptr addrspace(1) %a, align 32
  %1 = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 %i
  store i32 %0, ptr addrspace(1) %1, align 32
  ret void
}

; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) %a, align 32
; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[add:%[^ ]+]] = add i32 %j, [[shl]]
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[add]]
; CHECK:  store i32 [[load]], ptr addrspace(1) [[gep]], align 32

define spir_kernel void @bar(ptr addrspace(1) %a, i32 %i, i32 %j) {
entry:
  %0 = load i32, ptr addrspace(1) %a, align 32
  %1 = getelementptr [4 x i32], ptr addrspace(1) %a, i32 %i, i32 %j
  store i32 %0, ptr addrspace(1) %1, align 32
  ret void
}
