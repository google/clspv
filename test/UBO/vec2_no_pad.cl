// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Natural alignment don't lead to LLVM inserting packing so this is ok.
typedef struct {
  int x;
  int2 y;
} data_type;

__kernel void foo(__global data_type* d, __constant data_type* c) {
  d->y = c->y;
}

//      MAP: kernel,foo,arg,d,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 8
// CHECK-DAG: OpMemberDecorate [[struct:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpDecorate [[var:%[0-9a-zA-Z_]+]] NonWritable
// CHECK-DAG: OpDecorate [[var]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[var]] Binding 1
// CHECK: OpDecorate [[array:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[int2:%[0-9a-zA-Z_]+]] = OpTypeVector [[int]] 2
// CHECK: [[s]] = OpTypeStruct [[int]] [[int2]]
// CHECK: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK: [[array]] = OpTypeArray [[s]] [[int_4096]]
// CHECK: [[struct:%[0-9a-zA-Z_]+]] = OpTypeStruct [[array]]
// CHECK: [[ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[struct]]
// CHECK: [[ptr_int2:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[int2]]
// CHECK: [[zero:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 0
// CHECK: [[one:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 1
// CHECK: [[var]] = OpVariable [[ptr]] Uniform
// CHECK: [[gep:%[0-9a-zA-Z_]+]] = OpAccessChain [[ptr_int2]] [[var]] [[zero]] [[zero]] [[one]]
// CHECK: OpLoad [[int2]] [[gep]]
