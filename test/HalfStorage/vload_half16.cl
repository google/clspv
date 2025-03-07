// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir64 -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.2 %t.spv

__kernel void test(__global half *a, int b, __global float16 *dst) {
    *dst = vload_half16(b, a);
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
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
// CHECK-64-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1

// CHECK-DAG: [[uint4_array:%[^ ]+]] = OpTypeRuntimeArray [[uint4]]
// CHECK-DAG: [[uint4_ptr:%[^ ]+]] = OpTypeStruct [[uint4_array]]
// CHECK-DAG: [[global_uint4_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint4_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_uint4_ptr]] StorageBuffer
// CHECK: OpCopyLogical
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK-64-DAG: [[bx16:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[b_long]] [[ulong_1]]
// CHECK-32-DAG: [[bx16:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[b]] [[uint_1]]
// CHECK-64-DAG: [[idx8:%[^ ]+]] = OpBitwiseOr [[ulong]] [[bx16]] [[ulong_1]]
// CHECK-32-DAG: [[idx8:%[^ ]+]] = OpBitwiseOr [[uint]] [[bx16]] [[uint_1]]

// CHECK-DAG: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx16]]
// CHECK-DAG: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx8]]
// CHECK: [[val0:%[^ ]+]] = OpLoad [[uint4]] [[addr0]]
// CHECK: [[val1:%[^ ]+]] = OpLoad [[uint4]] [[addr1]]

// CHECK: [[val00i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 0
// CHECK: [[val01i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 1
// CHECK: [[val02i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 2
// CHECK: [[val03i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 3

// CHECK: [[val10i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1]] 0
// CHECK: [[val11i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1]] 1
// CHECK: [[val12i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1]] 2
// CHECK: [[val13i32:%[^ ]+]] = OpCompositeExtract [[uint]] [[val1]] 3

// CHECK: [[val0f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val00i32]]
// CHECK: [[val1f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32]]
// CHECK: [[val2f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val02i32]]
// CHECK: [[val3f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val03i32]]
// CHECK: [[val4f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val10i32]]
// CHECK: [[val5f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val11i32]]
// CHECK: [[val6f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val12i32]]
// CHECK: [[val7f2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val13i32]]

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

// CHECK: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: OpStore [[addr0]] [[val0]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_1]]
// CHECK: OpStore [[addr1]] [[val1]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_2]]
// CHECK: OpStore [[addr2]] [[val2]]
// CHECK: [[addr3:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_3]]
// CHECK: OpStore [[addr3]] [[val3]]
// CHECK: [[addr4:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_4]]
// CHECK: OpStore [[addr4]] [[val4]]
// CHECK: [[addr5:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_5]]
// CHECK: OpStore [[addr5]] [[val5]]
// CHECK: [[addr6:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_6]]
// CHECK: OpStore [[addr6]] [[val6]]
// CHECK: [[addr7:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_7]]
// CHECK: OpStore [[addr7]] [[val7]]
// CHECK: [[addr8:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_8]]
// CHECK: OpStore [[addr8]] [[val8]]
// CHECK: [[addr9:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_9]]
// CHECK: OpStore [[addr9]] [[val9]]
// CHECK: [[addr10:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_10]]
// CHECK: OpStore [[addr10]] [[val10]]
// CHECK: [[addr11:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_11]]
// CHECK: OpStore [[addr11]] [[val11]]
// CHECK: [[addr12:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_12]]
// CHECK: OpStore [[addr12]] [[val12]]
// CHECK: [[addr13:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_13]]
// CHECK: OpStore [[addr13]] [[val13]]
// CHECK: [[addr14:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_14]]
// CHECK: OpStore [[addr14]] [[val14]]
// CHECK: [[addr15:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_15]]
// CHECK: OpStore [[addr15]] [[val15]]
