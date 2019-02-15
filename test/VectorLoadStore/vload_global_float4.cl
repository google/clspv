// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float4* A, global float* B, uint n) {
  *A = vload4(n, B);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 48
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_7]] Block
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_28]] Binding 0
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 1
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_30]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_7]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_10]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_23]] [[_24]] [[_25]]
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_31]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_34]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_35]] [[_uint_2]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_37]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_1]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_39]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_40]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_39]] [[_uint_1]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_42]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_43]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_42]] [[_uint_1]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_45]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_46]]
// CHECK:  [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v4float]] [[_38]] [[_41]] [[_44]] [[_47]] 
// CHECK:  OpStore [[_33]] [[construct]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
