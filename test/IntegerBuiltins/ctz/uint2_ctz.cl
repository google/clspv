// RUN: clspv %s -o %t.spv --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void uint2_ctz(global uint2* out, global uint2* in) {
  *out = ctz(*in);
}

// CHECK: [[ext:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_n1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4294967295
// CHECK-DAG: [[uint_32:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 32
// CHECK-DAG: [[uint2_n1:%[a-zA-Z0-9_]+]] = OpConstantComposite [[uint2]] [[uint_n1]] [[uint_n1]]
// CHECK-DAG: [[uint2_32:%[a-zA-Z0-9_]+]] = OpConstantComposite [[uint2]] [[uint_32]] [[uint_32]]
// CHECK: [[find_lsb:%[a-zA-Z0-9_]+]] = OpExtInst [[uint2]] [[ext]] FindILsb
// CHECK: [[cmp:%[a-zA-Z0-9_]+]] = OpIEqual {{.*}} [[find_lsb]] [[uint2_n1]]
// CHECK: OpSelect [[uint2]] [[cmp]] [[uint2_32]] [[find_lsb]]

