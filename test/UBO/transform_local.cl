// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -int8=0 -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -int8=0 -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// TODO(#1292)
// XFAIL: *

typedef struct {
  int x __attribute__((aligned(16)));
} data_type;

__kernel void foo(__global data_type* data, __constant data_type* c_arg, __local data_type* l_arg) {
  data[2].x = c_arg[2].x + l_arg[2].x;
}

// Most important thing here is the arrayElemSize check for the pointer-to-local arg.
//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
// MAP-NEXT: kernel,foo,arg,l_arg,argOrdinal,2,argKind,local,arrayElemSize,16,arrayNumElemSpecId,3

// CHECK-DAG: OpMemberDecorate [[data_type:%[0-9a-zA-Z_]+]] 1 Offset 4
// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_arg:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[c_arg]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[spec_id:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-NOT: OpExtension
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[data_type]] = OpTypeStruct [[int]] [[int]]
// CHECK-DAG: [[runtime]] = OpTypeRuntimeArray [[data_type]]
// CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK-DAG: [[ubo_array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[int_4096]]
// CHECK-DAG: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
// CHECK-DAG: [[c_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
// CHECK-DAG: [[size1:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
// CHECK-DAG: [[size2:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
// CHECK-DAG: [[size3:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
// CHECK-DAG: [[size:%[0-9a-zA-Z_]+]] = OpSpecConstant [[int]] 1
// CHECK-DAG: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[data_type]] [[size]]
// CHECK-DAG: [[l_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[array]]
// CHECK-DAG: [[c_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
// CHECK-DAG: [[l_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[int]]
// CHECK-DAG: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
// CHECK-64-DAG: [[long:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-64-DAG: [[long_two:%[0-9a-zA-Z_]+]] = OpConstant [[long]] 2
// CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
// CHECK: [[c_arg]] = OpVariable [[c_arg_ptr]] Uniform
// CHECK: [[l_arg:%[0-9a-zA-Z_]+]] = OpVariable [[l_arg_ptr]] Workgroup
// CHECK: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[two]] [[zero]]
// CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_arg_gep]]
// CHECK-64: [[l_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[l_arg_ele_ptr]] [[l_arg]] [[long_two]] [[zero]]
// CHECK-32: [[l_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[l_arg_ele_ptr]] [[l_arg]] [[two]] [[zero]]
// CHECK: [[l_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[l_arg_gep]]
// CHECK: [[add:%[0-9a-zA-Z_]+]] = OpIAdd [[int]] [[l_load]] [[c_load]]
// CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[two]] [[zero]]
// CHECK: OpStore [[data_gep]] [[add]]
