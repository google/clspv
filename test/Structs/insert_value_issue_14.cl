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


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[struct:%[_a-zA-Z0-9]+]] = OpTypeStruct [[uint]] [[uint]] [[uint]]

// With undef mapping to 0 byte, (undef,1,2,3) maps to 66051.
// CHECK-DAG: [[theconst:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 66051
// CHECK-DAG: [[int_65280:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 65280
// CHECK-DAG: [[int_16711680:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16711680
// CHECK-DAG: [[int_4278190080:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4278190080
// CHECK-DAG: [[int_255:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 255

// no longer checked: [[undef_struct:%[_a-zA-Z0-9]+]] = OpUndef [[struct]]

// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[uint]] %{{.*}} [[int_255]]
// CHECK: [[or1:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[uint]] %{{.*}} [[and]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[uint]] [[theconst]] [[int_65280]]
// CHECK: [[or2:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[uint]] [[or1]] [[and]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[uint]] [[theconst]] [[int_16711680]]
// CHECK: [[or3:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[uint]] [[or2]] [[and]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[uint]] [[theconst]] [[int_4278190080]]
// CHECK: OpBitwiseOr [[uint]] [[or3]] [[and]]
