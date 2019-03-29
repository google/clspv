// RUN: clspv -int8 -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t.map
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Prior to #279 this would produce a [16 x i8] padding array.
typedef struct {
  int4 a;
  int4 b __attribute__((aligned(32)));
  int4 c;
} S;

kernel void foo(global S* out, constant S* in) {
  out->c = in->c;
}

//      MAP: kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,in,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 16
// CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 32
// CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 48
// CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[in]] NonWritable
// CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 64
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[int4:%[0-9a-zA-Z_]+]] = OpTypeVector [[int]] 4
// CHECK: [[s]] = OpTypeStruct [[int4]] [[char]] [[int4]] [[int4]]
// CHECK-DAG: [[int_1024:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1024
// CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_1024]]
// CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
// CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
// CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform
