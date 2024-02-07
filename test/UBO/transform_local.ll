; RUN: clspv-opt %s -o %t -constant-args-ubo -int8=0 -producer-out-file %t.spv --passes=ubo-type-transform,spirv-producer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: clspv-reflection %t.spv -o %t.map
; RUN: FileCheck --check-prefix=MAP %s < %t.map

; Most important thing here is the arrayElemSize check for the pointer-to-local arg.
;      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
; MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
; MAP-NEXT: kernel,foo,arg,l_arg,argOrdinal,2,argKind,local,arrayElemSize,16,arrayNumElemSpecId,3

; CHECK-DAG: OpMemberDecorate [[data_type:%[0-9a-zA-Z_]+]] 1 Offset 4
; CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
; CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
; CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[c_arg:%[0-9a-zA-Z_]+]] Binding 1
; CHECK-DAG: OpDecorate [[c_arg]] DescriptorSet 0
; CHECK-DAG: OpDecorate [[spec_id:%[0-9a-zA-Z_]+]] SpecId 3
; CHECK-NOT: OpExtension
; CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[data_type]] = OpTypeStruct [[int]] [[int]]
; CHECK-DAG: [[runtime]] = OpTypeRuntimeArray [[data_type]]
; CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
; CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
; CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
; CHECK-DAG: [[ubo_array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[int_4096]]
; CHECK-DAG: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
; CHECK-DAG: [[c_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
; CHECK-DAG: [[size1:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
; CHECK-DAG: [[size2:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
; CHECK-DAG: [[size3:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
; CHECK-DAG: [[size:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
; CHECK-DAG: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[size]]
; CHECK-DAG: [[l_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[array]]
; CHECK-DAG: [[c_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
; CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
; CHECK-DAG: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
; CHECK-DAG: [[l_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[int]]
; CHECK-DAG: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
; CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
; CHECK: [[c_arg]] = OpVariable [[c_arg_ptr]] Uniform
; CHECK: [[l_arg:%[0-9a-zA-Z_]+]] = OpVariable [[l_arg_ptr]] Workgroup
; CHECK: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[two]] [[zero]]
; CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_arg_gep]]
; CHECK: [[l_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[l_arg_ele_ptr]] [[l_arg]] [[two]] [[zero]]
; CHECK: [[l_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[l_arg_gep]]
; CHECK: [[add:%[0-9a-zA-Z_]+]] = OpIAdd [[int]] [[l_load]] [[c_load]]
; CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[two]] [[zero]]
; CHECK: OpStore [[data_gep]] [[add]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.data_type = type { i32, [12 x i8] }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c_arg, ptr addrspace(3) nocapture readonly align 16 %l_arg) !clspv.pod_args_impl !17 {
entry:
  %0 = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x %struct.data_type] zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x %struct.data_type] } zeroinitializer)
  %2 = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, { [4096 x %struct.data_type] } zeroinitializer)
  %6 = getelementptr { [4096 x %struct.data_type] }, ptr addrspace(2) %2, i32 0, i32 0, i32 2, i32 0
  %7 = load i32, ptr addrspace(2) %6, align 16
  %8 = getelementptr [0 x %struct.data_type], ptr addrspace(3) %0, i32 0, i32 2, i32 0
  %9 = load i32, ptr addrspace(3) %8, align 16
  %add.i = add nsw i32 %9, %7
  %10 = getelementptr { [0 x %struct.data_type] }, ptr addrspace(1) %1, i32 0, i32 0, i32 2, i32 0
  store i32 %add.i, ptr addrspace(1) %10, align 16
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x %struct.data_type] })

declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [4096 x %struct.data_type] })

declare ptr addrspace(9) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x %struct.data_type])

!clspv.next_spec_constant_id = !{!9}
!clspv.spec_constant_list = !{!10}
!_Z20clspv.local_spec_ids = !{!11}

!9 = distinct !{i32 4}
!10 = !{i32 3, i32 3}
!11 = !{ptr @foo, i32 2, i32 3}
!17 = !{i32 2}

