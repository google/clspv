// We use -O0 here because the compiler is smart enough to realise calling
// a function that does nothing can be removed.
// RUN: clspv -O0 %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv -O0 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 8
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 1 1 1
// CHECK-DAG: %[[VOID_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVoid
// CHECK-DAG: %[[NOP_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFunction %[[VOID_TYPE_ID]]

// CHECK: %[[BAR_ID:[a-zA-Z0-9_]*]] = OpFunction %[[VOID_TYPE_ID]] None %[[NOP_TYPE_ID]]
void bar()
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
{
// CHECK: OpReturn
}
// CHECK: OpFunctionEnd

// CHECK: %[[FOO_ID]] = OpFunction %[[VOID_TYPE_ID]] None %[[NOP_TYPE_ID]]
void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo()
// CHECK: %[[LABEL_ID:[a-zA-Z0-9_]*]] = OpLabel
{
// CHECK: %[[CALL_ID:[a-zA-Z0-9_]*]] = OpFunctionCall %[[VOID_TYPE_ID]] %[[BAR_ID]]
  bar();
// CHECK: OpReturn
}
// CHECK: OpFunctionEnd
