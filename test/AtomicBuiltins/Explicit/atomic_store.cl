// RUN: clspv %target --cl-std=CL2.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[value:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 7{{$}}

// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[Rel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 68{{$}}
// CHECK-DAG: [[Rel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 260{{$}}

// CHECK: OpAtomicStore {{.*}} [[dv]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[dv]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[dv]] [[Rx]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[wg]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[wg]] [[Rx]] [[value]]

// CHECK: OpAtomicStore {{.*}} [[wg]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[dv]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[dv]] [[Rx]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[wg]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicStore {{.*}} [[wg]] [[Rx]] [[value]]

kernel void foo(global atomic_int* a, local atomic_int* b) {

  atomic_store(a, 7);
  atomic_store_explicit(a, 7, memory_order_release, memory_scope_device);
  atomic_store_explicit(a, 7, memory_order_relaxed, memory_scope_device);
  atomic_store_explicit(a, 7, memory_order_release, memory_scope_work_group);
  atomic_store_explicit(a, 7, memory_order_relaxed, memory_scope_work_group);

  atomic_store(b, 7);
  atomic_store_explicit(b, 7, memory_order_release, memory_scope_device);
  atomic_store_explicit(b, 7, memory_order_relaxed, memory_scope_device);
  atomic_store_explicit(b, 7, memory_order_release, memory_scope_work_group);
  atomic_store_explicit(b, 7, memory_order_relaxed, memory_scope_work_group);
}
