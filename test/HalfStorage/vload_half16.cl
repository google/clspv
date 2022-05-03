// RUN: clspv %s -o %t.spv -long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float16 *dst) {
    *dst = vload_half16(b, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[half4:%[^ ]+]] = OpTypeVector [[half]] 4
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
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
// CHECK-DAG: [[uint_15:%[^ ]+]] = OpConstant [[uint]] 15

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK: [[bx16:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[b]] [[uint_4]]
// CHECK: [[idx8:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_8]]

// CHECK: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx16]]
// CHECK: [[val0:%[^ ]+]] = OpLoad [[half]] [[addr0]]

// CHECK: [[idx1:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx1]]
// CHECK: [[val1:%[^ ]+]] = OpLoad [[half]] [[addr1]]

// CHECK: [[idx2:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx2]]
// CHECK: [[val2:%[^ ]+]] = OpLoad [[half]] [[addr2]]

// CHECK: [[idx3:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_3
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx3]]
// CHECK: [[val3:%[^ ]+]] = OpLoad [[half]] [[addr3]]

// CHECK: [[idx4:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_4
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx4]]
// CHECK: [[val4:%[^ ]+]] = OpLoad [[half]] [[addr4]]

// CHECK: [[idx5:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_5
// CHECK: [[addr5:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx5]]
// CHECK: [[val5:%[^ ]+]] = OpLoad [[half]] [[addr5]]

// CHECK: [[idx6:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_6
// CHECK: [[addr6:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx6]]
// CHECK: [[val6:%[^ ]+]] = OpLoad [[half]] [[addr6]]

// CHECK: [[idx7:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_7
// CHECK: [[addr7:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx7]]
// CHECK: [[val7:%[^ ]+]] = OpLoad [[half]] [[addr7]]

// CHECK: [[val0h4:%[^ ]+]] = OpCompositeConstruct [[half4]] [[val0]] [[val1]] [[val2]] [[val3]]
// CHECK: [[val1h4:%[^ ]+]] = OpCompositeConstruct [[half4]] [[val4]] [[val5]] [[val6]] [[val7]]
// CHECK: [[val0i32:%[^ ]+]] = OpBitcast %v2uint [[val0h4]]
// CHECK: [[val1i32:%[^ ]+]] = OpBitcast %v2uint [[val1h4]]

// CHECK: [[addr8:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx8]]
// CHECK: [[val8:%[^ ]+]] = OpLoad [[half]] [[addr8]]

// CHECK: [[idx9:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_9]]
// CHECK: [[addr9:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx9]]
// CHECK: [[val9:%[^ ]+]] = OpLoad [[half]] [[addr9]]

// CHECK: [[idx10:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_10]]
// CHECK: [[addr10:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx10]]
// CHECK: [[val10:%[^ ]+]] = OpLoad [[half]] [[addr10]]

// CHECK: [[idx11:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_11
// CHECK: [[addr11:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx11]]
// CHECK: [[val11:%[^ ]+]] = OpLoad [[half]] [[addr11]]

// CHECK: [[idx12:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_12
// CHECK: [[addr12:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx12]]
// CHECK: [[val12:%[^ ]+]] = OpLoad [[half]] [[addr12]]

// CHECK: [[idx13:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_13
// CHECK: [[addr13:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx13]]
// CHECK: [[val13:%[^ ]+]] = OpLoad [[half]] [[addr13]]

// CHECK: [[idx14:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_14
// CHECK: [[addr14:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx14]]
// CHECK: [[val14:%[^ ]+]] = OpLoad [[half]] [[addr14]]

// CHECK: [[idx15:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] %uint_15
// CHECK: [[addr15:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx15]]
// CHECK: [[val15:%[^ ]+]] = OpLoad [[half]] [[addr15]]

// CHECK: [[val2h4:%[^ ]+]] = OpCompositeConstruct [[half4]] [[val8]] [[val9]] [[val10]] [[val11]]
// CHECK: [[val3h4:%[^ ]+]] = OpCompositeConstruct [[half4]] [[val12]] [[val13]] [[val14]] [[val15]]
// CHECK: [[val2i32:%[^ ]+]] = OpBitcast %v2uint [[val2h4]]
// CHECK: [[val3i32:%[^ ]+]] = OpBitcast %v2uint [[val3h4]]


