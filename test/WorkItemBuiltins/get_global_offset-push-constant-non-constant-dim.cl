// RUN: clspv -global-offset-push-constant %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     OpDecorate %[[_runtimearr_uint:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpDecorate %[[__original_id_19:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_19]] Binding 0
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_runtimearr_uint]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[_struct_3:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_3:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_3]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_7:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[_ptr_StorageBuffer_uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[uint]]
// CHECK-DAG: %[[__original_id_9:[0-9]+]] = OpTypeFunction %[[uint]] %[[uint]]
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[_struct_11:[0-9a-zA-Z_]+]] = OpTypeStruct %[[v3uint]]
// CHECK-DAG: %[[_ptr_PushConstant__struct_11:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[_struct_11]]
// CHECK-DAG: %[[_ptr_PushConstant_uint:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[uint]]
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_3:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpVariable %[[_ptr_PushConstant__struct_11]] PushConstant
// CHECK-DAG: %[[__original_id_19]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:     %[[__original_id_20:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_7]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_22:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_19]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_19]] %[[uint_0]] %[[uint_1]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_23]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpFunctionCall %[[uint]] %[[__original_id_26:[0-9]+]] %[[__original_id_24]]
// CHECK:     OpStore %[[__original_id_22]] %[[__original_id_25]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd
// CHECK:     %[[__original_id_26]] = OpFunction %[[uint]] Const %[[__original_id_9]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpFunctionParameter %[[uint]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpLabel
// CHECK:     %[[less:[a-zA-Z0-9_]+]] = OpULessThan %[[bool]] %[[__original_id_27]] %[[uint_3]]
// CHECK:     %[[select:[a-zA-Z0-9_]+]] = OpSelect %[[uint]] %[[less]] %[[__original_id_27]] %[[uint_0]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpAccessChain %[[_ptr_PushConstant_uint]] %[[__original_id_18]] %[[uint_0]] %[[select]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpLoad %[[uint]] %[[__original_id_29]]
// CHECK:     %[[__original_id_32:[0-9]+]] = OpSelect %[[uint]] %[[less]] %[[__original_id_30]] %[[uint_0]]
// CHECK:     OpReturnValue %[[__original_id_32]]
// CHECK:     OpFunctionEnd

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(global int *out) {
    out[0] = get_global_offset(out[1]);
}

