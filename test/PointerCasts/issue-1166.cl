// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_3705032704:%[^ ]+]] = OpConstant [[uint]] 3705032704

// CHECK: OpStore %{{.*}} [[uint_3705032704]]
// CHECK: OpStore %{{.*}} [[uint_1]]


struct S { long i1; int i2; int i3; };

kernel void Kernel(global struct S* s)
{
    s->i1 = 8000000000UL;
    s->i2 = 77;
    s->i3 = 88;
}
