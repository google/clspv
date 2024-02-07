; RUN: clspv-opt -constant-args-ubo -int8=0 %s -o %t.ll -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

;      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

; CHECK-DAG: OpMemberDecorate [[inner:%[0-9a-zA-Z_]+]] 0 Offset 0
; CHECK-DAG: OpMemberDecorate [[inner]] 1 Offset 4
; CHECK-DAG: OpMemberDecorate [[inner]] 2 Offset 16
; CHECK-DAG: OpMemberDecorate [[inner]] 3 Offset 20
; CHECK-DAG: OpDecorate [[inner_runtime:%[0-9a-zA-Z_]+]] ArrayStride 32
; CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 64
; CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
; CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[c:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[c]] DescriptorSet 0
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[inner]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]]
; CHECK-DAG: [[inner_runtime]] = OpTypeRuntimeArray [[inner]]
; CHECK-DAG: [[data_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[inner_runtime]]
; CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[data_struct]]
; CHECK-DAG: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
; CHECK-DAG: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[inner]] [[two]]
; CHECK-DAG: [[outer:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
; CHECK-DAG: [[int_1024:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1024
; CHECK-DAG: [[ubo_array:%[0-9a-zA-Z_]+]] = OpTypeArray [[outer]] [[int_1024]]
; CHECK-DAG: [[block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
; CHECK-DAG: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[block]]
; CHECK-DAG: [[c_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
; CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
; CHECK-DAG: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
; CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
; CHECK: [[c]] = OpVariable [[c_ptr]] Uniform
; CHECK: [[c_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_ele_ptr]] [[c]] [[zero]] {{.*}} [[zero]] [[zero]] [[zero]]
; CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_gep]]
; CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] {{.*}}
; CHECK: OpStore [[data_gep]] [[c_load]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.inner = type { i32, [12 x i8], i32, [12 x i8] }
%struct.outer = type { [2 x %struct.inner] }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.inner] } zeroinitializer)
  %1 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [1024 x %struct.outer] } zeroinitializer)
  %2 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %3 = load i32, ptr addrspace(5) %2, align 16
  %4 = getelementptr { [1024 x %struct.outer] }, ptr addrspace(2) %1, i32 0, i32 0, i32 %3, i32 0, i32 0, i32 0
  %5 = load i32, ptr addrspace(2) %4, align 16
  %6 = getelementptr { [0 x %struct.inner] }, ptr addrspace(1) %0, i32 0, i32 0, i32 %3, i32 0
  store i32 %5, ptr addrspace(1) %6, align 16
  %7 = getelementptr { [1024 x %struct.outer] }, ptr addrspace(2) %1, i32 0, i32 0, i32 %3, i32 0, i32 0, i32 2
  %8 = load i32, ptr addrspace(2) %7, align 16
  %9 = getelementptr { [0 x %struct.inner] }, ptr addrspace(1) %0, i32 0, i32 0, i32 %3, i32 2
  store i32 %8, ptr addrspace(1) %9, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.inner] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [1024 x %struct.outer] })

!8 = !{i32 1}

