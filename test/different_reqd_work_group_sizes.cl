// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: OpEntryPoint GLCompute [[bar:%[a-zA-Z0-9_]+]] "bar"
// CHECK-DAG: OpExecutionMode [[foo]] LocalSize 1 2 3
// CHECK-DAG: OpExecutionMode [[bar]] LocalSize 4 5 6

__attribute__((reqd_work_group_size(1,2,3)))
kernel void foo() { }

__attribute__((reqd_work_group_size(4,5,6)))
kernel void bar() { }
