// RUN: clspv -constant-args-ubo -inline-entry-points %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void foo(__global int* data, __constant int* c) {
  *data = *c;
}

// CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
// CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[var]] Binding 1
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[runtime:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[int]]
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[runtime]]
// CHECK: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
// CHECK: [[ptr_int:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[var]] = OpVariable [[ptr]] Uniform
// CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_int]] [[var]] [[zero]] [[zero]]
// CHECK: OpLoad [[int]] [[gep]]
