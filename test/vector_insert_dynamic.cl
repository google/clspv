// Test for https://github.com/google/clspv/issues/143
// Order of OpVectorInsertDynamic operands was incorrect.

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 37
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_28:%[0-9a-zA-Z_]+]] "foo" [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_20:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5:%[0-9a-zA-Z_]+]] Block
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9:%[0-9a-zA-Z_]+]] Block
// CHECK: OpDecorate [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]] BuiltIn GlobalInvocationId
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_25:%[0-9a-zA-Z_]+]] Binding 0
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] Binding 1
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] Binding 2
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint:%[0-9a-zA-Z_]+]] 4
// CHECK: [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_v4uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_v4uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5:%[0-9a-zA-Z_]+]]
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__runtimearr_uint:%[0-9a-zA-Z_]+]] = OpTypeRuntimeArray [[_uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__struct_9:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__runtimearr_uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9:%[0-9a-zA-Z_]+]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void:%[0-9a-zA-Z_]+]]
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint:%[0-9a-zA-Z_]+]] 3
// CHECK: [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint:%[0-9a-zA-Z_]+]]
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint:%[0-9a-zA-Z_]+]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint:%[0-9a-zA-Z_]+]] 0
// CHECK: [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint:%[0-9a-zA-Z_]+]] 42
// CHECK: [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] Input
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpSpecConstant [[_uint:%[0-9a-zA-Z_]+]] 1
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpSpecConstant [[_uint:%[0-9a-zA-Z_]+]] 1
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpSpecConstant [[_uint:%[0-9a-zA-Z_]+]] 1
// CHECK: [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] = OpSpecConstantComposite [[_v3uint:%[0-9a-zA-Z_]+]] [[_20:%[0-9a-zA-Z_]+]] [[_21:%[0-9a-zA-Z_]+]] [[_22:%[0-9a-zA-Z_]+]]
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] Private [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] StorageBuffer
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] StorageBuffer
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] StorageBuffer
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpFunction [[_void:%[0-9a-zA-Z_]+]] None [[_12:%[0-9a-zA-Z_]+]]
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]] [[_uint_0:%[0-9a-zA-Z_]+]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_uint:%[0-9a-zA-Z_]+]] [[_30:%[0-9a-zA-Z_]+]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] [[_26:%[0-9a-zA-Z_]+]] [[_uint_0:%[0-9a-zA-Z_]+]] [[_31:%[0-9a-zA-Z_]+]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] [[_27:%[0-9a-zA-Z_]+]] [[_uint_0:%[0-9a-zA-Z_]+]] [[_31:%[0-9a-zA-Z_]+]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint:%[0-9a-zA-Z_]+]] [[_33:%[0-9a-zA-Z_]+]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint:%[0-9a-zA-Z_]+]] [[_32:%[0-9a-zA-Z_]+]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpVectorInsertDynamic [[_v4uint:%[0-9a-zA-Z_]+]] [[_35:%[0-9a-zA-Z_]+]] [[_uint_42:%[0-9a-zA-Z_]+]] [[_34:%[0-9a-zA-Z_]+]]
// CHECK: OpStore [[_32:%[0-9a-zA-Z_]+]] [[_36:%[0-9a-zA-Z_]+]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd

kernel void foo(global int4* in, global int4* out,
                global int* index) {
  size_t gid = get_global_id(0);
  out[gid][index[gid]] = 42;
}
