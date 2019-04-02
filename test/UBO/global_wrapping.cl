// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int x;
  int y __attribute((aligned(16)));
} inner;

typedef struct {
  inner i[2];
} outer;

__kernel void foo(__global outer* data, __constant inner* c) {
  data->i[0].x = c->x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpMemberDecorate [[inner:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[inner]] 1 Offset 4
// CHECK-DAG: OpMemberDecorate [[inner]] 2 Offset 16
// CHECK-DAG: OpMemberDecorate [[inner]] 3 Offset 20
// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 64
// CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[c]] DescriptorSet 0
// CHECK: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK: OpDecorate [[inner_array:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[inner]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]]
// CHECK: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
// CHECK: [[array]] = OpTypeArray [[inner]] [[two]]
// CHECK: [[outer:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK: [[runtime]] = OpTypeRuntimeArray [[outer]]
// CHECK: [[block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK: [[int_2048:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2048
// CHECK: [[inner_array]] = OpTypeArray [[inner]] [[int_2048]]
// CHECK: [[c_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[inner_array]]
// CHECK: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[c_struct]]
// CHECK: [[c_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
// CHECK: [[c]] = OpVariable [[c_ptr]] Uniform
// CHECK: [[c_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_ele_ptr]] [[c]] [[zero]] [[zero]] [[zero]]
// CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_gep]]
// CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] [[zero]] [[zero]] [[zero]]
// CHECK: OpStore [[data_gep]] [[c_load]]

