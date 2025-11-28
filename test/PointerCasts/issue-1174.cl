// RUN: clspv %s -o %t.spv -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// RUN: clspv %s -o %t.spv -arch=spir64 -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

#define ElementCount 100

struct E {
    int i;
    long l;
};

struct S {
    struct E e[ElementCount];
};

kernel void Kernel(global struct S *s)
{

    for (int i = 0; i < ElementCount; ++i) {
        global struct E *e = &s->e[i];
        e->l += e->i;
    }

    s->e[0].i = s->e[1].i;
}
