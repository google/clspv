// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void add_sat_uint(global uint* out, global uint* a, global uint* b) {
  *out = add_sat(*a, *b);
}

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[carry_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[uint]] [[uint]]
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_max:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4294967295
// CHECK: [[add:%[a-zA-Z0-9_]+]] = OpIAddCarry [[carry_struct]]
// CHECK: [[ex0:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uint]] [[add]] 0
// CHECK: [[ex1:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uint]] [[add]] 1
// CHECK: [[cmp:%[a-zA-Z0-9_]+]] = OpIEqual [[bool]] [[ex1]] [[uint_0]]
// CHECK: OpSelect [[uint]] [[cmp]] [[ex0]] [[uint_max]]
