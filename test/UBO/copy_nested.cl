// RUN: clspv %target -constant-args-ubo -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct inner {
  float4 x;
} inner;

typedef struct outer {
  inner x;
} outer;

__kernel void foo(__global outer* data, __constant outer* c) {
  data->x.x = c->x.x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
// CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[var]] Binding 1
// CHECK: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: [[float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[0-9a-zA-Z_]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[inner:%[0-9a-zA-Z_]+]] = OpTypeStruct [[float4]]
// CHECK-DAG: [[outer:%[0-9a-zA-Z_]+]] = OpTypeStruct [[inner]]
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK-DAG: [[array]] = OpTypeArray [[outer]] [[int_4096]]
// CHECK-DAG: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK-DAG: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
// CHECK-DAG: [[ptr_float4:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[float4]]
// CHECK-DAG: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[var]] = OpVariable [[ptr]] Uniform
// CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_float4]] [[var]] [[zero]] [[zero]] [[zero]]
// CHECK: OpLoad [[float4]] [[gep]]
