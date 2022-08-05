// RUN: clspv %s -o %t.spv -long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float8 b, int c) {
    vstore_half8(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[^ ]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_28:%[^ ]+]] = OpConstant [[uint]] 28
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[^ ]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[^ ]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[uint_6:%[^ ]+]] = OpConstant [[uint]] 6
// CHECK-DAG: [[uint_7:%[^ ]+]] = OpConstant [[uint]] 7

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract {{.*}} {{.*}} 0

// CHECK: [[b0:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK: [[b1:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 1
// CHECK: [[b2:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 2
// CHECK: [[b3:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 3
// CHECK: [[b4:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 4
// CHECK: [[b5:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 5
// CHECK: [[b6:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 6
// CHECK: [[b7:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 7

// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK: [[b01:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b0]] [[b1]]
// CHECK: [[b23:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b2]] [[b3]]
// CHECK: [[b45:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b4]] [[b5]]
// CHECK: [[b67:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b6]] [[b7]]

// CHECK: [[b01f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b01]]
// CHECK: [[b23f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b23]]
// CHECK: [[b45f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b45]]
// CHECK: [[b67f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b67]]

// CHECK: [[b0123f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b01f]] [[b23f]]
// CHECK: [[b4567f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b45f]] [[b67f]]

// CHECK: [[cx8:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint_3]]

// CHECK: [[b0123h:%[^ ]+]] = OpBitcast [[half4]] [[b0123f]]
// CHECK: [[b4567h:%[^ ]+]] = OpBitcast [[half4]] [[b4567f]]
// CHECK: [[b0h:%[^ ]+]] = OpCompositeExtract [[half]] [[b0123h]] 0
// CHECK: [[b1h:%[^ ]+]] = OpCompositeExtract [[half]] [[b0123h]] 1
// CHECK: [[b2h:%[^ ]+]] = OpCompositeExtract [[half]] [[b0123h]] 2
// CHECK: [[b3h:%[^ ]+]] = OpCompositeExtract [[half]] [[b0123h]] 3
// CHECK: [[b4h:%[^ ]+]] = OpCompositeExtract [[half]] [[b4567h]] 0
// CHECK: [[b5h:%[^ ]+]] = OpCompositeExtract [[half]] [[b4567h]] 1
// CHECK: [[b6h:%[^ ]+]] = OpCompositeExtract [[half]] [[b4567h]] 2
// CHECK: [[b7h:%[^ ]+]] = OpCompositeExtract [[half]] [[b4567h]] 3

// CHECK: [[addr0:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[cx8]]
// CHECK: OpStore [[addr0]] [[b0h]]
// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx1]]
// CHECK: OpStore [[addr1]] [[b1h]]
// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx2]]
// CHECK: OpStore [[addr2]] [[b2h]]
// CHECK: [[idx3:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_3]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx3]]
// CHECK: OpStore [[addr3]] [[b3h]]
// CHECK: [[idx4:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_4]]
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx4]]
// CHECK: OpStore [[addr4]] [[b4h]]
// CHECK: [[idx5:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_5]]
// CHECK: [[addr5:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx5]]
// CHECK: OpStore [[addr5]] [[b5h]]
// CHECK: [[idx6:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_6]]
// CHECK: [[addr6:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx6]]
// CHECK: OpStore [[addr6]] [[b6h]]
// CHECK: [[idx7:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx8]] [[uint_7]]
// CHECK: [[addr7:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx7]]
// CHECK: OpStore [[addr7]] [[b7h]]
