// RUN: clspv --cl-std=CL3.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global atomic_int* out) {
  if (get_local_id(0) == 0)
      atomic_init(out, 42);
}

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[uint_68:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 68
// CHECK: [[uint_42:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 42
// CHECK: [[output_buffer_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: OpAtomicStore [[output_buffer_ptr]] [[uint_1]] [[uint_68]] [[uint_42]]
