// RUN: clspv %target --cl-std=CL3.0 --enable-feature-macros=__opencl_c_atomic_order_seq_cst,__opencl_c_atomic_scope_device,__opencl_c_atomic_order_acq_rel,__opencl_c_ext_fp32_global_atomic_add,__opencl_c_ext_fp32_local_atomic_add --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Floating-point atomics on local memory declared with an integer type.

// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[float]]
// CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[ptr]] Workgroup
// CHECK: OpAtomicFAddEXT [[float]] [[var]]
// CHECK: OpAtomicFAddEXT [[float]] [[var]]

kernel void foo(global float *out, float v) {
  local uint arr[1];
  out[0] = atomic_fetch_add_explicit((volatile local atomic_float *)arr, v,
                                     memory_order_relaxed,
                                     memory_scope_work_group);
  out[1] = atomic_fetch_sub_explicit((volatile local atomic_float *)arr, v,
                                     memory_order_relaxed,
                                     memory_scope_work_group);
}
