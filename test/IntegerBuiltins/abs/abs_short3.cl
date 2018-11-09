// RUN: clspv  %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 20
// CHECK:     ; Schema: 0
// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability Int16
// CHECK-DAG: OpCapability VariablePointers
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpExtension "SPV_KHR_variable_pointers"
// CHECK:     %[[__original_id_1:[0-9]+]] = OpExtInstImport "GLSL.std.450"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute %[[__original_id_14:[0-9]+]] "foo"
// CHECK:     OpExecutionMode %[[__original_id_14]] LocalSize 1 1 1
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate %[[_runtimearr_v3ushort:[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:     OpMemberDecorate %[[_struct_5:[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate %[[_struct_5]] Block
// CHECK:     OpDecorate %[[__original_id_12:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_12]] Binding 0
// CHECK:     OpDecorate %[[__original_id_13:[0-9]+]] DescriptorSet 0
// CHECK:     OpDecorate %[[__original_id_13]] Binding 1
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[_runtimearr_v3ushort]] = OpTypeRuntimeArray %[[v3ushort]]
// CHECK-DAG: %[[_struct_5]] = OpTypeStruct %[[_runtimearr_v3ushort]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_5:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_5]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_8:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_ptr_StorageBuffer_v3ushort:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[v3ushort]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[__original_id_12]] = OpVariable %[[_ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK-DAG: %[[__original_id_13]] = OpVariable %[[_ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:     %[[__original_id_14]] = OpFunction %[[void]] None %[[__original_id_8]]
// CHECK:     %[[__original_id_15:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_16:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v3ushort]] %[[__original_id_12]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_17:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_v3ushort]] %[[__original_id_13]] %[[uint_0]] %[[uint_0]]
// CHECK:     %[[__original_id_18:[0-9]+]] = OpLoad %[[v3ushort]] %[[__original_id_17]]
// CHECK:     %[[__original_id_19:[0-9]+]] = OpExtInst %[[v3ushort]] %[[__original_id_1]] SAbs %[[__original_id_18]]
// CHECK:     OpStore %[[__original_id_16]] %[[__original_id_19]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd


kernel void __attribute__((reqd_work_group_size(1, 1, 1))) foo(global ushort3* a, global short3* b)
{
    *a = abs(*b);
}

