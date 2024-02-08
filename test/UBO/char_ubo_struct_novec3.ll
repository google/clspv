; RUN: clspv-opt -constant-args-ubo %s -o %t.ll -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,in,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 2
; CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 4
; CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 8
; CHECK-DAG: OpMemberDecorate [[s]] 4 Offset 12
; CHECK: OpDecorate [[rta:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: OpDecorate [[out:%[0-9a-zA-Z_]+]] Binding 0
; CHECK-DAG: OpDecorate [[out]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[in]] NonWritable
; CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
; CHECK-DAG: [[char2:%[0-9a-zA-Z_]+]] = OpTypeVector [[char]] 2
; CHECK-DAG: [[char4:%[0-9a-zA-Z_]+]] = OpTypeVector [[char]] 4
; CHECK: [[s]] = OpTypeStruct [[char]] [[char2]] [[char4]] [[char4]] [[int]]
; CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
; CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_4096]]
; CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
; CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
; CHECK-DAG: [[rta]] = OpTypeRuntimeArray [[s]]
; CHECK-DAG: [[ssbo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[rta]]
; CHECK-DAG: [[ssbo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[ssbo_block]]
; CHECK-DAG: [[out]] = OpVariable [[ssbo_ptr]] StorageBuffer
; CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 4 %out, ptr addrspace(2) nocapture readonly align 4 %in) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] } zeroinitializer)
  %5 = getelementptr { [4096 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] }, ptr addrspace(2) %1, i32 0, i32 0, i32 0, i32 3
  %6 = load <4 x i8>, ptr addrspace(2) %5, align 4
  %7 = getelementptr { [0 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0, i32 3
  store <4 x i8> %6, ptr addrspace(1) %7, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x { i8, <2 x i8>, <4 x i8>, <4 x i8>, i32 }] })


!14 = !{i32 2}

