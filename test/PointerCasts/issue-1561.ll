; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-LABEL: @out_of_order_chain(
; CHECK: label1:
; CHECK-NEXT:   br label %label2
; CHECK: label0:
; CHECK-NEXT:   br label %label1
; CHECK: label2:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dest, i32 0
; CHECK-NEXT:   store i32 0, ptr addrspace(1) [[gep]], align 8
; CHECK-NEXT:   ret void
define dso_local spir_kernel void @out_of_order_chain(ptr addrspace(1) align 8 %dest) {
entry:
  br label %label0

label1:
  %idx0 = getelementptr i8, ptr addrspace(1) %idx2, i32 0
  br label %label2

label0:
  %idx1 = getelementptr i8, ptr addrspace(1) %dest, i32 0
  %idx2 = getelementptr i8, ptr addrspace(1) %idx1, i32 0
  br label %label1

label2:
  %idx3 = getelementptr i8, ptr addrspace(1) %idx0, i32 0
  store i32 0, ptr addrspace(1) %idx3, align 8
  ret void
}

; CHECK-LABEL: @multi_user_chain(
; CHECK: label1:
; CHECK-NEXT:   [[gep0:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dest, i32 4
; CHECK-NEXT:   [[v0:%[^ ]+]] = load i32, ptr addrspace(1) [[gep0]], align 4
; CHECK-NEXT:   store i32 [[v0]], ptr addrspace(1) %out, align 4
; CHECK-NEXT:   br label %label2
; CHECK: label0:
; CHECK-NEXT:   br label %label1
; CHECK: label2:
; CHECK-NEXT:   [[gep1:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %dest, i32 6
; CHECK-NEXT:   [[v1:%[^ ]+]] = load i32, ptr addrspace(1) [[gep1]], align 4
; CHECK-NEXT:   store i32 [[v1]], ptr addrspace(1) %out, align 4
; CHECK-NEXT:   ret void
define dso_local spir_kernel void @multi_user_chain(ptr addrspace(1) align 8 %dest, ptr addrspace(1) align 8 %out) {
entry:
  br label %label0

label1:
  %idx0 = getelementptr i32, ptr addrspace(1) %idx2, i32 1
  %v0 = load i32, ptr addrspace(1) %idx0, align 4
  store i32 %v0, ptr addrspace(1) %out, align 4
  br label %label2

label0:
  %idx1 = getelementptr i32, ptr addrspace(1) %dest, i32 1
  %idx2 = getelementptr i32, ptr addrspace(1) %idx1, i32 2
  br label %label1

label2:
  %idx3 = getelementptr i32, ptr addrspace(1) %idx2, i32 3
  %v1 = load i32, ptr addrspace(1) %idx3, align 4
  store i32 %v1, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: @struct_chain_dynamic_idx(
; CHECK-NEXT: entry:
; CHECK-NEXT:   [[gep0:%[^ ]+]] = getelementptr { i32, float }, ptr addrspace(1) %a, i32 0, i32 0
; CHECK-NEXT:   [[gep1:%[^ ]+]] = getelementptr i32, ptr addrspace(1) [[gep0]], i32 %i
; CHECK-NEXT:   store i32 1, ptr addrspace(1) [[gep1]], align 4
; CHECK-NEXT:   ret void
define dso_local spir_kernel void @struct_chain_dynamic_idx(ptr addrspace(1) %a, i32 %i) {
entry:
  %0 = getelementptr { i32, float }, ptr addrspace(1) %a, i32 0, i32 0
  %1 = getelementptr i32, ptr addrspace(1) %0, i32 0
  %2 = getelementptr i32, ptr addrspace(1) %1, i32 %i
  store i32 1, ptr addrspace(1) %2, align 4
  ret void
}
