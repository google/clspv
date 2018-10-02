// RUN: clspv -constant-args-ubo -inline-entry-points %s -S -o %t.spvasm -descriptormap=%t.map
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The data_type struct translates as { i32, [12 x i8] } which is transformed
// to { i32, i32 }
typedef struct {
  int x __attribute((aligned(16)));
} data_type;

__kernel void foo(__global data_type *data, __constant data_type *c_arg) {
  data->x = c_arg->x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: OpMemberDecorate [[data_type:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[data_type]] 1 Offset 4
// CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_arg:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[c_arg]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_arg]] NonWritable
//     CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
//     CHECK: [[data_type]] = OpTypeStruct [[int]] [[int]]
//     CHECK: [[runtime]] = OpTypeRuntimeArray [[data_type]]
//     CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
//     CHECK: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
//     CHECK: [[c_arg_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
//     CHECK: [[c_arg_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
//     CHECK: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
//     CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
//     CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
//     CHECK: [[c_arg]] = OpVariable [[c_arg_ptr]] Uniform
//     CHECK: [[c_arg_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_arg_ele_ptr]] [[c_arg]] [[zero]] [[zero]] [[zero]]
//     CHECK: [[load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_arg_gep]]
//     CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[zero]] [[zero]]
//     CHECK: OpStore [[data_gep]] [[load]]
