// RUN: clspv %target --cl-std=CL3.0 --enable-feature-macros=__opencl_c_atomic_order_seq_cst,__opencl_c_atomic_scope_device,__opencl_c_atomic_order_acq_rel,__opencl_c_ext_fp32_global_atomic_add,__opencl_c_ext_fp32_local_atomic_add --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability AtomicFloat32AddEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_add"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[value:%[a-zA-Z0-9_.]+]] = OpConstant [[float]] -7{{$}}

// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}

// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}

// CHECK-DAG: [[Acq_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 66{{$}}
// CHECK-DAG: [[Rel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 68{{$}}
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72{{$}}

// CHECK-DAG: [[Acq_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 258{{$}}
// CHECK-DAG: [[Rel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 260{{$}}
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264{{$}}

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]
// CHECK: [[neg:%[a-zA-Z0-9_]+]] = OpFNegate [[float]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[neg]]

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Acq_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Rx]] [[value]]

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Rel_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Acq_Uniform]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Rx]] [[value]]

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Acq_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[dv]] [[Rx]] [[value]]

// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Rel_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Acq_Workgroup]] [[value]]
// CHECK: OpAtomicFAddEXT [[float]] {{.*}} [[wg]] [[Rx]] [[value]]

kernel void foo(global float* out, volatile global atomic_float* a, volatile local atomic_float* b, float v) {
    *out = atomic_fetch_sub(a, 7.0f);
    *out = atomic_fetch_sub(a, v);

    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_acq_rel, memory_scope_device);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_release, memory_scope_device);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_acquire, memory_scope_device);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_relaxed, memory_scope_device);

    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_acq_rel, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_release, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_acquire, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(a, 7.0f, memory_order_relaxed, memory_scope_work_group);

    *out = atomic_fetch_sub(b, 7.0f);

    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_acq_rel, memory_scope_device);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_release, memory_scope_device);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_acquire, memory_scope_device);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_relaxed, memory_scope_device);

    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_acq_rel, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_release, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_acquire, memory_scope_work_group);
    *out = atomic_fetch_sub_explicit(b, 7.0f, memory_order_relaxed, memory_scope_work_group);
}
