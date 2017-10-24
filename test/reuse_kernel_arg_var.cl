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

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args
// RUN: FileCheck -check-prefix=CLUSTER %s < %t.spvasm
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

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 55
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_33:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpEntryPoint GLCompute [[_44:%[a-zA-Z0-9_]+]] "bar"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpDecorate [[__runtimearr_uint:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_9:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_11:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_11]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_25:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_25]] Binding 0
// CHECK: OpDecorate [[_26:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_26]] Binding 1
// CHECK: OpDecorate [[_27:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 2
// CHECK: OpDecorate [[_28:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 3
// CHECK: OpDecorate [[_29:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 4
// CHECK: OpDecorate [[_30:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 5
// CHECK: OpDecorate [[_31:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_31]] Binding 2
// CHECK: OpDecorate [[_32:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 3
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[__struct_9]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK: [[__struct_11]] = OpTypeStruct [[_float]]
// CHECK: [[__ptr_StorageBuffer__struct_11:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_14:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CHECK: [[_uint_12:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 12
// CHECK: [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_20]] [[_21]] [[_22]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_33]] = OpFunction [[_void]] None [[_14]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]]
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_39]]
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]]
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_41]]
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpFAdd [[_float]] [[_40]] [[_42]]
// CHECK: OpStore [[_35]] [[_43]]
// CHECK: OpStore [[_36]] [[_float_0]]
// CHECK: OpStore [[_37]] [[_uint_12]]
// CHECK: OpStore [[_38]] [[_40]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
// CHECK: [[_44]] = OpFunction [[_void]] None [[_14]]
// CHECK: [[_45:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_46:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_47:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_48:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_31]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_49:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_32]] [[_uint_0]]
// CHECK: [[_50:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_49]]
// CHECK: [[_51:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]]
// CHECK: [[_52:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_51]]
// CHECK: [[_53:%[a-zA-Z0-9_]+]] = OpFMul [[_float]] [[_50]] [[_52]]
// CHECK: OpStore [[_46]] [[_53]]
// CHECK: [[_54:%[a-zA-Z0-9_]+]] = OpFDiv [[_float]] [[_50]] [[_52]]
// CHECK: OpStore [[_47]] [[_54]]
// CHECK: OpStore [[_48]] [[_50]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd



// CLUSTER: ; SPIR-V
// CLUSTER: ; Version: 1.0
// CLUSTER: ; Generator: Codeplay; 0
// CLUSTER: ; Bound: 56
// CLUSTER: ; Schema: 0
// CLUSTER: OpCapability Shader
// CLUSTER: OpCapability VariablePointers
// CLUSTER: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CLUSTER: OpExtension "SPV_KHR_variable_pointers"
// CLUSTER: OpMemoryModel Logical GLSL450
// CLUSTER: OpEntryPoint GLCompute [[_34:%[a-zA-Z0-9_]+]] "foo"
// CLUSTER: OpEntryPoint GLCompute [[_45:%[a-zA-Z0-9_]+]] "bar"
// CLUSTER: OpSource OpenCL_C 120
// CLUSTER: OpDecorate [[_22:%[a-zA-Z0-9_]+]] SpecId 0
// CLUSTER: OpDecorate [[_23:%[a-zA-Z0-9_]+]] SpecId 1
// CLUSTER: OpDecorate [[_24:%[a-zA-Z0-9_]+]] SpecId 2
// CLUSTER: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CLUSTER: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpDecorate [[__struct_4]] Block
// CLUSTER: OpDecorate [[__runtimearr_uint:%[a-zA-Z0-9_]+]] ArrayStride 4
// CLUSTER: OpMemberDecorate [[__struct_9:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpDecorate [[__struct_9]] Block
// CLUSTER: OpMemberDecorate [[__struct_11:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpMemberDecorate [[__struct_11]] 1 Offset 4
// CLUSTER: OpMemberDecorate [[__struct_12:%[a-zA-Z0-9_]+]] 0 Offset 0
// CLUSTER: OpDecorate [[__struct_12]] Block
// CLUSTER: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CLUSTER: OpDecorate [[_27:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_27]] Binding 0
// CLUSTER: OpDecorate [[_28:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_28]] Binding 1
// CLUSTER: OpDecorate [[_29:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_29]] Binding 2
// CLUSTER: OpDecorate [[_30:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_30]] Binding 3
// CLUSTER: OpDecorate [[_31:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_31]] Binding 4
// CLUSTER: OpDecorate [[_32:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_32]] Binding 2
// CLUSTER: OpDecorate [[_33:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CLUSTER: OpDecorate [[_33]] Binding 3
// CLUSTER: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CLUSTER: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CLUSTER: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CLUSTER: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CLUSTER: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CLUSTER: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CLUSTER: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CLUSTER: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CLUSTER: [[__struct_9]] = OpTypeStruct [[__runtimearr_uint]]
// CLUSTER: [[__ptr_StorageBuffer__struct_9:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CLUSTER: [[__struct_11]] = OpTypeStruct [[_float]] [[_float]]
// CLUSTER: [[__struct_12]] = OpTypeStruct [[__struct_11]]
// CLUSTER: [[__ptr_StorageBuffer__struct_12:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CLUSTER: [[__ptr_StorageBuffer__struct_11:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CLUSTER: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CLUSTER: [[_16:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CLUSTER: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CLUSTER: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CLUSTER: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CLUSTER: [[_float_0:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0
// CLUSTER: [[_uint_12:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 12
// CLUSTER: [[_22]] = OpSpecConstant [[_uint]] 1
// CLUSTER: [[_23]] = OpSpecConstant [[_uint]] 1
// CLUSTER: [[_24]] = OpSpecConstant [[_uint]] 1
// CLUSTER: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CLUSTER: [[_26:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CLUSTER: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CLUSTER: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CLUSTER: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CLUSTER: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CLUSTER: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CLUSTER: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CLUSTER: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CLUSTER: [[_34]] = OpFunction [[_void]] None [[_16]]
// CLUSTER: [[_35:%[a-zA-Z0-9_]+]] = OpLabel
// CLUSTER: [[_36:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_37:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_38:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_39:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_40:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_11]] [[_31]] [[_uint_0]]
// CLUSTER: [[_41:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_11]] [[_40]]
// CLUSTER: [[_42:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_41]] 0
// CLUSTER: [[_43:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_41]] 1
// CLUSTER: [[_44:%[a-zA-Z0-9_]+]] = OpFAdd [[_float]] [[_42]] [[_43]]
// CLUSTER: OpStore [[_36]] [[_44]]
// CLUSTER: OpStore [[_37]] [[_float_0]]
// CLUSTER: OpStore [[_38]] [[_uint_12]]
// CLUSTER: OpStore [[_39]] [[_42]]
// CLUSTER: OpReturn
// CLUSTER: OpFunctionEnd
// CLUSTER: [[_45]] = OpFunction [[_void]] None [[_16]]
// CLUSTER: [[_46:%[a-zA-Z0-9_]+]] = OpLabel
// CLUSTER: [[_47:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_48:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_49:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_32]] [[_uint_0]] [[_uint_0]]
// CLUSTER: [[_50:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer__struct_11]] [[_33]] [[_uint_0]]
// CLUSTER: [[_51:%[a-zA-Z0-9_]+]] = OpLoad [[__struct_11]] [[_50]]
// CLUSTER: [[_52:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_51]] 0
// CLUSTER: [[_53:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_51]] 1
// CLUSTER: [[_54:%[a-zA-Z0-9_]+]] = OpFMul [[_float]] [[_52]] [[_53]]
// CLUSTER: OpStore [[_47]] [[_54]]
// CLUSTER: [[_55:%[a-zA-Z0-9_]+]] = OpFDiv [[_float]] [[_52]] [[_53]]
// CLUSTER: OpStore [[_48]] [[_55]]
// CLUSTER: OpStore [[_49]] [[_52]]
// CLUSTER: OpReturn
// CLUSTER: OpFunctionEnd
