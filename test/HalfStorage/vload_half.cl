// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float *dst) {
    *dst = vload_half(b, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[ushort]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK-32: [[addr:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint0]]
// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK-64: [[addr:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint0]] [[b_long]]
// CHECK: [[valh:%[^ ]+]] = OpLoad [[ushort]] [[addr]]
// CHECK: [[vali32:%[^ ]+]] = OpUConvert [[uint]] [[valh]]
// CHECK: [[valf2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[vali32]]
// CHECK: [[val:%[^ ]+]] = OpCompositeExtract [[float]] [[valf2]] 0
// CHECK: OpStore {{.*}} [[val]]
