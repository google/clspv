// Reuse the module-scope variables we make for kernel arguments, to
// the maximum extent possible.

kernel void foo(global float* A, global float *B, global int* C, global float* D, float f, float g) {
  *A = f + g;
  *B = 0.0f;
  *C = 12;
  *D = f;
}

kernel void bar(global float* R, global float* S, global float* T, float x, float y) {
  *R = x * y;
  *S = x / y;
  *T = x;
}

// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck -check-prefix=CLUSTER %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// In the default case:
//   R should reuse the var for A
//   S should reuse the var for B
//   T cannot reuse the var for C because of type mismatch
//   T cannot reuse the var for D because of binding mismatch
//   x cannot reuse a var because of binding mismatch
//   y should reuse the var for f

// In the cluster-pod-kernel-args case:
//   C should reuse the var for A
//   D should reuse the var for B
//   T cannot reuse the var for C because of type mismatch
//   T cannot reuse the var for D because of binding mismatch
//   {x, y} cannot reuse the var for {f, g} because of binding mismatch



// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 55
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_44:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_25]] Binding 0
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_26]] Binding 1
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_27]] Binding 2
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_28]] Binding 3
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 4
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_30]] Binding 5
// CHECK:  OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_31]] Binding 2
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_32]] Binding 3
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// CHECK:  [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_20]] [[_21]] [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_33]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_39]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_41]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_40]] [[_42]]
// CHECK:  OpStore [[_35]] [[_43]]
// CHECK:  OpStore [[_36]] [[_float_0]]
// CHECK:  OpStore [[_37]] [[_uint_12]]
// CHECK:  OpStore [[_38]] [[_40]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_44]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_31]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_32]] [[_uint_0]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_49]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_51]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpFMul [[_float]] [[_50]] [[_52]]
// CHECK:  OpStore [[_46]] [[_53]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpFDiv [[_float]] [[_50]] [[_52]]
// CHECK:  OpStore [[_47]] [[_54]]
// CHECK:  OpStore [[_48]] [[_50]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd

// CLUSTER:  ; SPIR-V
// CLUSTER:  ; Version: 1.0
// CLUSTER:  ; Generator: Codeplay; 0
// CLUSTER:  ; Bound: 56
// CLUSTER:  ; Schema: 0
// CLUSTER:  OpCapability Shader
// CLUSTER:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CLUSTER:  OpMemoryModel Logical GLSL450
// CLUSTER:  OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CLUSTER:  OpEntryPoint GLCompute [[_45:%[0-9a-zA-Z_]+]] "bar"
// CLUSTER:  OpSource OpenCL_C 120
// CLUSTER:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CLUSTER:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CLUSTER:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CLUSTER:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CLUSTER:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CLUSTER:  OpDecorate [[__struct_3]] Block
// CLUSTER:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CLUSTER:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CLUSTER:  OpDecorate [[__struct_7]] Block
// CLUSTER:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CLUSTER:  OpMemberDecorate [[__struct_9]] 1 Offset 4
// CLUSTER:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CLUSTER:  OpDecorate [[__struct_10]] Block
// CLUSTER:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CLUSTER:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_27]] Binding 0
// CLUSTER:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_28]] Binding 1
// CLUSTER:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_29]] Binding 2
// CLUSTER:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_30]] Binding 3
// CLUSTER:  OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_31]] Binding 4
// CLUSTER:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_32]] Binding 2
// CLUSTER:  OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CLUSTER:  OpDecorate [[_33]] Binding 3
// CLUSTER:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CLUSTER:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CLUSTER:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CLUSTER:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CLUSTER:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CLUSTER:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CLUSTER:  [[__struct_7]] = OpTypeStruct [[__runtimearr_uint]]
// CLUSTER:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CLUSTER:  [[__struct_9]] = OpTypeStruct [[_float]] [[_float]]
// CLUSTER:  [[__struct_10]] = OpTypeStruct [[__struct_9]]
// CLUSTER:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CLUSTER:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CLUSTER:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CLUSTER:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CLUSTER:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CLUSTER:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CLUSTER:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CLUSTER:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CLUSTER:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CLUSTER:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CLUSTER:  [[_uint_12:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 12
// CLUSTER:  [[_22]] = OpSpecConstant [[_uint]] 1
// CLUSTER:  [[_23]] = OpSpecConstant [[_uint]] 1
// CLUSTER:  [[_24]] = OpSpecConstant [[_uint]] 1
// CLUSTER:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CLUSTER:  [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CLUSTER:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CLUSTER:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CLUSTER:  [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CLUSTER:  [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CLUSTER:  [[_34]] = OpFunction [[_void]] None [[_13]]
// CLUSTER:  [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CLUSTER:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_9]] [[_31]] [[_uint_0]]
// CLUSTER:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_9]] [[_40]]
// CLUSTER:  [[_42:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_41]] 0
// CLUSTER:  [[_43:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_41]] 1
// CLUSTER:  [[_44:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_42]] [[_43]]
// CLUSTER:  OpStore [[_36]] [[_44]]
// CLUSTER:  OpStore [[_37]] [[_float_0]]
// CLUSTER:  OpStore [[_38]] [[_uint_12]]
// CLUSTER:  OpStore [[_39]] [[_42]]
// CLUSTER:  OpReturn
// CLUSTER:  OpFunctionEnd
// CLUSTER:  [[_45]] = OpFunction [[_void]] None [[_13]]
// CLUSTER:  [[_46:%[0-9a-zA-Z_]+]] = OpLabel
// CLUSTER:  [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_32]] [[_uint_0]] [[_uint_0]]
// CLUSTER:  [[_50:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_9]] [[_33]] [[_uint_0]]
// CLUSTER:  [[_51:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_9]] [[_50]]
// CLUSTER:  [[_52:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_51]] 0
// CLUSTER:  [[_53:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_51]] 1
// CLUSTER:  [[_54:%[0-9a-zA-Z_]+]] = OpFMul [[_float]] [[_52]] [[_53]]
// CLUSTER:  OpStore [[_47]] [[_54]]
// CLUSTER:  [[_55:%[0-9a-zA-Z_]+]] = OpFDiv [[_float]] [[_52]] [[_53]]
// CLUSTER:  OpStore [[_48]] [[_55]]
// CLUSTER:  OpStore [[_49]] [[_52]]
// CLUSTER:  OpReturn
// CLUSTER:  OpFunctionEnd
