// RUN: not clspv %target %s -o %t.spv -subgroup-uniform-control-flow 2>&1 | FileCheck %s --check-prefix=ERR
// RUN: not clspv %target %s -o %t.spv -subgroup-uniform-control-flow -spv-version=1.0 2>&1 | FileCheck %s --check-prefix=ERR

// RUN: clspv %target %s -o %t.spv -subgroup-uniform-control-flow -spv-version=1.3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -DNO_KERNEL -o %t.empty.spv -subgroup-uniform-control-flow -spv-version=1.3
// RUN: spirv-dis %t.empty.spv -o %t.empty.spvasm
// RUN: FileCheck %s --check-prefix=EMPTY < %t.empty.spvasm

// ERR: error: -subgroup-uniform-control-flow requires SPIR-V 1.3 or higher

// CHECK: OpExtension "SPV_KHR_subgroup_uniform_control_flow"
// CHECK-DAG: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]] "test1"
// CHECK-DAG: OpEntryPoint GLCompute [[k2:%[a-zA-Z0-9_]+]] "test2"
// CHECK-DAG: OpExecutionMode [[k1]] SubgroupUniformControlFlowKHR
// CHECK-DAG: OpExecutionMode [[k2]] SubgroupUniformControlFlowKHR

// EMPTY-NOT: OpExtension "SPV_KHR_subgroup_uniform_control_flow"
// EMPTY-NOT: SubgroupUniformControlFlowKHR

#pragma OPENCL EXTENSION cl_khr_subgroups : enable

#ifndef NO_KERNEL
kernel void test1(global int *out) {
  *out = sub_group_elect();
}

kernel void test2(global int *out) {
  *out = get_sub_group_local_id();
}
#endif
