// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 28
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability Int16
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_16:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_16]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_v2ushort:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate %[[_struct_4:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_4]] Block
// CHECK:     OpDecorate %[[__original_id_13:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_13]] Binding 0
// CHECK:     OpDecorate %[[__original_id_14:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_14]] Binding 1
// CHECK:     OpDecorate %[[__original_id_15:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_15]] Binding 2
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[_runtimearr_v2ushort]] = OpTypeRuntimeArray %[[v2ushort]]
// CHECK-DAG: %[[_struct_4]] = OpTypeStruct %[[_runtimearr_v2ushort]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_4:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_4]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_7:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_ptr_StorageBuffer_v2ushort:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v2ushort]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ushort_65535:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 65535
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_65535]] %[[ushort_65535]]
// CHECK-DAG: %[[__original_id_13]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_14]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_15]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:     %[[__original_id_16]] = OpFunction %[[void]] None %[[__original_id_7]]
// CHECK:     %[[__original_id_17:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_18:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2ushort]] %[[__original_id_13]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2ushort]] %[[__original_id_14]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2ushort]] %[[__original_id_15]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[v2ushort]] %[[__original_id_18]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLoad %[[v2ushort]] %[[__original_id_19]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[v2ushort]] %[[__original_id_20]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpBitwiseXor %[[v2ushort]] %[[__original_id_23]] %[[__original_id_12]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpBitwiseAnd %[[v2ushort]] %[[__original_id_21]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpBitwiseAnd %[[v2ushort]] %[[__original_id_23]] %[[__original_id_22]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpBitwiseOr %[[v2ushort]] %[[__original_id_25]] %[[__original_id_26]]
// CHECK:     OpStore %[[__original_id_18]] %[[__original_id_27]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort2* a, global ushort2* b, global ushort2* c)
{
    *a = bitselect(*a, *b, *c);
}

