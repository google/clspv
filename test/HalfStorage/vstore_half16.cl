// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float16 b, int c) {
    vstore_half16(b, c, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_15:%[^ ]+]] = OpConstant [[uint]] 15
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint_4:%[^ ]+]] = OpConstant [[uint]] 4{{$}}
// CHECK-32-DAG: [[uint_5:%[^ ]+]] = OpConstant [[uint]] 5
// CHECK-64-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-64-DAG: [[ulong_4:%[^ ]+]] = OpConstant [[ulong]] 4
// CHECK-64-DAG: [[ulong_5:%[^ ]+]] = OpConstant [[ulong]] 5

// CHECK: [[b01:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b23:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b45:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b67:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b89:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b1011:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b1213:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b1415:%[^ ]+]] = OpCompositeConstruct [[float2]]

// CHECK: [[b01f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b01]]
// CHECK: [[b23f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b23]]
// CHECK: [[b45f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b45]]
// CHECK: [[b67f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b67]]
// CHECK: [[b89f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b89]]
// CHECK: [[b1011f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1011]]
// CHECK: [[b1213f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1213]]
// CHECK: [[b1415f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1415]]

// CHECK: [[val0:%[^ ]+]] = OpCompositeConstruct [[uint4]] [[b01f]] [[b23f]] [[b45f]] [[b67f]]
// CHECK: [[val1:%[^ ]+]] = OpCompositeConstruct [[uint4]] [[b89f]] [[b1011f]] [[b1213f]] [[b1415f]]

// CHECK-64: [[shl_:%[^ ]+]] = OpShiftLeftLogical [[ulong]] {{.*}} [[ulong_5]]
// CHECK-64: [[shl:%[^ ]+]] = OpShiftRightLogical [[ulong]] {{.*}} [[ulong_4]]
// CHECK-32: [[shl_:%[^ ]+]] = OpShiftLeftLogical [[uint]] {{.*}} [[uint_5]]
// CHECK-32: [[shl:%[^ ]+]] = OpShiftRightLogical [[uint]] {{.*}} [[uint_4]]
// CHECK: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[shl]]
// CHECK: OpStore [[gep]] [[val0]]

// CHECK-64: [[or:%[^ ]+]] = OpIAdd [[ulong]] [[shl]] [[ulong_1]]
// CHECK-32: [[or:%[^ ]+]] = OpIAdd [[uint]] [[shl]] [[uint_1]]
// CHECK: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[or]]
// CHECK: OpStore [[gep]] [[val1]]

