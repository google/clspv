; RUN: clspv-opt --passes=replace-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; CHECK: [[call:%[^ ]+]] = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i8] } zeroinitializer)
; CHECK: [[gep:%[^ ]+]] = getelementptr { [0 x i8] }, ptr addrspace(2) [[call]], i32 0
; CHECK: [[gep0:%[^ ]+]] = getelementptr i8, ptr addrspace(2) [[gep]], i32 0
; CHECK: [[load0:%[^ ]+]] = load i8, ptr addrspace(2) [[gep0]], align 1
; CHECK: [[gep1:%[^ ]+]] = getelementptr i8, ptr addrspace(2) [[gep]], i32 1
; CHECK: [[load1:%[^ ]+]] = load i8, ptr addrspace(2) [[gep1]], align 1
; CHECK: [[gep2:%[^ ]+]] = getelementptr i8, ptr addrspace(2) [[gep]], i32 2
; CHECK: [[load2:%[^ ]+]] = load i8, ptr addrspace(2) [[gep2]], align 1
; CHECK: [[gep3:%[^ ]+]] = getelementptr i8, ptr addrspace(2) [[gep]], i32 3
; CHECK: [[load3:%[^ ]+]] = load i8, ptr addrspace(2) [[gep3]], align 1
; CHECK: [[insert0:%[^ ]+]] = insertelement <4 x i8> poison, i8 [[load0]], i32 0
; CHECK: [[insert1:%[^ ]+]] = insertelement <4 x i8> [[insert0]], i8 [[load1]], i32 1
; CHECK: [[insert2:%[^ ]+]] = insertelement <4 x i8> [[insert1]], i8 [[load2]], i32 2
; CHECK: [[insert3:%[^ ]+]] = insertelement <4 x i8> [[insert2]], i8 [[load3]], i32 3
; CHECK: bitcast <4 x i8> [[insert3]] to i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in, i32 %n) {
entry:
  %0 = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i8] } zeroinitializer)
  %1 = getelementptr { [0 x i8] }, ptr addrspace(2) %0, i32 0
  %2 = load i32, ptr addrspace(2) %1, align 4
  ret void
}

declare ptr addrspace(2) @_Z14clspv.resource.2(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, { [0 x i8] } %6)
