// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[entry_id:[a-zA-Z0-9_]*]] "src_is_array"
// CHECK: OpExecutionMode %[[entry_id]] LocalSize 1 1 1

// TODO(dneto): Fill in this test.

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
src_is_array(global float *A, int n, int k) {
  float src[20];
  for (int i = 0; i < 20; i++) {
    src[i] = i;
  }
  for (int i = 0; i < 20; i++) {
    A[n+i] = src[i]; // Reading whole array.
  }
}
