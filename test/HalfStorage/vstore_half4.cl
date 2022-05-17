// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float4 b, int c) {
    vstore_half4(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[^ ]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float4]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK: [[val_float01:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 0 1
// CHECK: [[val_float23:%[^ ]+]] = OpVectorShuffle [[float2]] [[b]] {{.*}} 2 3

// CHECK: [[val1_int:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val_float01]]
// CHECK: [[val2_int:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val_float23]]

// CHECK: [[val_int2:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[val1_int]] [[val2_int]]
// CHECK: [[cx4:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint_2]]
// CHECK: [[bitcast:%[^ ]+]] = OpBitcast [[half4]] [[val_int2]]

// CHECK: [[val1:%[^ ]+]] = OpCompositeExtract [[half]] [[bitcast]] 0
// CHECK: [[val2:%[^ ]+]] = OpCompositeExtract [[half]] [[bitcast]] 1
// CHECK: [[val3:%[^ ]+]] = OpCompositeExtract [[half]] [[bitcast]] 2
// CHECK: [[val4:%[^ ]+]] = OpCompositeExtract [[half]] [[bitcast]] 3

// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[cx4]]
// CHECK: OpStore [[addr1]] [[val1]]

// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx4]] [[uint_1]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx1]]
// CHECK: OpStore [[addr2]] [[val2]]

// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx4]] [[uint_2]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx2]]
// CHECK: OpStore [[addr3]] [[val3]]

// CHECK: [[idx3:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx4]] [[uint_3]]
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx3]]
// CHECK: OpStore [[addr4]] [[val4]]
