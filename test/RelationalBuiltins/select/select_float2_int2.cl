// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 32
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_22:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_22]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_v2float:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_4:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_4]] Block
// CHECK:     OpDecorate %[[_runtimearr_v2uint:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_9:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_9]] Block
// CHECK:     OpDecorate %[[__original_id_19:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_19]] Binding 0
// CHECK:     OpDecorate %[[__original_id_20:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_20]] Binding 1
// CHECK:     OpDecorate %[[__original_id_21:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_21]] Binding 2
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v2float:[0-9a-zA-Z_]+]] = OpTypeVector %[[float]] 2
// CHECK-DAG: %[[_runtimearr_v2float]] = OpTypeRuntimeArray %[[v2float]]
// CHECK-DAG: %[[_struct_4]] = OpTypeStruct %[[_runtimearr_v2float]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_4:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_4]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[_runtimearr_v2uint]] = OpTypeRuntimeArray %[[v2uint]]
// CHECK-DAG: %[[_struct_9]] = OpTypeStruct %[[_runtimearr_v2uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_9:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_9]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_12:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[_ptr_StorageBuffer_v2float:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v2float]]
// CHECK-DAG: %[[_ptr_StorageBuffer_v2uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v2uint]]
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[__original_id_18:[0-9]+]] = OpConstantNull %[[v2uint]]
// CHECK-DAG: %[[__original_id_19]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_20]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_21]] = OpVariable %[[_ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:     %[[__original_id_22]] = OpFunction %[[void]] None %[[__original_id_12]]
// CHECK:     %[[__original_id_23:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_24:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2float]] %[[__original_id_19]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_25:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2float]] %[[__original_id_20]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_26:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v2uint]] %[[__original_id_21]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_27:[0-9]+]] = OpLoad %[[v2float]] %[[__original_id_24]]
// CHECK:     %[[__original_id_28:[0-9]+]] = OpLoad %[[v2float]] %[[__original_id_25]]
// CHECK:     %[[__original_id_29:[0-9]+]] = OpLoad %[[v2uint]] %[[__original_id_26]]
// CHECK:     %[[__original_id_30:[0-9]+]] = OpSLessThan %[[v2bool]] %[[__original_id_29]] %[[__original_id_18]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpSelect %[[v2float]] %[[__original_id_30]] %[[__original_id_28]] %[[__original_id_27]]
// CHECK:     OpStore %[[__original_id_24]] %[[__original_id_31]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float2* b, global int2* c)
{
    *a = select(*a, *b, *c);
}

