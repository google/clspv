; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int]]
; CHECK: OpPhi [[ptr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in) {
entry:
  %res = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
  %gep = getelementptr { [0 x i32] }, ptr addrspace(1) %res, i32 0, i32 0, i32 0
  br label %loop

loop:
  %phi = phi ptr addrspace(1) [ %gep, %entry ], [ %p1, %next ]
  %n = phi i32 [ 0, %entry ], [ %add, %next ]
  %cmp = icmp eq i32 %n, 0
  br i1 %cmp, label %next, label %exit

next:
  %p1 = getelementptr i32, ptr addrspace(1) %phi, i32 1
  %add = add i32 %n, 1
  br label %loop

exit:
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })
