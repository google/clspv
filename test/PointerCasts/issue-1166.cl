// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// RUN: clspv %s -o %t.spv -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck --check-prefix=UNTYPED %s < %t.spvasm

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_3705032704:%[^ ]+]] = OpConstant [[uint]] 3705032704

// CHECK: OpStore %{{.*}} [[uint_3705032704]]
// CHECK: OpStore %{{.*}} [[uint_1]]

// UNTYPED-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// UNTYPED-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0

// UNTYPED-DAG: [[ulong_val:%[^ ]+]] = OpConstant [[ulong]] 8000000000
// UNTYPED-DAG: [[uint_77:%[^ ]+]] = OpConstant [[uint]] 77
// UNTYPED-DAG: [[uint_88:%[^ ]+]] = OpConstant [[uint]] 88

// UNTYPED: OpStore %{{.*}} [[ulong_val]]
// UNTYPED: OpStore %{{.*}} [[uint_77]]
// UNTYPED: OpStore %{{.*}} [[uint_88]]


struct S { long i1; int i2; int i3; };

kernel void Kernel(global struct S* s)
{
    s->i1 = 8000000000UL;
    s->i2 = 77;
    s->i3 = 88;
}
