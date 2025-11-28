// RUN: clspv %s -o %t.spv -physical-storage-buffers -arch=spir64 -cl-kernel-arg-info
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv  --target-env spv1.0

// RUN: clspv %s -o %t.spv -physical-storage-buffers -arch=spir64 -cl-kernel-arg-info -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv  --target-env spv1.0

struct E {
  int i1, i2, i3, i4;
};

struct S {
  int Shift;
  struct E e[3];
};

kernel void Kernel0(global struct S *s) { s->e[0] = s->e[1]; }
kernel void Kernel1(global struct S *s) {
  struct E e = s->e[1];
  s->e[0] = e;
}
kernel void Kernel2(global struct S *s) { s->e[1] = s->e[0]; }
kernel void Kernel3(global struct S *s) {
  struct E e = s->e[0];
  s->e[1] = e;
}
kernel void Kernel4(global struct S *s) { s->e[1] = s->e[2]; }
kernel void Kernel5(global struct S *s) { s->e[2] = s->e[1]; }
