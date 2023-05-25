; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[gep:%[^ ]+]] = getelementptr [4 x [8 x <4 x i32>]], ptr addrspace(1) %a, i32 1, i32 1, i32 0
; CHECK-NEXT: load <4 x i32>, ptr addrspace(1) [[gep]]
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr [4 x [8 x <4 x i32>]], ptr addrspace(1) %a, i32 1, i32 2, i32 2, i32 1
; CHECK-NEXT: load i32, ptr addrspace(1) [[gep]]
; CHECK-NEXT: ret void

define spir_kernel void @foo(ptr addrspace(1) %a) {
entry:
  %0 = getelementptr [4 x [8 x <4 x i32>]], ptr addrspace(1) %a, i32 1, i32 1, i32 0
  %1 = load <4 x i32>, ptr addrspace(1) %0
  %2 = getelementptr [8 x <4 x i32>], ptr addrspace(1) %0, i32 1, i32 2, i32 1
  %3 = load i32, ptr addrspace(1) %2
  ret void
}
