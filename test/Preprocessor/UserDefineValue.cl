// RUN: clspv %target -DUSER_SPECIFIED=42 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 4 2 42

#ifdef USER_SPECIFIED
void kernel __attribute__((reqd_work_group_size(4, 2, USER_SPECIFIED))) foo()
{
}
#endif
