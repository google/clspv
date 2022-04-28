// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float b, int c) {
    vstore_half(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[undef_float2:%[^ ]+]] = OpUndef [[float2]]
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1
// CHECK: [[val2f32:%[^ ]+]] = OpCompositeInsert [[float2]] [[b]] [[undef_float2]] 0
// CHECK: [[vali32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[val2f32]]
// CHECK: [[vali16:%[^ ]+]] = OpUConvert [[ushort]] [[vali32]]
// CHECK: [[val:%[^ ]+]] = OpBitcast [[half]] [[vali16]]
// CHECK: [[addr:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[c]]
// CHECK: OpStore [[addr]] [[val]]
