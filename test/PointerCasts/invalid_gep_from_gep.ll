; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: @fct1
; CHECK-NEXT: entry:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { i16, i16, i32, i8, i8, i16, float }, ptr addrspace(1) %a, i32 0, i32 3
; CHECK-NEXT:   getelementptr i8, ptr addrspace(1) [[gep]], i32 3

define spir_kernel void @fct1(ptr addrspace(1) %a) {
entry:
  %0 = getelementptr {i16, i16, i32, i8, i8, i16, float}, ptr addrspace(1) %a, i32 0, i32 3
  %1 = getelementptr i8, ptr addrspace(1) %0, i32 3
  ret void
}

; CHECK: @fct2
; CHECK-NEXT: entry:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { i16, i16, i32, i8, i8, i16, float }, ptr addrspace(1) %a, i32 0, i32 3
; CHECK-NEXT:   getelementptr i8, ptr addrspace(1) [[gep]], i32 %i

define spir_kernel void @fct2(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = getelementptr {i16, i16, i32, i8, i8, i16, float}, ptr addrspace(1) %a, i32 0, i32 3
  %1 = getelementptr i8, ptr addrspace(1) %0, i32 %i
  ret void
}

; CHECK: @fct3
; CHECK-NEXT: entry:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { i16, i16, i32, i8, i8, i16, float }, ptr addrspace(1) %a, i32 0, i32 3
; CHECK-NOT:   getelementptr i8, ptr addrspace(1) [[gep]], i32 0
; CHECK-NEXT:   ret void

define spir_kernel void @fct3(ptr addrspace(1) %a) {
entry:
  %0 = getelementptr {i16, i16, i32, i8, i8, i16, float}, ptr addrspace(1) %a, i32 0, i32 3
  %1 = getelementptr i8, ptr addrspace(1) %0, i32 0
  ret void
}
