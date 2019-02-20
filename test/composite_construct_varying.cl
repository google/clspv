// RUN: clspv %s -S -o %t.spvasm -hack-inserts -no-inline-single -keep-unused-arguments
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-inserts -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


typedef struct { float a, b, c, d; } S;

S boo(S in) {
  in.a = 0.0f;
  in.c = 2.0f;
  in.b = 1.0f;
  in.d = 3.0f;
  return in;
}


kernel void foo(global S* data, float f) {
  data[0] = boo(data[1]);
}

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 56
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_2]] 1 Offset 4
// CHECK:  OpMemberDecorate [[__struct_2]] 2 Offset 8
// CHECK:  OpMemberDecorate [[__struct_2]] 3 Offset 12
// CHECK:  OpDecorate [[__runtimearr__struct_2:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_4]] Block
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 0
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_30]] Binding 1
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__struct_2]] = OpTypeStruct [[_float]] [[_float]] [[_float]] [[_float]]
// CHECK:  [[__runtimearr__struct_2]] = OpTypeRuntimeArray [[__struct_2]]
// CHECK:  [[__struct_4]] = OpTypeStruct [[__runtimearr__struct_2]]
// CHECK:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK:  [[__struct_6]] = OpTypeStruct [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[__struct_2]] [[__struct_2]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__struct_2]] [[_float_0]] [[_float_1]] [[_float_2]] [[_float_3]]
// CHECK:  [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_24]] [[_25]] [[_26]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK:  [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunction [[__struct_2]] Const [[_12]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__struct_2]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  OpReturnValue [[_23]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_34]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_30]] [[_uint_0]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_1]] [[_uint_0]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_40]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_1]] [[_uint_2]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_42]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_1]] [[_uint_3]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_44]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_39]] [[_41]] [[_43]] [[_45]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_2]] [[_31]] [[_46]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 0
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 1
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 2
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 3
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  OpStore [[_52]] [[_48]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_53]] [[_49]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_0]] [[_uint_2]]
// CHECK:  OpStore [[_54]] [[_50]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_29]] [[_uint_0]] [[_uint_0]] [[_uint_3]]
// CHECK:  OpStore [[_55]] [[_51]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
