; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

; CHECK: [[struct:%[a-zA-Z0-9_.]+]] = type { [2 x i32] }
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], ptr addrspace(1) %0, i32 0
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load [[struct]], ptr addrspace(1) [[gep]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[struct]] [[ld]], 0
; CHECK-DAG: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [2 x i32] [[ex]], 0
; CHECK-DAG: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ex0]] to i64
; CHECK-DAG: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [2 x i32] [[ex]], 1
; CHECK-DAG: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ex1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl]]
; CHECK-DAG: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i64 [[or]] to i32
; CHECK-DAG: [[insert0:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i32] poison, i32 [[trunc0]], 0
; CHECK-DAG: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 32
; CHECK-DAG: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i32
; CHECK-DAG: [[insert1:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i32] [[insert0]], i32 [[trunc1]], 1
; CHECK: [[insert:%[a-zA-Z0-9_.]+]] = insertvalue [[struct]] poison, [2 x i32] [[insert1]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], ptr addrspace(1) %1, i32 0
; CHECK: store [[struct]] [[insert]], ptr addrspace(1) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.__InstanceTest = type { [2 x i32] }

define spir_kernel void @testCopyInstance1(ptr addrspace(1) %src, ptr addrspace(1) %dst) {
entry:
  %0 = getelementptr %struct.__InstanceTest, ptr addrspace(1) %src, i32 0
  %1 = getelementptr %struct.__InstanceTest, ptr addrspace(1) %dst, i32 0
  %2 = load i64, ptr addrspace(1) %0, align 4
  store i64 %2, ptr addrspace(1) %1, align 4
  ret void
}

