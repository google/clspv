; RUN: clspv-opt -constant-args-ubo -std430-ubo-layout %s -o %t -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv --uniform-buffer-standard-layout
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,in,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; With std430 layouts in UBO, the padding array ([16 x i8]) can be generated
; with an ArrayStride of 1.
; CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 16
; CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 32
; CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 48
; CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[in]] NonWritable
; CHECK: OpDecorate [[char_array:%[0-9a-zA-Z_]+]] ArrayStride 1
; CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 64
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
; CHECK-DAG: [[int4:%[0-9a-zA-Z_]+]] = OpTypeVector [[int]] 4
; CHECK-DAG: [[int_16:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 16
; CHECK-DAG: [[char_array]] = OpTypeArray [[char]] [[int_16]]
; CHECK: [[s]] = OpTypeStruct [[int4]] [[char_array]] [[int4]] [[int4]]
; CHECK-DAG: [[int_1024:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1024
; CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_1024]]
; CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
; CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
; CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { <4 x i32>, [16 x i8], <4 x i32>, <4 x i32> }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 32 %out, ptr addrspace(2) nocapture readonly align 32 %in) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.S] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [1024 x %struct.S] } zeroinitializer)
  %5 = getelementptr { [1024 x %struct.S] }, ptr addrspace(2) %1, i32 0, i32 0, i32 0, i32 3
  %6 = load <4 x i32>, ptr addrspace(2) %5, align 16
  %7 = getelementptr { [0 x %struct.S] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0, i32 3
  store <4 x i32> %6, ptr addrspace(1) %7, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.S] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [1024 x %struct.S] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!14 = !{i32 2}

