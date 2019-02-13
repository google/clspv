// Test for https://github.com/google/clspv/issues/143
// Order of OpVectorInsertDynamic operands was incorrect.

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global int4* in, global int4* out,
                global int* index) {
  size_t gid = get_global_id(0);
  out[gid][index[gid]] = 42;
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 38
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_28:%[0-9a-zA-Z_]+]] "foo" [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpDecorate [[_gl_GlobalInvocationID]] BuiltIn GlobalInvocationId
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_25]] Binding 0
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_26]] Binding 1
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_27]] Binding 2
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[__runtimearr_v4uint]] = OpTypeRuntimeArray [[_v4uint]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v4uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_10:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  [[_gl_GlobalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK:  [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_20]] [[_21]] [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_28]] = OpFunction [[_void]] None [[_10]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint]] [[_26]] [[_uint_0]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]] [[_32]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_34]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]] [[_33]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpVectorInsertDynamic [[_v4uint]] [[_36]] [[_uint_42]] [[_35]]
// CHECK:  OpStore [[_33]] [[_37]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
