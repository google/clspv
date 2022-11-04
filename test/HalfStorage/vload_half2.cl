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

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half2:%[^ ]+]] = OpTypeVector [[half]] 2
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-64-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]]  1

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK-64: [[bx2:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[b_long]] [[ulong_1]]
// CHECK-32: [[bx2:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[b]] [[uint_1]]
// CHECK: [[addr_low:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx2]]
// CHECK: [[val_low:%[^ ]+]] = OpLoad [[half]] [[addr_low]]

// CHECK-64: [[bx2p1:%[^ ]+]] = OpBitwiseOr [[ulong]] [[bx2]] [[ulong_1]]
// CHECK-32: [[bx2p1:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx2]] [[uint_1]]
// CHECK: [[addr_high:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx2p1]]
// CHECK: [[val_high:%[^ ]+]] = OpLoad [[half]] [[addr_high]]

// CHECK: [[val_half2:%[^ ]+]] = OpCompositeConstruct [[half2]] [[val_low]] [[val_high]]
// CHECK: [[vali32:%[^ ]+]] = OpBitcast [[uint]] [[val_half2]]

// CHECK: [[val:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[vali32]]
// CHECK: OpStore {{.*}} [[val]]
