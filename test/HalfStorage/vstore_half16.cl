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
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-64-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract {{.*}} {{.*}} 0

// CHECK: [[b0:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK: [[b1:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 1
// CHECK: [[b2:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 2
// CHECK: [[b3:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 3
// CHECK: [[b4:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 4
// CHECK: [[b5:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 5
// CHECK: [[b6:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 6
// CHECK: [[b7:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 7
// CHECK: [[b8:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 8
// CHECK: [[b9:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 9
// CHECK: [[b10:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 10
// CHECK: [[b11:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 11
// CHECK: [[b12:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 12
// CHECK: [[b13:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 13
// CHECK: [[b14:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 14
// CHECK: [[b15:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 15

// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1
// CHECK-64: [[c_long:%[^ ]+]] = OpSConvert [[ulong]] [[c]]

// CHECK: [[b01:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b0]] [[b1]]
// CHECK: [[b23:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b2]] [[b3]]
// CHECK: [[b45:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b4]] [[b5]]
// CHECK: [[b67:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b6]] [[b7]]
// CHECK: [[b89:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b8]] [[b9]]
// CHECK: [[b1011:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b10]] [[b11]]
// CHECK: [[b1213:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b12]] [[b13]]
// CHECK: [[b1415:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b14]] [[b15]]

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

// CHECK-64: [[shl:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[c_long]] [[ulong_1]]
// CHECK-32: [[shl:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint_1]]
// CHECK: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[shl]]
// CHECK: OpStore [[gep]] [[val0]]

// CHECK-64: [[or:%[^ ]+]] = OpBitwiseOr [[ulong]] [[shl]] [[ulong_1]]
// CHECK-32: [[or:%[^ ]+]] = OpBitwiseOr [[uint]] [[shl]] [[uint_1]]
// CHECK: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[or]]
// CHECK: OpStore [[gep]] [[val1]]

