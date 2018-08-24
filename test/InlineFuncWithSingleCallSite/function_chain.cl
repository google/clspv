// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// All functions should be inlined into the kernel.
// CHECK: OpEntryPoint GLCompute [[entry:%[0-9a-zA-Z_]+]] "func_0"
// CHECK-NOT: OpFunctionCall
// CHECK: [[entry]] = OpFunction
// CHECK-NOT: OpFunctionCall

int func_3(local int *in, int n) { return in[n]; }
int func_2(local int *in, int n) { return func_3(in, n); }
int func_1(local int *in, int n) { return func_2(in, n); }
kernel void func_0(local int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}
