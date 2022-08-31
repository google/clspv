// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[EXT:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[half3:%[a-zA-Z0-9_]+]] = OpTypeVector [[half]] 3
// CHECK-DAG: [[undefh4:%[a-zA-Z0-9_]+]] = OpUndef [[half4]]
// CHECK-DAG: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld2:%[a-zA-Z0-9_]+]] = OpLoad [[half4]]
// CHECK-DAG: [[ld0_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[half3]] [[ld0]] [[undefh4]] 0 1 2
// CHECK-DAG: [[ld1_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[half3]] [[ld1]] [[undefh4]] 0 1 2
// CHECK-DAG: [[ld2_shuffle:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[half3]] [[ld2]] [[undefh4]] 0 1 2
// CHECK: OpExtInst [[half3]] [[EXT]] FMix [[ld0_shuffle]] [[ld1_shuffle]] [[ld2_shuffle]]


#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half3* in, global half3* out) {
  *out = mix(in[0], in[1], in[2]);
}

