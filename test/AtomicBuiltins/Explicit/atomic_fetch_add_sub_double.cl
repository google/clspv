// RUN: clspv %target --cl-std=CL3.0 -fp64 --enable-feature-macros=__opencl_c_fp64,__opencl_c_atomic_order_seq_cst,__opencl_c_atomic_scope_device,__opencl_c_atomic_order_acq_rel,__opencl_c_ext_fp64_global_atomic_add,__opencl_c_ext_fp64_local_atomic_add --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability AtomicFloat64AddEXT
// CHECK: OpExtension "SPV_EXT_shader_atomic_float_add"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK-DAG: [[pos_val:%[a-zA-Z0-9_.]+]] = OpConstant [[double]] 7{{$}}
// CHECK-DAG: [[neg_val:%[a-zA-Z0-9_.]+]] = OpConstant [[double]] -7{{$}}
// CHECK-DAG: [[dv:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[wg:%[a-zA-Z0-9_.]+]] = OpConstant [[uint]] 2{{$}}
// CHECK-DAG: [[Rx:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0{{$}}
// CHECK-DAG: [[AcqRel_Uniform:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 72{{$}}
// CHECK-DAG: [[AcqRel_Workgroup:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264{{$}}

// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[pos_val]]
// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[dv]] [[Rx]] [[pos_val]]
// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[dv]] [[AcqRel_Uniform]] [[neg_val]]
// CHECK: [[neg:%[a-zA-Z0-9_]+]] = OpFNegate [[double]]
// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[dv]] [[Rx]] [[neg]]
// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[pos_val]]
// CHECK: OpAtomicFAddEXT [[double]] {{.*}} [[wg]] [[AcqRel_Workgroup]] [[neg_val]]

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

kernel void foo(global double* out, volatile global atomic_double* a, volatile local atomic_double* b, double v) {
    *out = atomic_fetch_add(a, 7.0);
    *out = atomic_fetch_add_explicit(a, 7.0, memory_order_relaxed, memory_scope_device);
    *out = atomic_fetch_sub(a, 7.0);
    *out = atomic_fetch_sub_explicit(a, v, memory_order_relaxed, memory_scope_device);
    *out = atomic_fetch_add(b, 7.0);
    *out = atomic_fetch_sub(b, 7.0);
}
