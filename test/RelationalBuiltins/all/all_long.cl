// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 24
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability Int64
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_17:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_17]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_uint:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate %[[_struct_3:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_3]] Block
// CHECK:     OpDecorate %[[_runtimearr_ulong:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_7:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_7]] Block
// CHECK:     OpDecorate %[[__original_id_15:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_15]] Binding 0
// CHECK:     OpDecorate %[[__original_id_16:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_16]] Binding 1
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_runtimearr_uint]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[_struct_3]] = OpTypeStruct %[[_runtimearr_uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_3:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_3]]
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[_runtimearr_ulong]] = OpTypeRuntimeArray %[[ulong]]
// CHECK-DAG: %[[_struct_7]] = OpTypeStruct %[[_runtimearr_ulong]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_7:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_7]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_10:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[_ptr_StorageBuffer_uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer_ulong:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[ulong]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[ulong_63:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 63
// CHECK-DAG: %[[__original_id_15]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG: %[[__original_id_16]] = OpVariable %[[_ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:     %[[__original_id_17]] = OpFunction %[[void]] None %[[__original_id_10]]
// CHECK:     %[[__original_id_18:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_19:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_15]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_ulong]] %[[__original_id_16]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLoad %[[ulong]] %[[__original_id_20]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpShiftRightLogical %[[ulong]] %[[__original_id_21]] %[[ulong_63]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpUConvert %[[uint]] %[[__original_id_22]]
// CHECK:     OpStore %[[__original_id_19]] %[[__original_id_23]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global long* b)
{
    *a = all(*b);
}

