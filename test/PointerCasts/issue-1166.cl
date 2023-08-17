// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK: [[ulong_8000000000:%[^ ]+]] = OpConstant [[ulong]] 8000000000

// CHECK: OpStore {{.*}} [[ulong_8000000000]]

struct S { long i1; int i2; int i3; };

kernel void Kernel(global struct S* s)
{
    s->i1 = 8000000000UL;
    s->i2 = 77;
    s->i3 = 88;
}
