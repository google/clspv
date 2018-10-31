// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 29
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability Int64
// CHECK-DAG: OpCapability VariablePointers
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpExtension "SPV_KHR_variable_pointers"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_21:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_21]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_uint:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate %[[_struct_3:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_3]] Block
// CHECK:     OpDecorate %[[_runtimearr_v2ulong:[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:     OpMemberDecorate %[[_struct_8:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_8]] Block
// CHECK:     OpDecorate %[[__original_id_19:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_19]] Binding 0
// CHECK:     OpDecorate %[[__original_id_20:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_20]] Binding 1
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_runtimearr_uint]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[_struct_3]] = OpTypeStruct %[[_runtimearr_uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_3:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_3]]
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[_runtimearr_v2ulong]] = OpTypeRuntimeArray %[[v2ulong]]
// CHECK-DAG: %[[_struct_8]] = OpTypeStruct %[[_runtimearr_v2ulong]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_8:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_8]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_11:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[_ptr_StorageBuffer_uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer_v2ulong:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v2ulong]]
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v2ulong]]
// CHECK-DAG: %[[__original_id_19]] = OpVariable %[[_ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK-DAG: %[[__original_id_20]] = OpVariable %[[_ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:     %[[__original_id_21]] = OpFunction %[[void]] None %[[__original_id_11]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_23:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_19]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2ulong]] %[[__original_id_20]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[v2ulong]] %[[__original_id_24]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_25]] %[[__original_id_18]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpAny %[[bool]] %[[__original_id_26]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_27]] %[[uint_1]] %[[uint_0]]
// CHECK:     OpStore %[[__original_id_23]] %[[__original_id_28]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global long2* b)
{
    *a = any(*b);
}

