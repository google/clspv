// RUN: clspv --cl-std=CL3.0 %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm

kernel void enum_values(global uint* out) {
  int i = 0;
  // Memory order
  out[i++] = memory_order_relaxed;
  out[i++] = memory_order_acquire;
  out[i++] = memory_order_release;
  out[i++] = memory_order_acq_rel;
  out[i++] = memory_order_seq_cst;

  // Memory scope
  out[i++] = memory_scope_work_item;
  out[i++] = memory_scope_work_group;
  out[i++] = memory_scope_device;
  out[i++] = memory_scope_all_svm_devices;
  out[i++] = memory_scope_sub_group;
}

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK: OpStore {{.*}} [[uint_0]]
// CHECK: OpStore {{.*}} [[uint_2]]
// CHECK: OpStore {{.*}} [[uint_3]]
// CHECK: OpStore {{.*}} [[uint_4]]
// CHECK: OpStore {{.*}} [[uint_5]]
// CHECK: OpStore {{.*}} [[uint_0]]
// CHECK: OpStore {{.*}} [[uint_1]]
// CHECK: OpStore {{.*}} [[uint_2]]
// CHECK: OpStore {{.*}} [[uint_3]]
// CHECK: OpStore {{.*}} [[uint_4]]
