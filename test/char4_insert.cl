// Test for https://github.com/google/clspv/issues/15

kernel void foo(global uchar4* A, int n) {
 *A = (uchar4)(1,2,(uchar)n,4);
}

// RUN: clspv %target %s -o %t.spv -int8=0 --spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_255:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 255
// CHECK:  [[_uint_16:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16
// CHECK:  [[_uint_16908292:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16908292
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_32]] [[_uint_255]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_uint_255]] [[_uint_16]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpNot [[_uint]] [[_34]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_uint_16908292]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_33]] [[_uint_16]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpBitwiseOr [[_uint]] [[_36]] [[_37]]
// CHECK:  OpStore {{.*}} [[_38]]
