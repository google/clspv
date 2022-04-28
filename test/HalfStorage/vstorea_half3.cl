// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float3 b, int c) {
    vstorea_half3(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint2:%[^ ]+]] = OpConstant [[uint]] 2

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float4]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK: [[val1_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 0 4294967295
// CHECK: [[val2_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 1 4294967295
// CHECK: [[val3_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 2 4294967295

// CHECK: [[val1i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val1_2f32]]
// CHECK: [[val1i16:%[^ ]+]] = OpUConvert [[ushort]] [[val1i32]]
// CHECK: [[val2i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val2_2f32]]
// CHECK: [[val2i16:%[^ ]+]] = OpUConvert [[ushort]] [[val2i32]]
// CHECK: [[val3i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val3_2f32]]
// CHECK: [[val3i16:%[^ ]+]] = OpUConvert [[ushort]] [[val3i32]]

// CHECK: [[cx4:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint2]]

// CHECK: [[val1:%[^ ]+]] = OpBitcast [[half]] [[val1i16]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[cx4]]
// CHECK: OpStore [[addr1]] [[val1]]

// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx4]] [[uint1]]
// CHECK: [[val2:%[^ ]+]] = OpBitcast [[half]] [[val2i16]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx1]]
// CHECK: OpStore [[addr2]] [[val2]]

// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx4]] [[uint2]]
// CHECK: [[val3:%[^ ]+]] = OpBitcast [[half]] [[val3i16]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx2]]
// CHECK: OpStore [[addr3]] [[val3]]
