// RUN: clspv --cl-std=CL2.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* out, global atomic_int* a) {
  *out = atomic_load(a);
}

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_66:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 66
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[uint_1]] [[uint_66]]
