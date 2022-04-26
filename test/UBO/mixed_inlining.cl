// RUN: clspv %s -o %t.spv -constant-args-ubo
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm

// This test is not validated because it uses a selection between Uniform
// pointers, which is disallowed by SPIR-V.
__attribute__((noinline))
int4 bar(constant int4* data) { return data[0]; }

kernel void k1(global int4* out, constant int4* in1, constant int4* in2, int a) {
  constant int4* x = (a == 0) ? in1 : in2;
  // This call requires inlining.
  *out = bar(x);
}

kernel void k2(global int4* out, constant int4* in) {
  // This call is specialized.
  *out = bar(in);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: OpEntryPoint GLCompute [[k2:%[a-zA-Z0-9_]+]]
// CHECK: [[k1]] = OpFunction
// CHECK-NOT: OpFunctionCall
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[k2]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[bar]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain
// CHECK: OpLoad {{.*}} [[gep]]
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction

