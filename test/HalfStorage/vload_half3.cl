// RUN: clspv %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test(__global half *a, int b, __global float3 *dst) {
    *dst = vload_half3(b, a);
}

// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[float3:%[^ ]+]] = OpTypeVector [[float]] 3
// CHECK-DAG: [[undef_float2:%[^ ]+]] = OpUndef [[float2]]
// CHECK-DAG: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-64-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-64-DAG: [[ulong_2:%[^ ]+]] = OpConstant [[ulong]] 2
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-64-DAG: [[ulong_3:%[^ ]+]] = OpConstant [[ulong]] 3

// CHECK-DAG: [[half_array:%[^ ]+]] = OpTypeRuntimeArray [[half]]
// CHECK-DAG: [[half_ptr:%[^ ]+]] = OpTypeStruct [[half_array]]
// CHECK-DAG: [[global_half_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[half_ptr]]

// CHECK: [[a:%[^ ]+]] = OpVariable [[global_half_ptr]] StorageBuffer
// CHECK: [[b:%[^ ]+]] = OpCompositeExtract [[uint]] {{.*}} 0

// CHECK-64: [[b_ulong:%[^ ]+]] = OpSConvert [[ulong]] [[b]]
// CHECK-64: [[bx3:%[^ ]+]] = OpIMul [[ulong]] [[b_ulong]] [[ulong_3]]
// CHECK-64: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx3]]
// CHECK-32: [[bx3:%[^ ]+]] = OpIMul [[uint]] [[b]] [[uint_3]]
// CHECK-32: [[addr0:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[bx3]]
// CHECK: [[val0h:%[^ ]+]] = OpLoad [[half]] [[addr0]]
// CHECK: [[val0i16:%[^ ]+]] = OpBitcast [[ushort]] [[val0h]]

// CHECK-64: [[idx1:%[^ ]+]] = OpIAdd [[ulong]] [[bx3]] [[ulong_1]]
// CHECK-32: [[idx1:%[^ ]+]] = OpIAdd [[uint]] [[bx3]] [[uint_1]]
// CHECK: [[addr1:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx1]]
// CHECK: [[val1h:%[^ ]+]] = OpLoad [[half]] [[addr1]]
// CHECK: [[val1i16:%[^ ]+]] = OpBitcast [[ushort]] [[val1h]]

// CHECK-64: [[idx2:%[^ ]+]] = OpIAdd [[ulong]] [[bx3]] [[ulong_2]]
// CHECK-32: [[idx2:%[^ ]+]] = OpIAdd [[uint]] [[bx3]] [[uint_2]]
// CHECK: [[addr2:%[^ ]+]] = OpAccessChain {{.*}} [[a]] [[uint_0]] [[idx2]]
// CHECK: [[val2h:%[^ ]+]] = OpLoad [[half]] [[addr2]]
// CHECK: [[val2i16:%[^ ]+]] = OpBitcast [[ushort]] [[val2h]]

// CHECK: [[val0i32:%[^ ]+]] = OpUConvert [[uint]] [[val0i16]]
// CHECK: [[val1i32:%[^ ]+]] = OpUConvert [[uint]] [[val1i16]]
// CHECK: [[val2i32:%[^ ]+]] = OpUConvert [[uint]] [[val2i16]]

// CHECK: [[val0:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val0i32]]
// CHECK: [[val1:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val1i32]]
// CHECK: [[val2:%[^ ]+]] = OpExtInst [[float2]] {{.*}} UnpackHalf2x16 [[val2i32]]

// CHECK: [[val0f3:%[^ ]+]] = OpVectorShuffle [[float3]] [[val2]] [[undef_float2]] 0 4294967295 4294967295
// CHECK: [[val1f3:%[^ ]+]] = OpVectorShuffle [[float3]] [[val0]] [[val1]] 0 2 4294967295
// CHECK: [[val:%[^ ]+]] = OpVectorShuffle [[float3]] [[val1f3]] [[val0f3]] 0 1 3

// CHECK: OpStore {{.*}} [[val]]
