// Demonstrate fix for https://github.com/google/clspv/issues/94
// A memset of 0 bytes that spans many pointee values should
// result in replicated stores.

// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// Issue #473: rewrite as a clspv-opt test
// XFAIL: *

__kernel void myTest(__global float* jasper)
{
  *jasper++ = 0;
  *jasper++ = 0;
  *jasper++ = 0;
  *jasper++ = 0;
}

// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CHECK-DAG: [[_uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_24]] [[_float_0]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_25]] [[_float_0]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_2]]
// CHECK: OpStore [[_26]] [[_float_0]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_3]]
// CHECK: OpStore [[_27]] [[_float_0]]
