; RUN: clspv-opt -constant-args-ubo %s -o %t.ll -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
; CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[var]] Binding 1
; CHECK: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: [[float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
; CHECK-DAG: [[float4:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 4
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
; CHECK-DAG: [[array]] = OpTypeArray [[float4]] [[int_4096]]
; CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
; CHECK-DAG: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
; CHECK-DAG: [[ptr_float4:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[float4]]
; CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
; CHECK: [[var]] = OpVariable [[ptr]] Uniform
; CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_float4]] [[var]] [[zero]] [[zero]]
; CHECK: OpLoad [[float4]] [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x float>] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x <4 x float>] } zeroinitializer)
  %2 = getelementptr { [4096 x <4 x float>] }, ptr addrspace(2) %1, i32 0, i32 0, i32 0
  %3 = load <4 x float>, ptr addrspace(2) %2, align 16
  %4 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  store <4 x float> %3, ptr addrspace(1) %4, align 16
  %5 = getelementptr { [4096 x <4 x float>] }, ptr addrspace(2) %1, i32 0, i32 0, i32 1
  %6 = load <4 x float>, ptr addrspace(2) %5, align 16
  %7 = getelementptr { [0 x <4 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  store <4 x float> %6, ptr addrspace(1) %7, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x float>] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x <4 x float>] })

!14 = !{i32 2}

