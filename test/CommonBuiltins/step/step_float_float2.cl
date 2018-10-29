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
// CHECK-DAG: OpCapability VariablePointers
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpExtension "SPV_KHR_variable_pointers"
// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_19:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_19]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_float:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate %[[_struct_4:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_4]] Block
// CHECK:     OpDecorate %[[_runtimearr_v2float:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_8:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_8]] Block
// CHECK:     OpDecorate %[[__original_id_17:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_17]] Binding 0
// CHECK:     OpDecorate %[[__original_id_18:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_18]] Binding 1
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[_runtimearr_float]] = OpTypeRuntimeArray %[[float]]
// CHECK-DAG: %[[_struct_4]] = OpTypeStruct %[[_runtimearr_float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_4:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_4]]
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[_runtimearr_v2float]] = OpTypeRuntimeArray %[[v2float]]
// CHECK-DAG: %[[_struct_8]] = OpTypeStruct %[[_runtimearr_v2float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_8:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_8]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_11:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_ptr_StorageBuffer_float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[float]]
// CHECK-DAG: %[[_ptr_StorageBuffer_v2float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v2float]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     %[[__original_id_16:[0-9]+]] = OpUndef %[[v2float]]
// CHECK-DAG: %[[__original_id_17]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_18]] = OpVariable %[[_ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:     %[[__original_id_19]] = OpFunction %[[void]] None %[[__original_id_11]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_21:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[__original_id_17]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_22:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2float]] %[[__original_id_18]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLoad %[[float]] %[[__original_id_21]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpLoad %[[v2float]] %[[__original_id_22]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpCompositeInsert %[[v2float]] %[[__original_id_23]] %[[__original_id_16]] 0
// CHECK:     %[[__original_id_26:[0-9]+]] = OpVectorShuffle %[[v2float]] %[[__original_id_25]] %[[__original_id_16]] 0 0
// CHECK:     %[[__original_id_27:[0-9]+]] = OpExtInst %[[v2float]] %[[__original_id_1]] Step %[[__original_id_26]] %[[__original_id_24]]
// CHECK:     OpStore %[[__original_id_22]] %[[__original_id_27]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float2* b)
{
    *b = step(*a, *b);
}

