// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// func_1 is called by both kernel_1 and kernel_2, so it will not be inlined,
// but func_2 and func_3 will both be inlined into func_1.
// CHECK: OpEntryPoint GLCompute [[k1:%[0-9a-zA-Z_]+]] "kernel_1"
// CHECK: OpEntryPoint GLCompute [[k2:%[0-9a-zA-Z_]+]] "kernel_2"
// CHECK: [[func:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK-NOT: OpFunctionCall
// CHECK: OpFunctionEnd
// CHECK: [[k1]] = OpFunction
// CHECK: OpFunctionCall {{%[0-9a-zA-Z_]+}} [[func]]
// CHECK-NOT: OpFunctionCall
// CHECK: [[k2]] = OpFunction
// CHECK: OpFunctionCall {{%[0-9a-zA-Z_]+}} [[func]]
// CHECK-NOT: OpFunctionCall

int func_3(local int *in, int n) { return in[n]; }
int func_2(local int *in, int n) { return func_3(in, n); }
int func_1(local int *in, int n) { return func_2(in, n); }
kernel void kernel_1(local int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}
kernel void kernel_2(local int *in, global int *out, int n) {
  out[n] = func_1(in, n);
}

