; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

; CHECK-DAG: [[in:%[a-zA-Z0-9_.]+]] = type { { i32 }, { i32 } }
; CHECK-DAG: [[out:%[a-zA-Z0-9_.]+]] = type { { [2 x i16] }, { <4 x i8> } }

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load [[in]], ptr addrspace(1)
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[in]] [[ld]], 0
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue { i32 } [[ex]], 0
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[in]] [[ld]], 1
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue { i32 } [[ex]], 0
; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i32 [[ex0]] to i64
; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i32 [[ex1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 32
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl]]

; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[or]] to i16
; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i16] undef, i16 [[trunc]], 0
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 16
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i16
; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertvalue [2 x i16] [[insert0]], i16 [[trunc]], 1
; CHECK: [[insert00:%[a-zA-Z0-9_.]+]] = insertvalue { [2 x i16] } undef, [2 x i16] [[insert1]], 0
; CHECK: [[insert000:%[a-zA-Z0-9_.]+]] = insertvalue [[out]] undef, { [2 x i16] } [[insert00]], 0

; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 32
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i8
; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> undef, i8 [[trunc]], i64 0
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 40
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i8
; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert0]], i8 [[trunc]], i64 1
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 48
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i8
; CHECK: [[insert2:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert1]], i8 [[trunc]], i64 2
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 56
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i8
; CHECK: [[insert3:%[a-zA-Z0-9_.]+]] = insertelement <4 x i8> [[insert2]], i8 [[trunc]], i64 3
; CHECK: [[insert11:%[a-zA-Z0-9_.]+]] = insertvalue { <4 x i8> } undef, <4 x i8> [[insert3]], 0
; CHECK: [[insert111:%[a-zA-Z0-9_.]+]] = insertvalue [[out]] [[insert000]], { <4 x i8> } [[insert11]], 1
; CHECK: store [[out]] [[insert111]], ptr addrspace(1)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.__in = type { { i32 }, { i32 } }
%struct.__out = type { { [2 x i16] }, { <4 x i8> } }

define spir_kernel void @testCopyInstance1(ptr addrspace(1) %src, ptr addrspace(1) %dst) {
entry:
  %0 = getelementptr %struct.__in, ptr addrspace(1) %src, i32 0
  %1 = getelementptr %struct.__out, ptr addrspace(1) %dst, i32 0
  %2 = load i64, ptr addrspace(1) %0, align 4
  store i64 %2, ptr addrspace(1) %1, align 4
  ret void
}

