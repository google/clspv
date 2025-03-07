// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers -pod-pushconstant -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-PC
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers -pod-ubo -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-UBO
// RUN: spirv-val --target-env vulkan1.2 %t.spv

kernel void copy(constant short *a, global int *b, int x, int y) {
    size_t gid = get_global_id(0);
    b[gid] = (int) a[gid] + x + y;
}

// CHECK: OpExtension "SPV_KHR_physical_storage_buffer"
// CHECK: [[ClspvReflection:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: OpMemoryModel PhysicalStorageBuffer64
// CHECK-DAG: OpDecorate [[ptr_physical_ushort:%[a-zA-Z0-9_]+]] ArrayStride 2
// CHECK-DAG: OpDecorate [[ptr_physical_uint:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK-DAG: [[ushort:%[a-zA-Z0-9_]+]] = OpTypeInt 16
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32
// CHECK-DAG: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64
// CHECK-DAG: [[pod_struct_ty:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ulong]] [[ulong]] [[uint]] [[uint]]
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[ptr_physical_ushort]] = OpTypePointer PhysicalStorageBuffer [[ushort]]
// CHECK-DAG: [[ptr_physical_uint]] = OpTypePointer PhysicalStorageBuffer [[uint]]

// CHECK: [[pod_struct:%[a-zA-Z0-9_]+]] = OpLoad [[pod_struct_ty]]
// CHECK: [[copy:%[a-zA-Z0-9_]+]] = OpCopyLogical {{.*}} [[pod_struct]]
// CHECK: [[ptr_int_a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[ulong]] [[copy]] 0
// CHECK: [[ptr_int_b:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[ulong]] [[copy]] 1
// CHECK: [[ptr_a:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_physical_ushort]] [[ptr_int_a]]
// CHECK: [[ptr_b:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_physical_uint]] [[ptr_int_b]]
// CHECK: [[ptr_a_access_chain:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr_physical_ushort]] [[ptr_a]]
// CHECK: OpLoad [[ushort]] [[ptr_a_access_chain]] Aligned 2
// CHECK: [[ptr_b_access_chain:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr_physical_uint]] [[ptr_b]]
// CHECK: OpStore [[ptr_b_access_chain]] %{{[a-zA-Z0-9_]+}} Aligned 4

// CHECK: [[KernelReflection:%[a-zA-Z0-9_]+]] = OpExtInst %void [[ClspvReflection]] Kernel
// CHECK-PC: OpExtInst %void [[ClspvReflection]] ArgumentPointerPushConstant [[KernelReflection]] [[uint_0]] [[uint_0]] [[uint_8]]
// CHECK-PC: OpExtInst %void [[ClspvReflection]] ArgumentPointerPushConstant [[KernelReflection]] [[uint_1]] [[uint_8]] [[uint_8]]
// CHECK-UBO: OpExtInst %void [[ClspvReflection]] ArgumentPointerUniform [[KernelReflection]] [[uint_0]] %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} [[uint_0]] [[uint_8]]
// CHECK-UBO: OpExtInst %void [[ClspvReflection]] ArgumentPointerUniform [[KernelReflection]] [[uint_1]] %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} [[uint_8]] [[uint_8]]
