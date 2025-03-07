// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args -arch=spir --spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args -arch=spir64 --spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.2 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, float f, global float* B, uint n)
{
  A[n] = B[n] + f;
}
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_8:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_8]] Block
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[_ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[__struct_7]] = OpTypeStruct [[_float]] [[_uint]]
// CHECK-DAG: [[__struct_8]] = OpTypeStruct [[__struct_7]]
// CHECK-DAG: [[__ptr_PushConstant__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[__struct_8]]
// CHECK-DAG: [[__ptr_PushConstant__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[__struct_7]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_PushConstant__struct_8]] PushConstant
// CHECK: [[_19:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_PushConstant__struct_7]] [[_16]] [[_uint_0]]
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_7]] [[_19]]
// CHECK: [[copy:%[a-zA-Z0-9_]+]] = OpCopyLogical {{.*}} [[_20]]
// CHECK: [[_21:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[copy]] 0
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[copy]] 1
// CHECK-64: [[_22_long:%[a-zA-Z0-9_]+]] = OpUConvert [[_ulong]] [[_22]]
// CHECK-64: [[_23:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_22_long]]
// CHECK-32: [[_23:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_22]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_23]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpFAdd [[_float]] [[_21]] [[_24]]
// CHECK-64: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_22_long]]
// CHECK-32: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[_uint_0]] [[_22]]
// CHECK: OpStore [[_26]] [[_25]]
