// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float4* A, global float* B, uint n) {
  *A = vload4(n, B);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 52
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_31:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_23:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_24:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_25:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_9:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_12:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_28:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 0
// CHECK: OpDecorate [[_29:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 1
// CHECK: OpDecorate [[_30:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 2
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK: [[__struct_5]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK: [[__struct_9]] = OpTypeStruct [[__runtimearr_float]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_12]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_16:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpUndef [[_v4float]]
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_23]] [[_24]] [[_25]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_31]] = OpFunction [[_void]] None [[_16]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpLoad [[_uint]] [[_34]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[_uint]] [[_35]] [[_uint_2]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_36]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_37]]
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_1]]
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_39]]
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_40]]
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_42]]
// CHECK: [[_44:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_43]]
// CHECK: [[_45:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_42]] [[_uint_1]]
// CHECK: [[_46:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_45]]
// CHECK: [[_47:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_46]]
// CHECK: [[_48:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[_v4float]] [[_38]] [[_22]] 0
// CHECK: [[_49:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[_v4float]] [[_41]] [[_48]] 1
// CHECK: [[_50:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[_v4float]] [[_44]] [[_49]] 2
// CHECK: [[_51:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[_v4float]] [[_47]] [[_50]] 3
// CHECK: OpStore [[_33]] [[_51]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
