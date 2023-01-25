// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float3 b, int c) {
    vstore_half3(b, c, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-64-DAG: [[ulong1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-64-DAG: [[ulong2:%[^ ]+]] = OpConstant [[ulong]] 2
// CHECK-DAG: [[uint2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-64-DAG: [[ulong3:%[^ ]+]] = OpConstant [[ulong]] 3

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float4]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1
// CHECK-64: [[c_long:%[^ ]+]] = OpSConvert [[ulong]] [[c]]

// CHECK: [[val1_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 0 4294967295
// CHECK: [[val2_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 1 4294967295
// CHECK: [[val3_2f32:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 2 4294967295

// CHECK: [[val1i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val1_2f32]]
// CHECK: [[val1i16:%[^ ]+]] = OpUConvert [[ushort]] [[val1i32]]
// CHECK: [[val2i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val2_2f32]]
// CHECK: [[val2i16:%[^ ]+]] = OpUConvert [[ushort]] [[val2i32]]
// CHECK: [[val3i32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val3_2f32]]
// CHECK: [[val3i16:%[^ ]+]] = OpUConvert [[ushort]] [[val3i32]]

// CHECK-64: [[cx3:%[^ ]+]] = OpIMul [[ulong]] [[c_long]] [[ulong3]]
// CHECK-32: [[cx3:%[^ ]+]] = OpIMul [[uint]] [[c]] [[uint3]]

// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[cx3]]
// CHECK: OpStore [[addr1]] [[val1i16]]

// CHECK-64: [[idx1:%[^ ]+]] = OpIAdd [[ulong]] [[cx3]] [[ulong1]]
// CHECK-32: [[idx1:%[^ ]+]] = OpIAdd [[uint]] [[cx3]] [[uint1]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx1]]
// CHECK: OpStore [[addr2]] [[val2i16]]

// CHECK-64: [[idx2:%[^ ]+]] = OpIAdd [[ulong]] [[cx3]] [[ulong2]]
// CHECK-32: [[idx2:%[^ ]+]] = OpIAdd [[uint]] [[cx3]] [[uint2]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx2]]
// CHECK: OpStore [[addr3]] [[val3i16]]
