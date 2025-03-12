// RUN: clspv %target --cl-std=CL2.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[value:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 7{{$}}

// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}

// CHECK-DAG: [[Acq_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 66{{$}}
// CHECK-DAG: [[Rel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 68{{$}}
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72{{$}}

// CHECK-DAG: [[Acq_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 258{{$}}
// CHECK-DAG: [[Rel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 260{{$}}
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264{{$}}

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Acq_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Rx]] [[value]]

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Acq_Uniform]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Rx]] [[value]]

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Acq_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[dv]] [[Rx]] [[value]]

// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Acq_Workgroup]] [[value]]
// CHECK: OpAtomicSMin [[uint]] {{.*}} [[wg]] [[Rx]] [[value]]

kernel void foo(global bool* out, global atomic_int* a, local atomic_int* b) {

    *out = atomic_fetch_min(a, 7);

    *out = atomic_fetch_min_explicit(a, 7, memory_order_acq_rel, memory_scope_device);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_release, memory_scope_device);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_acquire, memory_scope_device);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_relaxed, memory_scope_device);

    *out = atomic_fetch_min_explicit(a, 7, memory_order_acq_rel, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_release, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_acquire, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(a, 7, memory_order_relaxed, memory_scope_work_group);

    *out = atomic_fetch_min(b, 7);

    *out = atomic_fetch_min_explicit(b, 7, memory_order_acq_rel, memory_scope_device);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_release, memory_scope_device);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_acquire, memory_scope_device);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_relaxed, memory_scope_device);

    *out = atomic_fetch_min_explicit(b, 7, memory_order_acq_rel, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_release, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_acquire, memory_scope_work_group);
    *out = atomic_fetch_min_explicit(b, 7, memory_order_relaxed, memory_scope_work_group);
}
