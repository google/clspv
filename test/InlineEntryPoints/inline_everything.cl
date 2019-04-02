// RUN: clspv %s -o %t.spv -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int func_3(local int *in, int n) { return in[n]; }
int func_2(local int *in, int n) { return func_3(in, n); }
int func_1(local int *in, int n) { return func_2(in, n); }
kernel void kernel_1(local int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}
kernel void kernel_2(local int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}

int foo(local int *in, int n) { return func_3(in, n); }

// CHECK: OpEntryPoint GLCompute [[k1:%[0-9a-zA-Z_]+]] "kernel_1"
// CHECK: OpEntryPoint GLCompute [[k2:%[0-9a-zA-Z_]+]] "kernel_2"
// CHECK-NOT: OpFunction
// CHECK: [[k1]] = OpFunction
// CHECK-NOT: OpFunctionCall
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
// CHECK: [[k2]] = OpFunction
// CHECK-NOT: OpFunctionCall
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
