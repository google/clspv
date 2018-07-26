// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


















void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int2* a, global float4* b, int i)
{
  *b = ((global float4*)a)[i];
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 37
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_24:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_24]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_v2uint:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_11]] Block
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_21]] Binding 0
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_22]] Binding 1
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[__runtimearr_v2uint]] = OpTypeRuntimeArray [[_v2uint]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v2uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[__struct_11]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2uint]]
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK:  [[_24]] = OpFunction [[_void]] None [[_14]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_22]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_28]] [[_uint_1]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_21]] [[_uint_0]] [[_29]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_29]] [[_uint_1]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_21]] [[_uint_0]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4uint]] [[_31]] [[_34]] 0 1 2 3
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpBitcast [[_v4float]] [[_35]]
// CHECK:  OpStore [[_26]] [[_36]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
