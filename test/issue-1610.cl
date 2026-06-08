// RUN: clspv %s -o %t.spv -cl-std=CL3.0 --enable-feature-macros=__opencl_c_generic_address_space -inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK-DAG: [[null_ptr:%[^ ]+]] = OpConstantNull [[uint_ptr]]
// CHECK-DAG: [[out:%[^ ]+]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[gep:%[^ ]+]] = OpAccessChain [[uint_ptr]] [[out]]
// CHECK: [[load:%[^ ]+]] = OpLoad [[uint]] [[null_ptr]]
// CHECK: OpStore [[gep]] [[load]]

__kernel void mykernel(__global int* out) {
 __global int* foo = NULL;
 *out = *foo;
}
