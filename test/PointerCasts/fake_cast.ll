; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: foo
; CHECK: [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 0
; CHECK: [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 32
; CHECK: [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 %i
; CHECK: store i32 [[load]], ptr addrspace(1) [[gep]], align 32

; UNTYPED: foo
; UNTYPED: [[load:%[^ ]+]] = load i32, ptr addrspace(1) %a, align 32
; UNTYPED: [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 %i
; UNTYPED: store i32 [[load]], ptr addrspace(1) [[gep]], align 32

define spir_kernel void @foo(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = load i32, ptr addrspace(1) %a, align 32
  %1 = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 %i
  store i32 %0, ptr addrspace(1) %1, align 32
  ret void
}

; CHECK:  bar
; CHECK:  [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 0, i32 0
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 32
; CHECK:  [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 %i, i32 %j
; CHECK:  store i32 [[load]], ptr addrspace(1) [[gep]], align 32

; UNTYPED: bar
; UNTYPED: [[load:%[^ ]+]] = load i32, ptr addrspace(1) %a, align 32
; UNTYPED: [[gep:%[^ ]+]] = getelementptr [4 x i32], ptr addrspace(1) %a, i32 %i, i32 %j
; UNTYPED: store i32 [[load]], ptr addrspace(1) [[gep]], align 32

define spir_kernel void @bar(ptr addrspace(1) %a, i32 %i, i32 %j) {
entry:
  %0 = load i32, ptr addrspace(1) %a, align 32
  %1 = getelementptr [4 x i32], ptr addrspace(1) %a, i32 %i, i32 %j
  store i32 %0, ptr addrspace(1) %1, align 32
  ret void
}
