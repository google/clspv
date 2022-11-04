// RUN: clspv %target %s -o %t.spv -constant-args-ubo
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm

// This test is not validated because it uses a selection between Uniform
// pointers, which is disallowed by SPIR-V.
int4 bar(constant int4* data) { return data[0]; }

kernel void k1(global int4* out, constant int4* in1, constant int4* in2, int a) {
  constant int4* x = (a == 0) ? in1 : in2;
  *out = bar(x);
}

// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect
// CHECK-NEXT: OpLoad {{.*}} [[sel]]
// CHECK-NOT: OpFunctionCall
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
