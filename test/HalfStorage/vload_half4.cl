// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float4 *dst) {
    *dst = vload_half4(b, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3

// CHECK-DAG: [[uint2_array:%[^ ]+]] = OpTypeRuntimeArray [[uint2]]
// CHECK-DAG: [[uint2_ptr:%[^ ]+]] = OpTypeStruct [[uint2_array]]
// CHECK-DAG: [[global_uint2_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint2_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_uint2_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK-64: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[b_long]]
// CHECK-32: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[b]]
// CHECK: [[val0:%[^ ]+]] = OpLoad [[uint2]] [[addr0]]

// CHECK: [[val01i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 0
// CHECK: [[val23i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 1

// CHECK: [[val01:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32]]
// CHECK: [[val23:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val23i32]]

// CHECK: [[val:%[^ ]+]] = OpVectorShuffle [[float4]] [[val01]] [[val23]] 0 1 2 3
// CHECK:       OpStore {{.*}} [[val]]
