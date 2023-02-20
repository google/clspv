; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

; CHECK: [[struct:%[a-zA-Z0-9_.]+]] = type { [4 x i16] }
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], ptr addrspace(1) %0, i32 0
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load [[struct]], ptr addrspace(1) [[gep]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[struct]] [[ld]], 0
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 1
; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 2
; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 3
; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i16 [[ex0]] to i64
; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i16 [[ex1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 16
; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl]]
; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i16 [[ex2]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext2]], 32
; CHECK: [[or2:%[a-zA-Z0-9_.]+]] = or i64 [[or1]], [[shl]]
; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i16 [[ex3]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 48
; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[or2]], [[shl]]
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i64 [[or3]] to i16
; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] poison, i16 [[trunc0]], 0
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 16
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert0]], i16 [[trunc1]], 1
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 32
; CHECK: [[trunc2:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert2:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert1]], i16 [[trunc2]], 2
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 48
; CHECK: [[trunc3:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert3:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert2]], i16 [[trunc3]], 3
; CHECK: [[insert:%[a-zA-Z0-9_.]+]] = insertvalue [[struct]] poison, [4 x i16] [[insert3]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], ptr addrspace(1) %1, i32 0
; CHECK: store [[struct]] [[insert]], ptr addrspace(1) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.__InstanceTest = type { [4 x i16] }

define spir_kernel void @testCopyInstance1(ptr addrspace(1) %src, ptr addrspace(1) %dst) {
entry:
  %0 = getelementptr %struct.__InstanceTest, ptr addrspace(1) %src, i32 0
  %1 = getelementptr %struct.__InstanceTest, ptr addrspace(1) %dst, i32 0
  %2 = load i64, ptr addrspace(1) %0, align 4
  store i64 %2, ptr addrspace(1) %1, align 4
  ret void
}

