// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float4 *dst) {
    *dst = vload_half4(b, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[^ ]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK: [[bx4:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[b]] [[uint_2]]
// CHECK: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx4]]
// CHECK: [[val0:%[^ ]+]] = OpLoad [[half]] [[addr0]]

// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx4]] [[uint_1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx1]]
// CHECK: [[val1:%[^ ]+]] = OpLoad [[half]] [[addr1]]

// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx4]] [[uint_2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx2]]
// CHECK: [[val2:%[^ ]+]] = OpLoad [[half]] [[addr2]]

// CHECK: [[idx3:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx4]] %uint_3
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx3]]
// CHECK: [[val3:%[^ ]+]] = OpLoad [[half]] [[addr3]]

// CHECK: [[valh4:%[^ ]+]] = OpCompositeConstruct [[half4]] [[val0]] [[val1]] [[val2]] [[val3]]
// CHECK: [[vali32:%[^ ]+]] = OpBitcast %v2uint [[valh4]]
// CHECK: [[val01i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[vali32]] 0
// CHECK: [[val23i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[vali32]] 1

// CHECK: [[val01:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32]]
// CHECK: [[val23:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val23i32]]

// CHECK: [[val:%[^ ]+]] = OpVectorShuffle [[float4]] [[val01]] [[val23]] 0 1 2 3
// CHECK:       OpStore {{.*}} [[val]]
