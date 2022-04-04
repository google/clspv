// RUN: clspv %s -o %t.spv -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpEntryPoint GLCompute %[[BAR_ID:[a-zA-Z0-9_]*]] "bar"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK: OpExecutionMode %[[BAR_ID]] LocalSize 1 1 1
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar()
{
}
