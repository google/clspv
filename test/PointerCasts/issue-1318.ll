; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t.ll

; CHECK: [[ptr:%[^ ]+]] = inttoptr i64 %a to ptr addrspace(1)
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[ptr]], i32 1
; CHECK: load i32, ptr addrspace(1) [[gep]]

; UNTYPED: [[ptr:%[^ ]+]] = inttoptr i64 %a to ptr addrspace(1)
; UNTYPED: [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[ptr]]
; UNTYPED: load i32, ptr addrspace(1) [[gep]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(i64 %a) {
entry:
  %0 = inttoptr i64 %a to ptr addrspace(1)
  %1 = getelementptr i8, ptr addrspace(1) %0, i64 4
  %2 = load i32, ptr addrspace(1) %1, align 4
  ret void
}
