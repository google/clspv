// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float2 *dst) {
    *dst = vload_half2(b, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1

// CHECK-DAG: [[uint_array:%[^ ]+]] = OpTypeRuntimeArray [[uint]]
// CHECK-DAG: [[uint_ptr:%[^ ]+]] = OpTypeStruct [[uint_array]]
// CHECK-DAG: [[global_uint_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_uint_ptr]] StorageBuffer

// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK-64: [[addr:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[b_long]]
// CHECK-32: [[addr:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]]
// CHECK: [[ld:%[^ ]+]] = OpLoad [[uint]] [[addr]]

// CHECK: [[val:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[ld]]
// CHECK: OpStore {{.*}} [[val]]
