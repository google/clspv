// Test the -hack-inserts option.
// Check that we can remove partial chains of insertvalue
// to avoid OpCompositeInsert entirely.

// RUN: clspv %s -o %t.spv -hack-inserts -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


typedef struct { float a, b, c, d; } S;

S boo(S in) {
  in.c = 2.0f;
  in.b = 1.0f;
  return in;
}


kernel void foo(global S* data, float f) {
  data[0] = boo(data[1]);
}


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 56
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 2
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
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_26]] Binding 0
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_27]] Binding 1
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[__struct_2]] = OpTypeStruct [[_float]] [[_float]] [[_float]] [[_float]]
// CHECK-DAG:  [[__runtimearr__struct_2]] = OpTypeRuntimeArray [[__struct_2]]
// CHECK-DAG:  [[__struct_4]] = OpTypeStruct [[__runtimearr__struct_2]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK-DAG:  [[__struct_6]] = OpTypeStruct [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[__struct_2]] [[__struct_2]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK-DAG:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK-DAG:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK-DAG:  [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_21]] [[_22]] [[_23]]
// CHECK-DAG:  [[_25:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK-DAG:  [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK-DAG:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpFunction [[__struct_2]] Const [[_12]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__struct_2]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_29]] 3
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_29]] 0
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_32]] [[_float_1]] [[_float_2]] [[_31]]
// CHECK:  OpReturnValue [[_33]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_34]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_1]] [[_uint_0]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_38]]
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_40]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_1]] [[_uint_2]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_42]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_1]] [[_uint_3]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_44]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_39]] [[_41]] [[_43]] [[_45]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_2]] [[_28]] [[_46]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 0
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 1
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 2
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_47]] 3
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK:  OpStore [[_52]] [[_48]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK:  OpStore [[_53]] [[_49]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_2]]
// CHECK:  OpStore [[_54]] [[_50]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_3]]
// CHECK:  OpStore [[_55]] [[_51]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
