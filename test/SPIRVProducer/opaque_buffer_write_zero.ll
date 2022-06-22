; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[int]]
; CHECK-DAG: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[array]]
; CHECK-DAG: [[block_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
; CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int]]
; CHECK-DAG: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
; CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[block_ptr]] StorageBuffer
; CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[zero]]
; CHECK: OpStore [[gep]] [[zero]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  store i32 0, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })


!8 = !{i32 2}

