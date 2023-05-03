// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t2.map
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
  unsigned gid = get_global_id(0);
  data[gid].i[0].x = c[gid].x;
  data[gid].i[0].y = c[gid].y;
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
// CHECK-DAG: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK-DAG: OpDecorate [[inner_array:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[inner]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]]
// CHECK-DAG: [[two:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
// CHECK-DAG: [[array]] = OpTypeArray [[inner]] [[two]]
// CHECK-DAG: [[outer:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK-DAG: [[runtime]] = OpTypeRuntimeArray [[outer]]
// CHECK-DAG: [[block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK-DAG: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK-DAG: [[int_2048:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2048
// CHECK-DAG: [[inner_array]] = OpTypeArray [[inner]] [[int_2048]]
// CHECK-DAG: [[c_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[inner_array]]
// CHECK-DAG: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[c_struct]]
// CHECK-DAG: [[c_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[data_ele_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[int]]
// CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
// CHECK: [[c]] = OpVariable [[c_ptr]] Uniform
// CHECK: [[c_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[c_ele_ptr]] [[c]] [[zero]] {{.*}} [[zero]]
// CHECK: [[c_load:%[0-9a-zA-Z_]+]] = OpLoad [[int]] [[c_gep]]
// CHECK: [[data_gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[data_ele_ptr]] [[data]] [[zero]] {{.*}} [[zero]] [[zero]]
// CHECK: OpStore [[data_gep]] [[c_load]]

