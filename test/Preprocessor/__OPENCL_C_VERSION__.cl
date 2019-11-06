// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 120 120 120

#ifdef __OPENCL_C_VERSION__
void kernel __attribute__((reqd_work_group_size(__OPENCL_C_VERSION__, __OPENCL_C_VERSION__, __OPENCL_C_VERSION__))) foo()
{
}
#endif
