// RUN: clspv %s -o %t.spv -int8 -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar3* a, global uchar3* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char4]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int4]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int4]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[char4]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
