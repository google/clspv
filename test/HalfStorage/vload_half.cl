// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float *dst) {
    *dst = vload_half(b, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0
// CHECK: [[addr:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint0]] [[b]]
// CHECK: [[valh:%[^ ]+]] = OpLoad [[half]] [[addr]]
// CHECK: [[vali16:%[^ ]+]] = OpBitcast [[ushort]] [[valh]]
// CHECK: [[vali32:%[^ ]+]] = OpUConvert [[uint]] [[vali16]]
// CHECK: [[valf2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[vali32]]
// CHECK: [[val:%[^ ]+]] = OpCompositeExtract [[float]] [[valf2]] 0
// CHECK: OpStore {{.*}} [[val]]
