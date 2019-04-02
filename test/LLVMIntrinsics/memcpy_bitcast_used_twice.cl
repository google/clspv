// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute %[[entry_id:[a-zA-Z0-9_]*]] "bitcast_used_twice"


void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
bitcast_used_twice(global float *A, int n, int k) {
  float dst[25];
  float src[20];
  for (int i = 0; i < 20; i++) {
    src[i] = A[i];
  }
  for (int i = 0; i < 20; i++) {
    // Second use of a bitcast for A[i]. Don't delete prematurely
    // Just check that we don't crash the compiler, and we produce sensible output.
    dst[n+i] = A[i];
  }
  A[n] = dst[k] + src[k];
}
