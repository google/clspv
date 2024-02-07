; RUN: clspv-opt %s -o %t -constant-args-ubo -int8=0 -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: OpMemberDecorate [[data_type:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[data_type]] 1 Offset 4
; CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
; CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[c_arg:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[c_arg]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[c_arg]] NonWritable
;     CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
;     CHECK: [[data_type]] = OpTypeStruct [[int]] [[int]]
;     CHECK: [[runtime]] = OpTypeRuntimeArray [[data_type]]
;     CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
;     CHECK: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
;     CHECK: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
;     CHECK: [[ubo_array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[int_4096]]
;     CHECK: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
;     CHECK: [[c_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
;     CHECK: [[c_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
;     CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
;     CHECK: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
;     CHECK: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
;     CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
;     CHECK: [[c_arg]] = OpVariable [[c_arg_ptr]] Uniform
;     CHECK: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[two]] [[zero]]
;     CHECK: [[load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_arg_gep]]
;     CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[two]] [[zero]]
;     CHECK: OpStore [[data_gep]] [[load]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.data_type = type { i32, [12 x i8] }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c_arg, { i32 } %podargs) !clspv.pod_args_impl !14 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.data_type] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x %struct.data_type] } zeroinitializer)
  %5 = getelementptr { [4096 x %struct.data_type] }, ptr addrspace(2) %1, i32 0, i32 0, i32 2, i32 0
  %6 = load i32, ptr addrspace(2) %5, align 16
  %7 = getelementptr { [0 x %struct.data_type] }, ptr addrspace(1) %0, i32 0, i32 0, i32 2, i32 0
  store i32 %6, ptr addrspace(1) %7, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.data_type] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x %struct.data_type] })

!14 = !{i32 2}

