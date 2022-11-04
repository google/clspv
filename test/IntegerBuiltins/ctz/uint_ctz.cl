// RUN: clspv %target %s -o %t.spv --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void uint_ctz(global uint* out, global uint* in) {
  *out = ctz(*in);
}

// CHECK: [[ext:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_n1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4294967295
// CHECK-DAG: [[uint_32:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 32
// CHECK: [[find_lsb:%[a-zA-Z0-9_]+]] = OpExtInst [[uint]] [[ext]] FindILsb
// CHECK: [[cmp:%[a-zA-Z0-9_]+]] = OpIEqual {{.*}} [[find_lsb]] [[uint_n1]]
// CHECK: OpSelect [[uint]] [[cmp]] [[uint_32]] [[find_lsb]]
