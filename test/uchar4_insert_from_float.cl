// Test for https://github.com/google/clspv/issues/15

kernel void foo(global uchar4* A, float f) {
 *A = (uchar4)(1,2,(uchar)f,4);
}

// RUN: clspv %target %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv





// This is ok because results ought to be unspecified if the conversion overflows.

// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_255:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 255
// CHECK:  [[_uint_16:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16
// CHECK:  [[_uint_16908292:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16908292
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpConvertFToU [[_uint]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_uint_255]] [[_uint_16]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpNot [[_uint]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_uint_16908292]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_34]] [[_uint_16]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpBitwiseOr [[_uint]] [[_37]] [[_38]]
// CHECK:  OpStore {{.*}} [[_39]]
