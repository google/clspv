; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [10 x i32], ptr %alloca, i32 0, i32 0
; CHECK: [[ld0:%[a-zA-Z0-9_.]+]] = load i32, ptr [[gep]]

define spir_kernel void @foo(ptr addrspace(1) %a) {
entry:
  %alloca = alloca [10 x i32], align 8
  %0 = getelementptr [40 x i8], ptr %alloca, i32 0
  %1 = load i32, ptr %0, align 2
  store i32 %1, ptr addrspace(1) %a, align 4
  ret void
}
