// RUN: clspv %target --cl-std=CL2.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0

// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[Acq_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 66{{$}}
// CHECK-DAG: [[Acq_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 258{{$}}

// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dv]] [[Acq_Uniform]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dv]] [[Acq_Uniform]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dv]] [[Rx]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[Acq_Uniform]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[Rx]]

// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[Acq_Workgroup]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dv]] [[Acq_Workgroup]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[dv]] [[Rx]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[Acq_Workgroup]]
// CHECK: OpAtomicLoad [[uint]] {{.*}} [[wg]] [[Rx]]

kernel void foo(global int* out, global atomic_int* a, local atomic_int* b) {

  *out = atomic_load(a);
  *out = atomic_load_explicit(a, memory_order_acquire, memory_scope_device);
  *out = atomic_load_explicit(a, memory_order_relaxed, memory_scope_device);
  *out = atomic_load_explicit(a, memory_order_acquire, memory_scope_work_group);
  *out = atomic_load_explicit(a, memory_order_relaxed, memory_scope_work_group);

  *out = atomic_load(b);
  *out = atomic_load_explicit(b, memory_order_acquire, memory_scope_device);
  *out = atomic_load_explicit(b, memory_order_relaxed, memory_scope_device);
  *out = atomic_load_explicit(b, memory_order_acquire, memory_scope_work_group);
  *out = atomic_load_explicit(b, memory_order_relaxed, memory_scope_work_group);
}
