// RUN: clspv %target --cl-std=CL3.0 -fp64 --enable-feature-macros=__opencl_c_fp64,__opencl_c_atomic_order_seq_cst,__opencl_c_atomic_scope_device,__opencl_c_atomic_order_acq_rel,__opencl_c_ext_fp64_global_atomic_min_max,__opencl_c_ext_fp64_local_atomic_min_max --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s --implicit-check-not=OpAtomicSMin --implicit-check-not=OpAtomicSMax < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability AtomicFloat64MinMaxEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_min_max"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK-DAG: [[val:%[a-zA-Z0-9_.]+]] = OpConstant [[double]] 7{{$}}
// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72{{$}}
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264{{$}}

// CHECK: OpAtomicFMinEXT [[double]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[val]]
// CHECK: OpAtomicFMinEXT [[double]] {{.*}} [[dv]] [[Rx]] [[val]]
// CHECK: OpAtomicFMaxEXT [[double]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[val]]
// CHECK: OpAtomicFMaxEXT [[double]] {{.*}} [[dv]] [[Rx]] [[val]]
// CHECK: OpAtomicFMinEXT [[double]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[val]]
// CHECK: OpAtomicFMinEXT [[double]] {{.*}} [[wg]] [[Rx]] [[val]]
// CHECK: OpAtomicFMaxEXT [[double]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[val]]
// CHECK: OpAtomicFMaxEXT [[double]] {{.*}} [[wg]] [[Rx]] [[val]]

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

kernel void foo(global double* out, volatile global atomic_double* a, volatile local atomic_double* b) {
    *out = atomic_fetch_min(a, 7.0);
    *out = atomic_fetch_min_explicit(a, 7.0, memory_order_relaxed, memory_scope_device);
    *out = atomic_fetch_max(a, 7.0);
    *out = atomic_fetch_max_explicit(a, 7.0, memory_order_relaxed, memory_scope_device);
    *out = atomic_fetch_min(b, 7.0);
    *out = atomic_fetch_min_explicit(b, 7.0, memory_order_relaxed, memory_scope_work_group);
    *out = atomic_fetch_max(b, 7.0);
    *out = atomic_fetch_max_explicit(b, 7.0, memory_order_relaxed, memory_scope_work_group);
}
