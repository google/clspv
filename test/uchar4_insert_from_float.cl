// Test for https://github.com/google/clspv/issues/15

kernel void foo(global uchar4* A, float f) {
 *A = (uchar4)(1,2,(uchar)f,4);
}

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK: [[float:%[_a-zA-Z0-9]+]] = OpTypeFloat 32
// CHECK: [[uint3mask:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16908292
// CHECK: [[uint255:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 255
// CHECK: [[uint16:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16


// CHECK: [[load:%[_a-zA-Z0-9]+]] = OpLoad [[float]] {{%[_0-9a-zA-Z]+}}

// This is ok because results ought to be unspecified if the conversion overflows.
// CHECK: [[conv:%[_a-zA-Z0-9]+]] = OpConvertFToU [[uint]] [[load]]

// CHECK-NEXT: [[shift:%[_a-zA-Z0-9]+]] = OpShiftLeftLogical [[uint]] [[uint255]] [[uint16]]
// CHECK-NEXT: [[not:%[_a-zA-Z0-9]+]] = OpNot [[uint]] [[shift]]
// CHECK-NEXT: [[and:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[uint3mask]] [[not]]
// CHECK-NEXT: [[shift2:%[_a-zA-Z0-9]+]] = OpShiftLeftLogical [[uint]] [[conv]] [[uint16]]
// CHECK-NEXT: [[or:%[_a-zA-Z0-9]+]] = OpBitwiseOr [[uint]] [[and]] [[shift2]]
// CHECK-NEXT: OpStore {{%[_0-9a-zA-Z]+}} [[or]]
