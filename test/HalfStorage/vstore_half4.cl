// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float4 b, int c) {
    vstore_half4(b, c, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-32-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3{{$}}

// CHECK: [[val1_int:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: [[val2_int:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16

// CHECK: [[construct:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[val1_int]] [[val2_int]]

// CHECK-64: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]]
// CHECK-32: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]]
// CHECK: OpStore [[gep]] [[construct]]
