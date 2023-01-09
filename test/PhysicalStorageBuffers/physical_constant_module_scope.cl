// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant int myconst[5] = { 0 };

kernel void test(global int *result) {
  size_t tid = get_global_id(0);
  result[tid] = myconst[tid];
}

// CHECK: OpExtension "SPV_KHR_physical_storage_buffer"
// CHECK: [[ClspvReflection:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: OpMemoryModel PhysicalStorageBuffer64
// CHECK: [[Initializer:%[a-zA-Z0-9_]+]] = OpString "0000000000000000000000000000000000000000"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32
// CHECK-DAG: [[ulong:%[a-zA-Z0-9_]+]] = OpTypeInt 64
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[arr_int_5:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[uint_5]]
// CHECK-DAG: [[arr_int_5_struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[arr_int_5]]
// CHECK-DAG: [[module_consts_pc_ptr_type:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant %ulong
// CHECK-DAG: [[module_consts_type:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[arr_int_5_struct]]
// CHECK-DAG: [[physical_int_ptr_type0:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[uint]]
// CHECK-DAG: [[physical_int_ptr_type1:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[uint]]

// CHECK: [[module_consts_pc_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[module_consts_pc_ptr_type]]
// CHECK: [[module_consts_ptr:%[a-zA-Z0-9_]+]] = OpLoad [[ulong]] [[module_consts_pc_ptr]] Aligned 8
// CHECK: [[module_consts_ptr_converted:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[module_consts_type]] [[module_consts_ptr]]
// CHECK: [[module_consts_gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[physical_int_ptr_type1]] [[module_consts_ptr_converted]]
// CHECK: OpLoad [[uint]] [[module_consts_gep]] Aligned 4

// CHECK: OpExtInst [[void]] [[ClspvReflection]] ConstantDataPointerPushConstant [[uint_0]] [[uint_8]] [[Initializer]]
