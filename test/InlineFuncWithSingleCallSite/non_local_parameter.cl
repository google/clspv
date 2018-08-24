// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute [[entry:%[0-9a-zA-Z_]+]] "func_0"
// CHECK: [[entry]] = OpFunction
// CHECK: OpFunctionCall

int func_1(global int *in, int n) { return in[n]; }
kernel void func_0(global int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}
