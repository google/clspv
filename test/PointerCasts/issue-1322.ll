; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 9
; CHECK: [[load:%[^ ]+]] = load i64, ptr addrspace(1) [[gep]]
; CHECK: [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 11
; CHECK: store i64 [[load]], ptr addrspace(1) [[gep]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(ptr addrspace(1) %a) {
entry:
  %0 = getelementptr inbounds i8, ptr addrspace(1) %a, i64 36
  %1 = load i64, ptr addrspace(1) %0, align 8
  %2 = getelementptr inbounds i8, ptr addrspace(1) %a, i64 44
  store i64 %1, ptr addrspace(1) %2, align 8
  ret void
}
