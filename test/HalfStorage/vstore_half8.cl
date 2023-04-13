// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float8 b, int c) {
    vstore_half8(b, c, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK: [[b01:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b23:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b45:%[^ ]+]] = OpCompositeConstruct [[float2]]
// CHECK: [[b67:%[^ ]+]] = OpCompositeConstruct [[float2]]

// CHECK: [[b01f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b01]]
// CHECK: [[b23f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b23]]
// CHECK: [[b45f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b45]]
// CHECK: [[b67f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b67]]

// CHECK: [[b0123f:%[^ ]+]] = OpCompositeConstruct [[uint4]] [[b01f]] [[b23f]]

// CHECK-64: [[addr0:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]]
// CHECK-32: [[addr0:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]]
// CHECK: OpStore [[addr0]] [[b0123f]]
