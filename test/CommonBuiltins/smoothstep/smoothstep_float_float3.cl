// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 33
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_20:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_20]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_float:[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate %[[_struct_4:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_4]] Block
// CHECK:     OpDecorate %[[_runtimearr_v3float:[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:     OpMemberDecorate %[[_struct_8:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_8]] Block
// CHECK:     OpDecorate %[[__original_id_17:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_17]] Binding 0
// CHECK:     OpDecorate %[[__original_id_18:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_18]] Binding 1
// CHECK:     OpDecorate %[[__original_id_19:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_19]] Binding 2
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[_runtimearr_float]] = OpTypeRuntimeArray %[[float]]
// CHECK-DAG: %[[_struct_4]] = OpTypeStruct %[[_runtimearr_float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_4:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_4]]
// CHECK-DAG: %[[v3float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 3
// CHECK-DAG: %[[_runtimearr_v3float]] = OpTypeRuntimeArray %[[v3float]]
// CHECK-DAG: %[[_struct_8]] = OpTypeStruct %[[_runtimearr_v3float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_8:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_8]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_11:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_ptr_StorageBuffer_float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[float]]
// CHECK-DAG: %[[_ptr_StorageBuffer_v3float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v3float]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK:     %[[__original_id_16:[0-9]+]] = OpUndef %[[v3float]]
// CHECK-DAG: %[[__original_id_17]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_18]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_19]] = OpVariable %[[_ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK:     %[[__original_id_20]] = OpFunction %[[void]] None %[[__original_id_11]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_22:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[__original_id_17]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_float]] %[[__original_id_18]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_24:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v3float]] %[[__original_id_19]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpLoad %[[float]] %[[__original_id_22]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpLoad %[[float]] %[[__original_id_23]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v3float]] %[[__original_id_24]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpCompositeInsert %[[v3float]] %[[__original_id_25]] %[[__original_id_16]] 0
// CHECK:     %[[__original_id_29:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_28]] %[[__original_id_16]] 0 0 0
// CHECK:     %[[__original_id_30:[0-9]+]] = OpCompositeInsert %[[v3float]] %[[__original_id_26]] %[[__original_id_16]] 0
// CHECK:     %[[__original_id_31:[0-9]+]] = OpVectorShuffle %[[v3float]] %[[__original_id_30]] %[[__original_id_16]] 0 0 0
// CHECK:     %[[__original_id_32:[0-9]+]] = OpExtInst %[[v3float]] %[[__original_id_1]] SmoothStep %[[__original_id_29]] %[[__original_id_31]] %[[__original_id_27]]
// CHECK:     OpStore %[[__original_id_24]] %[[__original_id_32]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd

kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b, global float3* c)
{
    *c = smoothstep(*a, *b, *c);
}

