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

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-DAG: [[struct:%[_a-zA-Z0-9]+]] = OpTypeStruct [[uint]] [[uint]] [[uint]]

// With undef mapping to 0 byte, (undef,1,2,3) maps to 66051.
// CHECK-DAG: [[theconst:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 66051

// no longer checked: [[undef_struct:%[_a-zA-Z0-9]+]] = OpUndef [[struct]]

// CHECK: OpBitwiseAnd [[uint]] [[theconst]] {{%[_a-zA-Z0-9]+}}
