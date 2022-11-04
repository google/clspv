// RUN: clspv %target -int8 -constant-args-ubo -inline-entry-points %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  char a;
  char2 b;
  char3 c;
  char4 d;
  int pad; // necessary to get up to 16 byte size
} S;

kernel void foo(global S* out, constant S* in) {
  out->d = in->d;
}

//      MAP: kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,in,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo

// CHECK-DAG: OpMemberDecorate [[s:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[s]] 1 Offset 2
// CHECK-DAG: OpMemberDecorate [[s]] 2 Offset 4
// CHECK-DAG: OpMemberDecorate [[s]] 3 Offset 8
// CHECK-DAG: OpMemberDecorate [[s]] 4 Offset 12
// CHECK: OpDecorate [[rta:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: OpDecorate [[out:%[0-9a-zA-Z_]+]] Binding 0
// CHECK-DAG: OpDecorate [[out]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[in:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: OpDecorate [[in]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[in]] NonWritable
// CHECK: OpDecorate [[ubo_array:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK-DAG: [[int:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char2:%[0-9a-zA-Z_]+]] = OpTypeVector [[char]] 2
// CHECK-DAG: [[char4:%[0-9a-zA-Z_]+]] = OpTypeVector [[char]] 4
// CHECK: [[s]] = OpTypeStruct [[char]] [[char2]] [[char4]] [[char4]] [[int]]
// CHECK-DAG: [[int_4096:%[0-9a-zA-Z_]+]] = OpConstant [[int]] 4096
// CHECK-DAG: [[ubo_array]] = OpTypeArray [[s]] [[int_4096]]
// CHECK-DAG: [[ubo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[ubo_array]]
// CHECK-DAG: [[ubo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[ubo_block]]
// CHECK-DAG: [[rta]] = OpTypeRuntimeArray [[s]]
// CHECK-DAG: [[ssbo_block:%[0-9a-zA-Z_]+]] = OpTypeStruct [[rta]]
// CHECK-DAG: [[ssbo_ptr:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[ssbo_block]]
// CHECK-DAG: [[out]] = OpVariable [[ssbo_ptr]] StorageBuffer
// CHECK-DAG: [[in]] = OpVariable [[ubo_ptr]] Uniform
