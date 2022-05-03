// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float2 *dst) {
    *dst = vload_half2(b, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK: [[bx2:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[b]]
// CHECK: [[addr_low:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx2]]
// CHECK: [[val_low:%[^ ]+]] = OpLoad [[half]] [[addr_low]]
// CHECK: [[val_lowi16:%[^ ]+]] = OpBitcast [[ushort]] [[val_low]]

// CHECK: [[bx2p1:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx2]] [[uint_1]]
// CHECK: [[addr_high:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx2p1]]
// CHECK: [[val_high:%[^ ]+]] = OpLoad [[half]] [[addr_high]]
// CHECK: [[val_highi16:%[^ ]+]] = OpBitcast [[ushort]] [[val_high]]

// CHECK: [[val_lowi32:%[^ ]+]] = OpUConvert [[uint]] [[val_lowi16]]
// CHECK: [[val_highi32:%[^ ]+]] = OpUConvert [[uint]] [[val_highi16]]
// CHECK: [[val_highshift:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[val_highi32]] [[uint_16]]
// CHECK: [[vali32:%[^ ]+]] = OpBitwiseOr [[uint]] [[val_highshift]] [[val_lowi32]]

// CHECK: [[val:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[vali32]]
// CHECK: OpStore {{.*}} [[val]]
