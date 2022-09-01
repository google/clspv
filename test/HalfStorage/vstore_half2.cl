// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float2 b, int c) {
    vstore_half2(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[short:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[float2]] {{.*}} 0
// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK: [[vali32:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b]]
// CHECK: [[idx0:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint1]]
// CHECK: [[conv1:%[a-zA-Z0-9_]+]] = OpUConvert [[short]] [[vali32]]
// CHECK: [[shr:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[uint]] [[vali32]] [[uint16]]
// CHECK: [[conv2:%[a-zA-Z0-9_]+]] = OpUConvert [[short]] [[shr]]

// CHECK: [[val1:%[^ ]+]] = OpBitcast [[half]] [[conv1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx0]]
// CHECK: OpStore [[addr1]] [[val1]]
//
// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[idx0]] [[uint1]]
// CHECK: [[val2:%[^ ]+]] = OpBitcast [[half]] [[conv2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint0]] [[idx1]]
// CHECK: OpStore [[addr2]] [[val2]]
