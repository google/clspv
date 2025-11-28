// RUN: clspv %s -o %t.spv -physical-storage-buffers -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// RUN: clspv %s -o %t.spv -physical-storage-buffers -arch=spir64 -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct V {
    int x, y;
};
struct E {
    struct V v;
};
struct S {
    struct E e[2];
};

kernel void Kernel0(global struct S *s)
{
    s->e[0].v.x = 1;
    s->e[0].v.y = 1;
    s->e[1].v.x = 1;
}

kernel void Kernel1(global struct S *s)
{
    global struct E *e0 = (global struct E *)(((long)s->e) + sizeof(struct E) * 0);
    e0->v.x = 1;
    e0->v.y = 1;
    global struct E *e1 = (global struct E *)(((long)s->e) + sizeof(struct E) * 1);
    e1->v.x = 1;
    e1->v.y = 1;
}

kernel void Kernel2(global struct S *s)
{
    s->e[0].v.x = 1;
    s->e[1].v.x = 1;
}

kernel void Kernel3(global struct S *s)
{
    s->e[0].v.y = 1;
    s->e[1].v.y = 1;
}

kernel void Kernel(global struct S *s)
{
    s->e[0].v.x = 1;
    s->e[1].v.y = 1;
}
