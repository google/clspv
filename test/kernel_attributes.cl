// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm

// CHECK: [[attributes:%[^ ]+]] = OpString " __attribute__((work_group_size_hint(1, 1, 1))) __attribute__((reqd_work_group_size(1, 1, 1))) __attribute__((vec_type_hint(uchar2))) __kernel"
// CHECK: OpExtInst %void {{.*}} Kernel {{.*}} {{.*}} {{.*}} {{.*}} [[attributes]]

__attribute__((work_group_size_hint(1,1,1)))
__attribute__((reqd_work_group_size(1,1,1)))
__attribute__((vec_type_hint(uchar2)))
__kernel void test_kernel(){}
