// RUN: clspv %target %s -o %t.spv -arch=spir64 -physical-storage-buffers -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

kernel void test(global ulong *a, global int *b)
{
    size_t tid = get_global_id(0);
    a[tid] = (ulong) &b[tid];
}

// CHECK: [[clspv_reflection:%[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK-DAG: OpDecorate [[ptr_physical_ulong:%[a-zA-Z0-9_]+]] ArrayStride 8
// CHECK-DAG: OpDecorate [[global_id:%[a-zA-Z0-9_]+]] BuiltIn GlobalInvocationId
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32
// CHECK-DAG: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[ulong_2:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 2
// CHECK-DAG: [[ptr_physical_ulong]] = OpTypePointer PhysicalStorageBuffer [[ulong]]
// CHECK-DAG: [[pod_struct_ty:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ulong]] [[ulong]]

// CHECK: [[pod_struct:%[a-zA-Z0-9_]+]] = OpLoad [[pod_struct_ty]]
// CHECK: [[copy:%[a-zA-Z0-9_]+]] = OpCopyLogical {{.*}} [[pod_struct]]
// CHECK: [[ptr_int_a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[ulong]] [[copy]] 0
// CHECK: [[ptr_int_b:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[ulong]] [[copy]] 1
// CHECK: [[ptr_a:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_physical_ulong]] [[ptr_int_a]]
// CHECK: [[gid_x_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %{{[a-zA-Z0-9_]+}} [[global_id]] [[uint_0]]
// CHECK: [[gid_x_load:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gid_x_ptr]]
// CHECK: [[gid_x:%[a-zA-Z0-9_]+]] = OpUConvert [[ulong]] [[gid_x_load]]
// CHECK: [[gid_x_shift:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[ulong]] [[gid_x]] [[ulong_2]]
// CHECK: [[ptr_b_offset_int:%[a-zA-Z0-9_]+]] = OpIAdd [[ulong]] [[gid_x_shift]] [[ptr_int_b]]
// CHECK: [[ptr_a_offset:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr_physical_ulong]] [[ptr_a]] [[gid_x]]
// CHECK: OpStore [[ptr_a_offset]] [[ptr_b_offset_int]] Aligned 8
