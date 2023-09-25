; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; Nothing should have changed
; CHECK: [[call:%[^ ]+]] = call ptr addrspace(2) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i8] } zeroinitializer)
; CHECK: [[gep:%[^ ]+]] = getelementptr { [0 x i8] }, ptr addrspace(2) [[call]], i32 0
; CHECK: load i32, ptr addrspace(2) [[gep]], align 4

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
