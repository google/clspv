// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float2* A, global uint* B, uint n) {
  A[0] = vloada_half2(n, (global half*)B);
  A[1] = vloada_half2(0, (global half*)(B+1));
}

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[v2float:%[^ ]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1

// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0

// CHECK-DAG: [[_runtimearr_v2float:%[^ ]+]] = OpTypeRuntimeArray [[v2float]]
// CHECK-DAG: [[_runtimearr_uint:%[^ ]+]] = OpTypeRuntimeArray [[uint]]
// CHECK-DAG: [[_struct_12:%[^ ]+]] = OpTypeStruct [[_runtimearr_v2float]]
// CHECK-DAG: [[_struct_16:%[^ ]+]] = OpTypeStruct [[_runtimearr_uint]]
// CHECK-DAG: [[_struct_19:%[^ ]+]] = OpTypeStruct [[uint]]
// CHECK-DAG: [[_struct_20:%[^ ]+]] = OpTypeStruct [[_struct_19]]
// CHECK-DAG: [[_ptr_StorageBuffer__struct_12:%[^ ]+]] = OpTypePointer StorageBuffer [[_struct_12]]
// CHECK-DAG: [[_ptr_StorageBuffer_v2float:%[^ ]+]] = OpTypePointer StorageBuffer [[v2float]]
// CHECK-DAG: [[_ptr_StorageBuffer__struct_16:%[^ ]+]] = OpTypePointer StorageBuffer [[_struct_16]]
// CHECK-DAG: [[_ptr_PushConstant__struct_20:%[^ ]+]] = OpTypePointer PushConstant [[_struct_20]]
// CHECK-DAG: [[_ptr_PushConstant__struct_19:%[^ ]+]] = OpTypePointer PushConstant [[_struct_19]]
// CHECK-DAG: [[_ptr_StorageBuffer_uint:%[^ ]+]] = OpTypePointer StorageBuffer [[uint]]

// CHECK-DAG: [[A:%[^ ]+]] = OpVariable [[_ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK-DAG: [[B:%[^ ]+]] = OpVariable [[_ptr_StorageBuffer__struct_16]] StorageBuffer
// CHECK-DAG: [[n:%[^ ]+]] = OpVariable [[_ptr_PushConstant__struct_20]] PushConstant

// CHECK-DAG: [[A0:%[^ ]+]] = OpAccessChain [[_ptr_StorageBuffer_v2float]] [[A]] [[uint_0]] [[uint_0]]
// CHECK-DAG: [[A1:%[^ ]+]] = OpAccessChain [[_ptr_StorageBuffer_v2float]] [[A]] [[uint_0]] [[uint_1]]
// CHECK-DAG: [[n0:%[^ ]+]] = OpAccessChain [[_ptr_PushConstant__struct_19]] [[n]] [[uint_0]]
// CHECK-DAG: [[n0s:%[^ ]+]] = OpLoad [[_struct_19]] [[n0]]
// CHECK-DAG: [[nVal:%[^ ]+]] = OpCompositeExtract [[uint]] [[n0s]] 0

// CHECK-64-DAG: [[nValL:%[^ ]+]] = OpUConvert [[ulong]] [[nVal]]

// CHECK-32-DAG: [[BnPtr:%[^ ]+]] = OpAccessChain [[_ptr_StorageBuffer_uint]] [[B]] [[uint_0]] [[nVal]]
// CHECK-64-DAG: [[BnPtr:%[^ ]+]] = OpAccessChain [[_ptr_StorageBuffer_uint]] [[B]] [[uint_0]] [[nValL]]
// CHECK-DAG: [[Bn:%[^ ]+]] = OpLoad [[uint]] [[BnPtr]]
// CHECK-DAG: [[Bn2f:%[^ ]+]] = OpExtInst [[v2float]] {{.*}} UnpackHalf2x16 [[Bn]]
// CHECK-DAG: OpStore [[A0]] [[Bn2f]]

// CHECK-DAG: [[B1Ptr:%[^ ]+]] = OpAccessChain [[_ptr_StorageBuffer_uint]] [[B]] [[uint_0]] [[uint_1]]
// CHECK-DAG: [[B1:%[^ ]+]] = OpLoad [[uint]] [[B1Ptr]]
// CHECK-DAG: [[B12f:%[^ ]+]] = OpExtInst [[v2float]] {{.*}} UnpackHalf2x16 [[B1]]
// CHECK-DAG: OpStore [[A1]] [[B12f]]
