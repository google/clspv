// RUN: clspv -constant-args-ubo -inline-entry-points %s -S -o %t.spvasm -descriptormap=%t.map
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void foo(__global int* data, __constant int* c) {
  *data = *c;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
// CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[var]] Binding 1
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[int_16384:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 16384
// CHECK: [[array:%[0-9a-zA-Z_]+]] = OpTypeArray [[int]] [[int_16384]]
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
// CHECK: [[ptr_int:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int]]
// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[var]] = OpVariable [[ptr]] Uniform
// CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_int]] [[var]] [[zero]] [[zero]]
// CHECK: OpLoad [[int]] [[gep]]
