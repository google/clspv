// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Libclc functions (such as tgamma) use __clc_mad which is preserved as Fma.
// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpExtInst %{{.*}} %[[EXT_INST]] Fma

void kernel foo(global float* out, global float* in) {
  out[0] = tgamma(in[0]);
}
