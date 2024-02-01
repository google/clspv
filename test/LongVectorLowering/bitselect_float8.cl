// RUN: clspv %target %s --long-vector -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// TODO(#1292)
// XFAIL: *

__kernel void test_bitselect(__global float8 *A, __global float8 *B,
                        __global float8 *C, __global float8 *destValue) {
  *destValue = bitselect(*A, *B, *C);
}

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[uint_8:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 8
// CHECK-DAG: %[[float8:[0-9a-zA-Z_]+]] = OpTypeArray %[[float]] %[[uint_8]]
// CHECK-DAG: %[[array_float8:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[float8]]
// CHECK-DAG: %[[struct_float8:[0-9a-zA-Z_]+]] = OpTypeStruct %[[array_float8]]
// CHECK-DAG: %[[ptr_float8:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[struct_float8]]
// CHECK-DAG: %[[ptr_float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[float]]
// CHECK-DAG: %[[uint0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0

// CHECK: %[[A:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_float8]] StorageBuffer
// CHECK: %[[B:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_float8]] StorageBuffer
// CHECK: %[[C:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_float8]] StorageBuffer
// CHECK: %[[destValue:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_float8]] StorageBuffer

// CHECK: %[[GEPA:[0-9a-zA-Z_]+]] = OpAccessChain %[[ptr_float]] %[[A]] %[[uint0]] %[[uint0]] %[[uint0]]
// CHECK: %[[A0:[0-9a-zA-Z_]+]] = OpLoad %[[float]] %[[GEPA]]
// CHECK: %[[A0_uint:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[A0]]

// CHECK: %[[GEPB:[0-9a-zA-Z_]+]] = OpAccessChain %[[ptr_float]] %[[B]] %[[uint0]] %[[uint0]] %[[uint0]]
// CHECK: %[[B0:[0-9a-zA-Z_]+]] = OpLoad %[[float]] %[[GEPB]]
// CHECK: %[[B0_uint:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[B0]]

// CHECK: %[[GEPC:[0-9a-zA-Z_]+]] = OpAccessChain %[[ptr_float]] %[[C]] %[[uint0]] %[[uint0]] %[[uint0]]
// CHECK: %[[C0:[0-9a-zA-Z_]+]] = OpLoad %[[float]] %[[GEPC]]
// CHECK: %[[C0_uint:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[C0]]

