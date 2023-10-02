; RUN: clspv %s -o %t.spv 
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val %t.spv

__attribute__((work_group_size_hint(1,1,1)))
__attribute__((reqd_work_group_size(1,1,1)))
__kernel void add(global int *A, global int *B) {
  // Add 1 to each element of the input buffer.
  for (unsigned int i = 0; i < get_global_size(0); i++) {
    B[i] = A[i] + 1;
  }
}

// kernel1.clspv
kernel void main_kernel(global int* A, global int* B) {
  // Call the function.
  add(A, B);
}

// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "add"
// CHECK: [[attributes:%[^ ]+]] = OpString " __attribute__((work_group_size_hint(1, 1, 1))) __attribute__((reqd_work_group_size(1, 1, 1))) __kernel"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "A"
// CHECK-DAG: [[arg1name:%[a-zA-Z0-9_]+]] = OpString "B"
// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "main_kernel"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "A"
// CHECK-DAG: [[arg1name:%[a-zA-Z0-9_]+]] = OpString "B"
// CHECK: OpExtInst %void {{.*}} Kernel {{.*}} {{.*}} {{.*}} {{.*}} [[attributes]]
