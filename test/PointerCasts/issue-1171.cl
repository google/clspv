// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// RUN: clspv %s -o %t.spv -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct S {
    int i;
};

kernel void Kernel1(global struct S *s1, global struct S *s2)
{
    s2->i = 0;
    *s1 = *s2;
}

kernel void Kernel2(global struct S *s1, global struct S *s2)
{
    *s1 = *s2;
    s2->i = 0;
}

kernel void Kernel3(global struct S *s1, global struct S *s2)
{
    *s1 = *s2;
    s1->i = 0;
}

kernel void Kernel4(global struct S *s1, global struct S *s2)
{
    *s2 = *s1;
    s1->i = 0;
}

kernel void Kernel5(global struct S *s1, global struct S *s2)
{
    *s2 = *s1;
    s2->i = 0;
}
