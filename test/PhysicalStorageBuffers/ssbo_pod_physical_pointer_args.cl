// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -no-16bit-storage=ubo -max-pushconstant-size=1 -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-TYPED,CHECK-CLUSTERED
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -no-16bit-storage=ubo -max-pushconstant-size=1 -spv-version=1.4 -untyped-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-UNTYPED,CHECK-CLUSTERED
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -no-16bit-storage=ubo -max-pushconstant-size=1 -cluster-pod-kernel-args=0 -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-NOCLUSTER
// RUN: spirv-val --target-env vulkan1.2 %t.spv

kernel void foo(short data, global short *out) {
  *out = data;
}

// CHECK: OpExtension "SPV_KHR_physical_storage_buffer"
// CHECK: [[ClspvReflection:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: OpMemoryModel PhysicalStorageBuffer64 GLSL450
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ushort:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK-DAG: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8

// CHECK-TYPED-DAG: [[inner_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ushort]] [[ulong]]
// CHECK-TYPED-DAG: [[outer_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[inner_struct]]
// CHECK-TYPED-DAG: [[ptr_ssbo_outer:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[outer_struct]]
// CHECK-TYPED-DAG: [[ptr_physical_ushort:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[ushort]]
// CHECK-TYPED: OpVariable [[ptr_ssbo_outer]] StorageBuffer

// CHECK-UNTYPED-DAG: [[ptr_ssbo:%[a-zA-Z0-9_]+]] = OpTypeUntypedPointerKHR StorageBuffer
// CHECK-UNTYPED-DAG: [[inner_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ushort]] [[ulong]]
// CHECK-UNTYPED-DAG: [[outer_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[inner_struct]]
// CHECK-UNTYPED-DAG: [[ptr_physical:%[a-zA-Z0-9_]+]] = OpTypeUntypedPointerKHR PhysicalStorageBuffer
// CHECK-UNTYPED: OpUntypedVariableKHR [[ptr_ssbo]] StorageBuffer [[outer_struct]]

// CHECK-NOCLUSTER-DAG: [[struct_ushort:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ushort]]
// CHECK-NOCLUSTER-DAG: [[ptr_ssbo_ushort:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct_ushort]]
// CHECK-NOCLUSTER-DAG: [[struct_ulong:%[a-zA-Z0-9_]+]] = OpTypeStruct [[ulong]]
// CHECK-NOCLUSTER-DAG: [[ptr_ubo_ulong:%[a-zA-Z0-9_]+]] = OpTypePointer Uniform [[struct_ulong]]
// CHECK-NOCLUSTER: OpVariable [[ptr_ssbo_ushort]] StorageBuffer
// CHECK-NOCLUSTER: OpVariable [[ptr_ubo_ulong]] Uniform

// CHECK: [[KernelReflection:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] [[ClspvReflection]] Kernel
// CHECK-CLUSTERED: OpExtInst [[void]] [[ClspvReflection]] ArgumentPodStorageBuffer [[KernelReflection]] [[uint_0]] [[uint_0]] [[uint_0]] [[uint_0]] [[uint_2]]
// CHECK-CLUSTERED: OpExtInst [[void]] [[ClspvReflection]] ArgumentPointerUniform [[KernelReflection]] [[uint_1]] [[uint_0]] [[uint_0]] [[uint_8]] [[uint_8]]
// CHECK-NOCLUSTER: OpExtInst [[void]] [[ClspvReflection]] ArgumentPodStorageBuffer [[KernelReflection]] [[uint_0]] [[uint_0]] [[uint_0]] [[uint_0]] [[uint_2]]
// CHECK-NOCLUSTER: OpExtInst [[void]] [[ClspvReflection]] ArgumentPointerUniform [[KernelReflection]] [[uint_1]] [[uint_0]] [[uint_1]] [[uint_0]] [[uint_8]]
