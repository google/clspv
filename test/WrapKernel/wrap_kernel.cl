// ; RUN: clspv %s -o %t.spv 
// ; RUN: spirv-dis -o %t2.spvasm %t.spv
// ; RUN: FileCheck %s < %t2.spvasm
// ; RUN: spirv-val %t.spv

__attribute__((work_group_size_hint(1,1,1)))
__attribute__((reqd_work_group_size(1,1,1)))
__kernel void add(global int *A, global int *B) {
  // Add 1 to each element of the input buffer.
  for (unsigned int i = 0; i < get_global_size(0); i++) {
    B[i] = A[i] + 1;
  }
}

// kernel1.clspv
kernel void main_kernel(global int* C, global int* D) {
  // Call the function.
  add(C, D);
}

// CHECK: [[extinst:%[a-zA-A0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK-DAG: [[kernel_add_name:%[a-zA-Z0-9_]+]] = OpString "add"
// CHECK: [[attributes:%[^ ]+]] = OpString "__attribute__((work_group_size_hint(1, 1, 1)))__attribute__((reqd_work_group_size(1, 1, 1))) __kernel"
// CHECK-DAG: [[k0arg0:%[a-zA-Z0-9_]+]] = OpString "A"
// CHECK-DAG: [[k0arg1:%[a-zA-Z0-9_]+]] = OpString "B"
// CHECK-DAG: [[kernel_main_name:%[a-zA-Z0-9_]+]] = OpString "main_kernel"
// CHECK-DAG: [[k1arg0:%[a-zA-Z0-9_]+]] = OpString "C"
// CHECK-DAG: [[k1arg1:%[a-zA-Z0-9_]+]] = OpString "D"

// CHECK-DAG: [[kernel_add_def:%[a-zA-A0-9_]+]] = OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_add_name]] {{.*}} [[attributes]]
// CHECK-NEXT: OpExtInst %void [[extinst]] PropertyRequiredWorkgroupSize [[kernel_add_def]] {{.*}} {{.*}} {{.*}}
// CHECK: OpExtInst %void [[extinst]] ArgumentInfo [[k0arg0]]
// CHECK: OpExtInst %void [[extinst]] ArgumentInfo [[k0arg1]]
// CHECK-DAG: OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_main_name]] {{.*}} {{.*}} {{.*}}
// CHECK: OpExtInst %void [[extinst]] ArgumentInfo [[k1arg0]]
// CHECK: OpExtInst %void [[extinst]] ArgumentInfo [[k1arg1]]
