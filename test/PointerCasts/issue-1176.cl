// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// RUN: clspv %s -o %t.spv -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct E {
  int i1, i2, i3;
};

struct S {
  struct E e[3];
};

kernel void Kernel0(global struct S *s) { s->e[0] = s->e[1]; }
kernel void Kernel1(global struct S *s) { s->e[1] = s->e[0]; }
kernel void Kernel2(global struct S *s) { s->e[1] = s->e[2]; }
kernel void Kernel3(global struct S *s) { s->e[2] = s->e[1]; }
