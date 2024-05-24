// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant char myconst[5] = { 42 };

kernel void test(global ulong *a, constant int *b)
{
    size_t tid = get_global_id(0);
    a[tid] = (ulong) &b[tid];
    a[tid + 1] = (ulong) &myconst[tid];
}

// CHECK: [[clspv_reflection:%[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32
// CHECK-DAG: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64
// CHECK-DAG: [[ptr_physical_ulong:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[ulong]]
// CHECK-DAG: OpDecorate [[ptr_physical_ulong]] ArrayStride 8
// CHECK-DAG: OpDecorate [[global_id:%[a-zA-Z0-9_]+]] BuiltIn GlobalInvocationId
// CHECK-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[ulong_2:%[a-zA-Z0-9_]+]] = OpConstant [[ulong]] 2
// CHECK-DAG: [[arr_uchar_5:%[a-zA-Z0-9_]+]] = OpTypeArray [[uchar]] [[uint_5]]
// CHECK-DAG: [[arr_uchar_5_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[arr_uchar_5]]
// CHECK-DAG: [[ptr_physical_arr_uchar_5:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[arr_uchar_5_struct]]
// CHECK-DAG: [[ptr_physical_uchar:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[uchar]]

// CHECK: [[ptr_a_int:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[ulong]]
// CHECK: [[ptr_b_int:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[ulong]]
// CHECK: [[ptr_a:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_physical_ulong]] [[ptr_a_int]]
// CHECK: [[gid_x_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %{{[a-zA-Z0-9_]+}} [[global_id]] [[uint_0]]
// CHECK: [[gid_x_load:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gid_x_ptr]]
// CHECK: [[gid_x:%[a-zA-Z0-9_]+]] = OpUConvert [[ulong]] [[gid_x_load]]
// CHECK: [[gid_x_shift:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[ulong]] [[gid_x]] [[ulong_2]]
// CHECK: [[ptr_b_offset_int:%[a-zA-Z0-9_]+]] = OpIAdd [[ulong]] [[ptr_b_int]] [[gid_x_shift]]
// CHECK: [[ptr_a_offset:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr_physical_ulong]] [[ptr_a]] [[gid_x]]
// CHECK: OpStore [[ptr_a_offset]] [[ptr_b_offset_int]] Aligned 8
// CHECK: [[ptr_consts:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_physical_arr_uchar_5]]
// CHECK: [[ptr_consts_offset:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_physical_uchar]] [[ptr_consts]]
// CHECK: [[ptr_consts_offset_int:%[a-zA-Z0-9_]+]] = OpConvertPtrToU [[ulong]] [[ptr_consts_offset]]
// CHECK: OpStore {{%[a-zA-Z0-9_]+}} [[ptr_consts_offset_int]] Aligned 8
