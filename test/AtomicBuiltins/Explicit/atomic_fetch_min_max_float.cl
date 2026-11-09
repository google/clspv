// RUN: clspv %target --cl-std=CL3.0 --enable-feature-macros=__opencl_c_atomic_order_seq_cst,__opencl_c_atomic_scope_device,__opencl_c_atomic_order_acq_rel,__opencl_c_ext_fp32_global_atomic_min_max,__opencl_c_ext_fp32_local_atomic_min_max --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s --implicit-check-not=OpAtomicSMin --implicit-check-not=OpAtomicSMax < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Floating-point atomic min/max must not be lowered to the integer
// OpAtomicSMin/OpAtomicSMax, which compare the raw bits as signed integers.

// CHECK: OpCapability AtomicFloat32MinMaxEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_min_max"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[value:%[a-zA-Z0-9_.]+]] = OpConstant [[float]] 7{{$}}
// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72{{$}}
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264{{$}}

// CHECK: OpAtomicFMinEXT [[float]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicFMinEXT [[float]] {{.*}} [[dv]] [[Rx]] [[value]]
// CHECK: OpAtomicFMaxEXT [[float]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[value]]
// CHECK: OpAtomicFMaxEXT [[float]] {{.*}} [[dv]] [[Rx]] [[value]]
// CHECK: OpAtomicFMinEXT [[float]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicFMinEXT [[float]] {{.*}} [[wg]] [[Rx]] [[value]]
// CHECK: OpAtomicFMaxEXT [[float]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[value]]
// CHECK: OpAtomicFMaxEXT [[float]] {{.*}} [[wg]] [[Rx]] [[value]]

kernel void foo(global float *out, volatile global atomic_float *a,
                volatile local atomic_float *b) {
  out[0] = atomic_fetch_min(a, 7.0f);
  out[1] = atomic_fetch_min_explicit(a, 7.0f, memory_order_relaxed,
                                     memory_scope_device);
  out[2] = atomic_fetch_max(a, 7.0f);
  out[3] = atomic_fetch_max_explicit(a, 7.0f, memory_order_relaxed,
                                     memory_scope_device);

  out[4] = atomic_fetch_min(b, 7.0f);
  out[5] = atomic_fetch_min_explicit(b, 7.0f, memory_order_relaxed,
                                     memory_scope_work_group);
  out[6] = atomic_fetch_max(b, 7.0f);
  out[7] = atomic_fetch_max_explicit(b, 7.0f, memory_order_relaxed,
                                     memory_scope_work_group);
}
