// RUN: clspv -int8 -constant-args-ubo -inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  char a;
  int b __attribute__((aligned(16)));
} S;

 kernel void foo(global S* out, constant S* in) {
  out->b = in->b;
}

// CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 1
// CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 16
// CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 20
// CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
// CHECK: OpDecorate [[in]] NonWritable
// CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 32
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK: [[s]] = OpTypeStruct [[char]] [[char]] [[int]] [[char]]
// CHECK-DAG: [[int_2048:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 2048
// CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_2048]]
// CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
// CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
// CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform
