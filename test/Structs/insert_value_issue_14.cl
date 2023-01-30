// Test for https://github.com/google/clspv/issues/14
// An undef for an aggregate was not being generated because
// of an early return in constant generation when we generate
// the <4 x i8> constant.
// UPDATE: Rewriting constant composites makes the OpUndef struct go away.

// Also test https://github.com/google/clspv/issues/36 for
// generation of the <4 x i8> constant including an undef component.

typedef struct {
  int a, b, c, d;
} S;

S convert(int n) {
  S s = {n, n, n, n};
  return s;
}

kernel void foo(global S* A, global uchar4* B, int n) {
 *B = (uchar4)((uchar)n,1,2,3);
 *A = convert(10);
}

// RUN: clspv %target %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// TODO(#1004): pointer bitcast issue
// XFAIL: *


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[struct:%[_a-zA-Z0-9]+]] = OpTypeStruct [[uint]] [[uint]] [[uint]]

 
// With undef mapping to a 0 byte sequence, (undef,1,2,3) maps to 66051.
// CHECK-DAG: [[theconst:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 66051
// CHECK-DAG: [[int_255:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 255
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0

// no longer checked: [[undef_struct:%[_a-zA-Z0-9]+]] = OpUndef [[struct]]

// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[uint]] %{{.*}} [[int_255]]
// CHECK: [[mask_255:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical %uint [[int_255]] [[int_0]]
// CHECK: [[mask:%[a-zA-Z0-9_]+]] = OpNot %uint [[mask_255]]
// CHECK: [[otherelems:%[a-zA-Z0-9_]+]] = OpBitwiseAnd %uint [[theconst]] [[mask]]
// CHECK: [[firstelem:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical %uint [[and]] [[int_0]]

// CHECK: OpBitwiseOr [[uint]] [[otherelems]] [[firstelem]]
