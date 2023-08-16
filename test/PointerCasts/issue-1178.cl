// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct E {
  int i1, i2, i3;
};

struct S {
  int i1, i2;
  struct E e1, e2;
};

kernel void Kernel0(global struct S *s) {
  s->e1 = s->e2;
  s->i1 = 0;
}

kernel void Kernel1(global struct S *s) {
  s->e1 = s->e2;
  s->i2 = 0;
}
kernel void Kernel2(global struct S *s) {
  s->e1 = s->e2;
  s->i2 = s->i1;
}
