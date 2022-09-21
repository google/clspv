// RUN: clspv %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 --enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global short3* a, global short3* b) {
  *a = popcount(*b);
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK: [[short4:%[a-zA-Z0-9_]+]] = OpTypeVector [[short]] 4
// CHECK: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[short4]]
// CHECK: [[convert:%[a-zA-Z0-9_]+]] = OpUConvert [[int4]] [[ld]]
// CHECK: [[cnt:%[a-zA-Z0-9_]+]] = OpBitCount [[int4]] [[convert]]
// CHECK: [[res:%[a-zA-Z0-9_]+]] = OpUConvert [[short4]] [[cnt]]
// CHECK: OpStore {{.*}} [[res]]
