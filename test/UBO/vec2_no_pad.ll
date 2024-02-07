; RUN: clspv-opt %s -o %t -constant-args-ubo -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,d,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 8
; CHECK-DAG: OpMemberDecorate [[struct:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
; CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[var]] Binding 1
; CHECK: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK: [[int2:%[0-9a-zA-Z_]+]] = OpTypeVector [[int]] 2
; CHECK: [[s]] = OpTypeStruct [[int]] [[int2]]
; CHECK: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
; CHECK: [[array]] = OpTypeArray [[s]] [[int_4096]]
; CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
; CHECK: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
; CHECK: [[ptr_int2:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int2]]
; CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
; CHECK: [[one:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1
; CHECK: [[var]] = OpVariable [[ptr]] Uniform
; CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_int2]] [[var]] [[zero]] [[zero]] [[one]]
; CHECK: OpLoad [[int2]] [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.data_type = type { i32, <2 x i32> }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 8 %d, ptr addrspace(2) nocapture readonly align 8 %c) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.data_type] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x %struct.data_type] } zeroinitializer)
  %5 = getelementptr { [4096 x %struct.data_type] }, ptr addrspace(2) %1, i32 0, i32 0, i32 0, i32 1
  %6 = load <2 x i32>, ptr addrspace(2) %5, align 8
  %7 = getelementptr { [0 x %struct.data_type] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0, i32 1
  store <2 x i32> %6, ptr addrspace(1) %7, align 8
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.data_type] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x %struct.data_type] })

!14 = !{i32 2}

