; RUN: clspv-opt --passes=replace-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; CHECK: [[gep1:%[a-zA-Z0-9_]+]] = getelementptr i8, ptr addrspace(1) %0, i32 0
; CHECK: [[val1:%[a-zA-Z0-9_]+]] = load i8, ptr addrspace(1) [[gep1]]
; CHECK: [[gep2:%[a-zA-Z0-9_]+]] = getelementptr i8, ptr addrspace(1) %0, i32 1
; CHECK: [[val2:%[a-zA-Z0-9_]+]] = load i8, ptr addrspace(1) [[gep2]]
; CHECK: [[insert1:%[^ ]+]] = insertelement <2 x i8> poison, i8 [[val1]], i32 0
; CHECK: [[insert2:%[^ ]+]] = insertelement <2 x i8> [[insert1]], i8 [[val2]], i32 1
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x i8> [[insert2]] to i16
; CHECK: store i16 [[bitcast]], ptr addrspace(1) %out, align 2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in, ptr addrspace(1) %out) {
entry:
  %0 = getelementptr i8, ptr addrspace(1) %in, i32 0
  %1 = load i16, ptr addrspace(1) %0, align 2
  store i16 %1, ptr addrspace(1) %out, align 2
  ret void
}

