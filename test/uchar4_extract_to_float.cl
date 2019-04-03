// Test for https://github.com/google/clspv/issues/55
// Extraction of char values from a uchar4.

// RUN: clspv %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uchar4* IN, global float4* OUT) {
  uchar4 in4 = *IN;
  float4 result;
  result.x = in4.x;
  result.y = in4.y;
  result.z = in4.z;
  result.w = in4.w;
  *OUT = result;
}


// CHECK-DAG: [[float:%[_a-zA-Z0-9]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[_a-zA-Z0-9]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[_a-zA-Z0-9]+]] = OpTypeInt 32 0
// CHECK-NOT: checking barrier
// CHECK-DAG: [[uint_0:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_255:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 255
// CHECK-DAG: [[uint_8:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[uint_16:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_24:%[_a-zA-Z0-9]+]] = OpConstant [[uint]] 24


// There is only one load
// CHECK: [[load:%[_a-zA-Z0-9]+]] = OpLoad [[uint]] {{%[_0-9a-zA-Z]+}}
// CHECK-NOT: OpLoad

// CHECK: [[c0:%[_a-zA-Z0-9]+]] = OpShiftRightLogical [[uint]] [[load]] [[uint_0]]
// CHECK: [[and0:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[c0]] [[uint_255]]
// CHECK: [[f0:%[_a-zA-Z0-9]+]] = OpConvertUToF [[float]] [[and0]]

// CHECK: [[c1:%[_a-zA-Z0-9]+]] = OpShiftRightLogical [[uint]] [[load]] [[uint_8]]
// CHECK: [[and1:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[c1]] [[uint_255]]
// CHECK: [[f1:%[_a-zA-Z0-9]+]] = OpConvertUToF [[float]] [[and1]]

// CHECK: [[c2:%[_a-zA-Z0-9]+]] = OpShiftRightLogical [[uint]] [[load]] [[uint_16]]
// CHECK: [[and2:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[c2]] [[uint_255]]
// CHECK: [[f2:%[_a-zA-Z0-9]+]] = OpConvertUToF [[float]] [[and2]]

// CHECK: [[c3:%[_a-zA-Z0-9]+]] = OpShiftRightLogical [[uint]] [[load]] [[uint_24]]
// CHECK: [[and3:%[_a-zA-Z0-9]+]] = OpBitwiseAnd [[uint]] [[c3]] [[uint_255]]
// CHECK: [[f3:%[_a-zA-Z0-9]+]] = OpConvertUToF [[float]] [[and3]]

// CHECK: [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[float4]] [[f0]] [[f1]] [[f2]] [[f3]]

// CHECK: OpStore {{%[_0-9a-zA-Z]+}} [[construct]]
// CHECK-NOT: OpStore
