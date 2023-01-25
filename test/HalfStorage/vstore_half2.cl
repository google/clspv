// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float2 b, int c) {
    vstore_half2(b, c, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1


// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float2]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK-64: [[c_long:%[^ ]+]] = OpSConvert [[ulong]] [[c]]
// CHECK: [[pack:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b]]
// CHECK-64: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint0]] [[c_long]]
// CHECK-32: [[gep:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint0]] [[c]]
// CHECK: OpStore [[gep]] [[pack]]
