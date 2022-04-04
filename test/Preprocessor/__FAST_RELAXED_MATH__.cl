// RUN: clspv -cl-fast-relaxed-math %s -o %t.spv -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 2 3 4

#ifdef __FAST_RELAXED_MATH__
void kernel __attribute__((reqd_work_group_size(2, 3, 4))) foo()
{
}
#endif
