// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 22
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability Int64
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_14:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_14]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_ulong:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_4:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_4]] Block
// CHECK:     OpDecorate %[[__original_id_11:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_11]] Binding 0
// CHECK:     OpDecorate %[[__original_id_12:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_12]] Binding 1
// CHECK:     OpDecorate %[[__original_id_13:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_13]] Binding 2
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[_runtimearr_ulong]] = OpTypeRuntimeArray %[[ulong]]
// CHECK-DAG: %[[_struct_4]] = OpTypeStruct %[[_runtimearr_ulong]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_4:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_4]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_7:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_ptr_StorageBuffer_ulong:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[ulong]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[__original_id_11]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_12]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG: %[[__original_id_13]] = OpVariable %[[_ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:     %[[__original_id_14]] = OpFunction %[[void]] None %[[__original_id_7]]
// CHECK:     %[[__original_id_15:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_16:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_ulong]] %[[__original_id_11]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_17:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_ulong]] %[[__original_id_12]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_18:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_ulong]] %[[__original_id_13]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpLoad %[[ulong]] %[[__original_id_17]]
// CHECK:     %[[__original_id_20:[0-9]+]] = OpLoad %[[ulong]] %[[__original_id_18]]
// CHECK:     %[[__original_id_21:[0-9]+]] = OpExtInst %[[ulong]] %[[__original_id_1]] SMin %[[__original_id_19]] %[[__original_id_20]]
// CHECK:     OpStore %[[__original_id_16]] %[[__original_id_21]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global long* a, global long* b, global long* c)
{
    *a = min(*b, *c);
}

