// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -long-vector -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float8 *dst) {
    *dst = vload_half8(b, a);
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

// CHECK-DAG: [[uint4_array:%[^ ]+]] = OpTypeRuntimeArray [[uint4]]
// CHECK-DAG: [[uint4_ptr:%[^ ]+]] = OpTypeStruct [[uint4_array]]
// CHECK-DAG: [[global_uint4_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint4_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_uint4_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK-64: [[b_long:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK-64: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[b_long]]
// CHECK-32: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[b]]
// CHECK: [[val0:%[^ ]+]] = OpLoad [[uint4]] [[addr0]]

// CHECK: [[val01i32l:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 0
// CHECK: [[val23i32l:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 1
// CHECK: [[val01i32h:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 2
// CHECK: [[val23i32h:%[^ ]+]] = OpCompositeExtract [[uint]] [[val0]] 3

// CHECK: [[val01:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32l]]
// CHECK: [[val23:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val23i32l]]
// CHECK: [[val45:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val01i32h]]
// CHECK: [[val67:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val23i32h]]

// CHECK: [[val0:%[^ ]+]] = OpCompositeExtract [[float]] [[val01]] 0
// CHECK: [[val1:%[^ ]+]] = OpCompositeExtract [[float]] [[val01]] 1
// CHECK: [[val2:%[^ ]+]] = OpCompositeExtract [[float]] [[val23]] 0
// CHECK: [[val3:%[^ ]+]] = OpCompositeExtract [[float]] [[val23]] 1
// CHECK: [[val4:%[^ ]+]] = OpCompositeExtract [[float]] [[val45]] 0
// CHECK: [[val5:%[^ ]+]] = OpCompositeExtract [[float]] [[val45]] 1
// CHECK: [[val6:%[^ ]+]] = OpCompositeExtract [[float]] [[val67]] 0
// CHECK: [[val7:%[^ ]+]] = OpCompositeExtract [[float]] [[val67]] 1

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