// CHECK: [[val00i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0i32]] 0
// CHECK: [[val01i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0i32]] 1
// CHECK: [[val10i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1i32]] 0
// CHECK: [[val11i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1i32]] 1

// CHECK: [[val20i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val2i32]] 0
// CHECK: [[val21i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val2i32]] 1
// CHECK: [[val30i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val3i32]] 0
// CHECK: [[val31i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val3i32]] 1

// CHECK: [[val0f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val00i32]]
// CHECK: [[val1f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32]]
// CHECK: [[val2f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val10i32]]
// CHECK: [[val3f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val11i32]]
// CHECK: [[val4f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val20i32]]
// CHECK: [[val5f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val21i32]]
// CHECK: [[val6f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val30i32]]
// CHECK: [[val7f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val31i32]]

// CHECK: [[val0:%[^ ]+]] = OpCompositeExtract [[float]] [[val0f2]] 0
// CHECK: [[val1:%[^ ]+]] = OpCompositeExtract [[float]] [[val0f2]] 1
// CHECK: [[val2:%[^ ]+]] = OpCompositeExtract [[float]] [[val1f2]] 0
// CHECK: [[val3:%[^ ]+]] = OpCompositeExtract [[float]] [[val1f2]] 1
// CHECK: [[val4:%[^ ]+]] = OpCompositeExtract [[float]] [[val2f2]] 0
// CHECK: [[val5:%[^ ]+]] = OpCompositeExtract [[float]] [[val2f2]] 1
// CHECK: [[val6:%[^ ]+]] = OpCompositeExtract [[float]] [[val3f2]] 0
// CHECK: [[val7:%[^ ]+]] = OpCompositeExtract [[float]] [[val3f2]] 1
// CHECK: [[val8:%[^ ]+]] = OpCompositeExtract [[float]] [[val4f2]] 0
// CHECK: [[val9:%[^ ]+]] = OpCompositeExtract [[float]] [[val4f2]] 1
// CHECK: [[val10:%[^ ]+]] = OpCompositeExtract [[float]] [[val5f2]] 0
// CHECK: [[val11:%[^ ]+]] = OpCompositeExtract [[float]] [[val5f2]] 1
// CHECK: [[val12:%[^ ]+]] = OpCompositeExtract [[float]] [[val6f2]] 0
// CHECK: [[val13:%[^ ]+]] = OpCompositeExtract [[float]] [[val6f2]] 1
// CHECK: [[val14:%[^ ]+]] = OpCompositeExtract [[float]] [[val7f2]] 0
// CHECK: [[val15:%[^ ]+]] = OpCompositeExtract [[float]] [[val7f2]] 1

// CHECK: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_0]]
// CHECK: OpStore [[addr0]] [[val0]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_1]]
// CHECK: OpStore [[addr1]] [[val1]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_2]]
// CHECK: OpStore [[addr2]] [[val2]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_3]]
// CHECK: OpStore [[addr3]] [[val3]]
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_4]]
// CHECK: OpStore [[addr4]] [[val4]]
// CHECK: [[addr5:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_5]]
// CHECK: OpStore [[addr5]] [[val5]]
// CHECK: [[addr6:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_6]]
// CHECK: OpStore [[addr6]] [[val6]]
// CHECK: [[addr7:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_7]]
// CHECK: OpStore [[addr7]] [[val7]]
// CHECK: [[addr8:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_8]]
// CHECK: OpStore [[addr8]] [[val8]]
// CHECK: [[addr9:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_9]]
// CHECK: OpStore [[addr9]] [[val9]]
// CHECK: [[addr10:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_10]]
// CHECK: OpStore [[addr10]] [[val10]]
// CHECK: [[addr11:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_11]]
// CHECK: OpStore [[addr11]] [[val11]]
// CHECK: [[addr12:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_12]]
// CHECK: OpStore [[addr12]] [[val12]]
// CHECK: [[addr13:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_13]]
// CHECK: OpStore [[addr13]] [[val13]]
// CHECK: [[addr14:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_14]]
// CHECK: OpStore [[addr14]] [[val14]]
// CHECK: [[addr15:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]] [[uint_15]]
// CHECK: OpStore [[addr15]] [[val15]]
