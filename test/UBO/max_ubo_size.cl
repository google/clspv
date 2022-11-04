// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv -max-ubo-size=64 -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Checking that -max-ubo-size affects the number of elements in the UBO array.
// Struct alloca size is 32, so expect 2 elements with max size of 64.

typedef struct {
  int x;
  int y __attribute((aligned(16)));
} s;

__kernel void foo(__global s* data, __constant s* c) {
  data->x = c->x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 4
// CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 16
// CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 20
// CHECK-DAG: OpDecorate [[runtime:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK-DAG: OpDecorate [[data:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[data]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[c]] DescriptorSet 0
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[s]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]]
// CHECK: [[runtime]] = OpTypeRuntimeArray [[s]]
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK: [[data_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK: [[int_2:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2
// CHECK: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[s]] [[int_2]]
// CHECK: [[ubo_struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK: [[c_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_struct]]
// CHECK: [[data]] = OpVariable [[data_ptr]] StorageBuffer
// CHECK: [[c]] = OpVariable [[c_ptr]] Uniform

