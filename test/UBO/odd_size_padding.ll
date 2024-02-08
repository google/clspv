; RUN: clspv-opt -constant-args-ubo %s -o %t -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm

; CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 1
; CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 16
; CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 20
; CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
; CHECK: OpDecorate [[in]] NonWritable
; CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 32
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
; CHECK: [[s]] = OpTypeStruct [[char]] [[char]] [[int]] [[char]]
; CHECK-DAG: [[int_2048:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2048
; CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_2048]]
; CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
; CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
; CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { i8, [15 x i8], i32, [12 x i8] }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %out, ptr addrspace(2) nocapture readonly align 16 %in, { i32 } %podargs) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.S] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [2048 x %struct.S] } zeroinitializer)
  %2 = getelementptr { [2048 x %struct.S] }, ptr addrspace(2) %1, i32 0, i32 0, i32 0, i32 2
  %3 = load i32, ptr addrspace(2) %2, align 16
  %4 = getelementptr { [0 x %struct.S] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0, i32 2
  store i32 %3, ptr addrspace(1) %4, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [2048 x %struct.S] })

!14 = !{i32 2}
