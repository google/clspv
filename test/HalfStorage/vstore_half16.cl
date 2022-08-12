// RUN: clspv %s -o %t.spv -long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, float16 b, int c) {
    vstore_half16(b, c, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[^ ]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint2:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_15:%[^ ]+]] = OpConstant [[uint]] 15
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[^ ]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[^ ]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[uint_6:%[^ ]+]] = OpConstant [[uint]] 6
// CHECK-DAG: [[uint_7:%[^ ]+]] = OpConstant [[uint]] 7
// CHECK-DAG: [[uint_8:%[^ ]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[uint_9:%[^ ]+]] = OpConstant [[uint]] 9
// CHECK-DAG: [[uint_10:%[^ ]+]] = OpConstant [[uint]] 10
// CHECK-DAG: [[uint_11:%[^ ]+]] = OpConstant [[uint]] 11
// CHECK-DAG: [[uint_12:%[^ ]+]] = OpConstant [[uint]] 12
// CHECK-DAG: [[uint_13:%[^ ]+]] = OpConstant [[uint]] 13
// CHECK-DAG: [[uint_14:%[^ ]+]] = OpConstant [[uint]] 14

// CHECK: [[b:%[^ ]+]] = OpCompositeExtract {{.*}} {{.*}} 0

// CHECK: [[b0:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK: [[b1:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 1
// CHECK: [[b2:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 2
// CHECK: [[b3:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 3
// CHECK: [[b4:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 4
// CHECK: [[b5:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 5
// CHECK: [[b6:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 6
// CHECK: [[b7:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 7
// CHECK: [[b8:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 8
// CHECK: [[b9:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 9
// CHECK: [[b10:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 10
// CHECK: [[b11:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 11
// CHECK: [[b12:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 12
// CHECK: [[b13:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 13
// CHECK: [[b14:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 14
// CHECK: [[b15:%[^ ]+]] = OpCompositeExtract [[float]] {{.*}} 15

// CHECK: [[c:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 1

// CHECK: [[b01:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b0]] [[b1]]
// CHECK: [[b23:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b2]] [[b3]]
// CHECK: [[b45:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b4]] [[b5]]
// CHECK: [[b67:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b6]] [[b7]]
// CHECK: [[b89:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b8]] [[b9]]
// CHECK: [[b1011:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b10]] [[b11]]
// CHECK: [[b1213:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b12]] [[b13]]
// CHECK: [[b1415:%[^ ]+]] = OpCompositeConstruct [[float2]] [[b14]] [[b15]]

// CHECK: [[b01f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b01]]
// CHECK: [[b23f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b23]]
// CHECK: [[b45f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b45]]
// CHECK: [[b67f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b67]]
// CHECK: [[b89f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b89]]
// CHECK: [[b1011f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1011]]
// CHECK: [[b1213f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1213]]
// CHECK: [[b1415f:%[^ ]+]] = OpExtInst [[uint]] {{.*}} PackHalf2x16 [[b1415]]

// CHECK: [[b0123f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b01f]] [[b23f]]
// CHECK: [[b4567f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b45f]] [[b67f]]
// CHECK: [[b891011f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b89f]] [[b1011f]]
// CHECK: [[b12131415f:%[^ ]+]] = OpCompositeConstruct [[uint2]] [[b1213f]] [[b1415f]]

// CHECK: [[cx16:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[c]] [[uint_4]]

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

// CHECK: [[addr0:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[cx16]]
// CHECK: OpStore [[addr0]] [[b0h]]
// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx1]]
// CHECK: OpStore [[addr1]] [[b1h]]
// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx2]]
// CHECK: OpStore [[addr2]] [[b2h]]
// CHECK: [[idx3:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_3]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx3]]
// CHECK: OpStore [[addr3]] [[b3h]]
// CHECK: [[idx4:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_4]]
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx4]]
// CHECK: OpStore [[addr4]] [[b4h]]
// CHECK: [[idx5:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_5]]
// CHECK: [[addr5:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx5]]
// CHECK: OpStore [[addr5]] [[b5h]]
// CHECK: [[idx6:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_6]]
// CHECK: [[addr6:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx6]]
// CHECK: OpStore [[addr6]] [[b6h]]
// CHECK: [[idx7:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_7]]
// CHECK: [[addr7:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx7]]
// CHECK: OpStore [[addr7]] [[b7h]]

// CHECK: [[idx8:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_8]]

// CHECK: [[b891011h:%[^ ]+]] = OpBitcast [[half4]] [[b891011f]]
// CHECK: [[b12131415h:%[^ ]+]] = OpBitcast [[half4]] [[b12131415f]]
// CHECK: [[b8h:%[^ ]+]] = OpCompositeExtract [[half]] [[b891011h]] 0
// CHECK: [[b9h:%[^ ]+]] = OpCompositeExtract [[half]] [[b891011h]] 1
// CHECK: [[b10h:%[^ ]+]] = OpCompositeExtract [[half]] [[b891011h]] 2
// CHECK: [[b11h:%[^ ]+]] = OpCompositeExtract [[half]] [[b891011h]] 3
// CHECK: [[b12h:%[^ ]+]] = OpCompositeExtract [[half]] [[b12131415h]] 0
// CHECK: [[b13h:%[^ ]+]] = OpCompositeExtract [[half]] [[b12131415h]] 1
// CHECK: [[b14h:%[^ ]+]] = OpCompositeExtract [[half]] [[b12131415h]] 2
// CHECK: [[b15h:%[^ ]+]] = OpCompositeExtract [[half]] [[b12131415h]] 3

// CHECK: [[addr8:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx8]]
// CHECK: OpStore [[addr8]] [[b8h]]
// CHECK: [[idx9:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_9]]
// CHECK: [[addr9:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx9]]
// CHECK: OpStore [[addr9]] [[b9h]]
// CHECK: [[idx10:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_10]]
// CHECK: [[addr10:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx10]]
// CHECK: OpStore [[addr10]] [[b10h]]
// CHECK: [[idx11:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_11]]
// CHECK: [[addr11:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx11]]
// CHECK: OpStore [[addr11]] [[b11h]]
// CHECK: [[idx12:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_12]]
// CHECK: [[addr12:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx12]]
// CHECK: OpStore [[addr12]] [[b12h]]
// CHECK: [[idx13:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_13]]
// CHECK: [[addr13:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx13]]
// CHECK: OpStore [[addr13]] [[b13h]]
// CHECK: [[idx14:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_14]]
// CHECK: [[addr14:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx14]]
// CHECK: OpStore [[addr14]] [[b14h]]
// CHECK: [[idx15:%[^ ]+]] = OpBitwiseOr [[uint]] [[cx16]] [[uint_15]]
// CHECK: [[addr15:%[^ ]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[idx15]]
// CHECK: OpStore [[addr15]] [[b15h]]
