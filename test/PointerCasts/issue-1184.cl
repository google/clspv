// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// RUN: clspv %s -o %t.spv -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct E { int i0, i1; };

struct S
{
    long i; struct E e; // Fails
    // struct E e; long i; // OK
    // int i; struct E e; // OK
};

kernel void Kernel(global struct S* s)
{
    s->i = 1;
    s->e.i0 = 1;
    s->e.i1 = 1;
}
