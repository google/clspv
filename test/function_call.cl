// We use -O0 here because the compiler is smart enough to realise calling
// a function that does nothing can be removed.
// RUN: clspv %target -O0 %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[BAR_ID:[a-zA-Z0-9_]*]] = OpFunction
void bar()
{
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
{
// CHECK: OpFunctionCall {{.*}} %[[BAR_ID]]
  bar();
}
