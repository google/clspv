// Test for https://github.com/google/clspv/issues/15

kernel void foo(global uchar4* A, int n) {
 *A = (uchar4)(1,2,(uchar)n,4);
}

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[uint255:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 255
// CHECK: [[uint3mask:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16908292
// CHECK: [[uint16:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16


// CHECK: [[load:%[_a-zA-Z0-9]+]] = OpLoad [[uint]] {{%[_0-9a-zA-Z]+}}
// CHECK: [[conv:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[load]] [[uint255]]
// CHECK: [[shift:%[_a-zA-Z0-9]+]] = OpShiftLeftLogical [[uint]] [[uint255]] [[uint16]]
// CHECK: [[not:%[_a-zA-Z0-9]+]] = OpNot [[uint]] [[shift]]
// CHECK: [[and:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[uint3mask]] [[not]]
// CHECK: [[shift2:%[_a-zA-Z0-9]+]] = OpShiftLeftLogical [[uint]] [[conv]] [[uint16]]
// CHECK: [[or:%[_a-zA-Z0-9]+]] = OpBitwiseOr [[uint]] [[and]] [[shift2]]
// CHECK: OpStore {{%[_0-9a-zA-Z]+}} [[or]]
