// RUN: clspv %s -S -o %t.spvasm -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

void core(float4 a, write_only image2d_t im, int2 coord) {
  write_imagef(im, coord, a);
}

void apple(write_only image2d_t im, int2 coord, float4 a) {
   core(a, im, coord);
}

kernel void foo(int2 coord, write_only image2d_t im, float4 a) {
  apple(im, 2 * coord, a);
}

kernel void bar(int2 coord, write_only image2d_t im, float4 a) {
  apple(im, 3 * coord, a);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 63
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability StorageImageWriteWithoutFormat
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_45:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_54:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 1
// CHECK:  OpDecorate [[_29]] NonReadable
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_30]] Binding 0
// CHECK:  OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_31]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 2 Unknown
// CHECK:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[__struct_6]] = OpTypeStruct [[_v2uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__struct_9]] = OpTypeStruct [[_v4float]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2uint]]
// CHECK:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK:  [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[_v4float]] [[_2]] [[_v2uint]]
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[_2]] [[_v2uint]] [[_v4float]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_3]] [[_uint_3]]
// CHECK:  [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_24]] [[_25]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_29]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_15]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v2uint]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_29]]
// CHECK:  OpImageWrite [[_37]] [[_35]] [[_33]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_16]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v2uint]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_29]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_32]] [[_41]] [[_43]] [[_40]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_45]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_30]] [[_uint_0]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_47]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_29]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_31]] [[_uint_0]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_50]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_v2uint]] [[_48]] [[_21]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_38]] [[_49]] [[_52]] [[_51]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_54]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_30]] [[_uint_0]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_56]]
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_29]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_31]] [[_uint_0]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_59]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpIMul [[_v2uint]] [[_57]] [[_23]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_38]] [[_58]] [[_61]] [[_60]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
