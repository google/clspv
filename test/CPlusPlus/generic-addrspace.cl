// RUN: clspv %target -cl-std=CLC++ -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_runtimearr_uint:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[_struct_7:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_7:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_7]]
// CHECK-DAG: %[[_ptr_Workgroup_uint:[0-9a-zA-Z_]+]] = OpTypePointer Workgroup %[[uint]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_11:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[_ptr_StorageBuffer_uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[uint]]
// CHECK-DAG: %[[__spc_1:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__spc_2:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__spc_3:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_2:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[_arr_uint_2:[0-9a-zA-Z_]+]] = OpTypeArray %[[uint]] %[[__original_id_2]]
// CHECK-DAG: %[[_ptr_Workgroup__arr_uint_2:[0-9a-zA-Z_]+]] = OpTypePointer Workgroup %[[_arr_uint_2]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_42:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 42
// CHECK-DAG: %[[__original_id_22:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK-DAG: %[[__original_id_1:[0-9]+]] = OpVariable %[[_ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK:     %[[__original_id_23:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_11]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_25:[0-9]+]] = OpAccessChain %[[_ptr_Workgroup_uint]] %[[__original_id_1]] %[[uint_0]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_22]] %[[uint_0]] %[[uint_0]]
// CHECK:     OpStore %[[__original_id_26]] %[[uint_42]]
// CHECK:     OpStore %[[__original_id_25]] %[[uint_42]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


void fill(int* out) {
    *out = 42;
}

void kernel test(global int* gout, local int* lout) {
    fill(gout);
    fill(lout);
}

