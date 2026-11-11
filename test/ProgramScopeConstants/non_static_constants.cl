// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target %s -o %t.o0.spv -cl-std=CL2.0 -inline-entry-points -O0
// RUN: spirv-dis -o %t.o0.spvasm %t.o0.spv
// RUN: FileCheck %s < %t.o0.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.o0.spv
// RUN: clspv %target %s -o %t.ll -cl-std=CL2.0 -inline-entry-points -O0 -output-format=ll
// RUN: FileCheck --check-prefix=LLVM %s < %t.ll

const float M = 4.3f;

// A non-static constant referenced only by another unused non-static
// constant. Both must be removed at -O0 as well.
const float A = 1.0f;
const global float *const B = &A;

// A static constant referenced only by an unused non-static constant. It must
// be removed at -O0 as well.
static const float S = 2.0f;
const global float *const T = &S;

// A non-static constant used only by an unused function. The function is
// removed before the pass runs, so the constant must be removed too.
const float U = 3.0f;
void unused_helper(global float *out) {
  const global float *p = &U;
  *out = *p;
}

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[CST:[a-zA-Z0-9_]+]] = OpConstant [[float]] 4.30000019
// CHECK-NOT: OpVariable %_ptr_StorageBuffer_float
// CHECK: OpStore {{.*}} %[[CST]]

// The clCompileProgram flow emits LLVM IR without running the clspv pass
// pipeline, so the constant keeps its external linkage.
// LLVM: @M = addrspace(1) constant float

kernel void myKernel(global float *out)
{
  *out = M;
}
