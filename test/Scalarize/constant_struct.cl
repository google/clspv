// RUN: clspv %s -S -o %t.spvasm -hack-phis -inline-entry-points
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-phis -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { int arr[2]; } S1;
typedef struct { S1 s1; int a; S1 s2; } S2;

S2 make_s2(int n) {
  S2 s2;
  s2.s1.arr[0] = n;
  s2.s1.arr[1] = n;
  s2.a = n;
  s2.s2.arr[0] = n;
  s2.s2.arr[1] = n;
  return s2;
}

S2 choose(int n) {
  if (n > 0) return make_s2(n - 5);
  return make_s2(0);
}

kernel void foo(global S2 *data, int n) {
  *data = choose(n);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 64
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_28:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_5]] 1 Offset 8
// CHECK: OpMemberDecorate [[__struct_5]] 2 Offset 12
// CHECK: OpDecorate [[__runtimearr__struct_5:%[0-9a-zA-Z_]+]] ArrayStride 20
// CHECK: OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7]] Block
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_26]] Binding 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 1
// CHECK: OpDecorate [[__arr_uint_uint_2:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[__arr_uint_uint_2]] = OpTypeArray [[_uint]] [[_uint_2]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__arr_uint_uint_2]]
// CHECK: [[__struct_5]] = OpTypeStruct [[__struct_4]] [[_uint]] [[__struct_4]]
// CHECK: [[__runtimearr__struct_5]] = OpTypeRuntimeArray [[__struct_5]]
// CHECK: [[__struct_7]] = OpTypeStruct [[__runtimearr__struct_5]]
// CHECK: [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK: [[__struct_9]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_4294967291:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967291
// CHECK: [[_19:%[0-9a-zA-Z_]+]] = OpConstantNull [[__arr_uint_uint_2]]
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_21]] [[_22]] [[_23]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_28]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_30]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpSGreaterThan [[_bool]] [[_31]] [[_uint_0]]
// CHECK: OpSelectionMerge [[_43:%[0-9a-zA-Z_]+]] None
// CHECK: OpBranchConditional [[_32]] [[_33:%[0-9a-zA-Z_]+]] [[_43]]
// CHECK: [[_33]] = OpLabel
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_31]] [[_uint_4294967291]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__arr_uint_uint_2]] [[_34]] [[_34]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_36]] [[_34]] [[_36]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_37]] 0
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_38]] 0
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_37]] 1
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_37]] 2
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_41]] 0
// CHECK: OpBranch [[_43]]
// CHECK: [[_43]] = OpLabel
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_19]] [[_29]] [[_42]] [[_33]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_uint_0]] [[_29]] [[_40]] [[_33]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_19]] [[_29]] [[_39]] [[_33]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_46]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_44]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_48]] [[_45]] [[_47]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_49]] 0
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_50]] 0
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_51]] 0
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_51]] 1
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_49]] 1
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_49]] 2
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_55]] 0
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_56]] 0
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_56]] 1
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_59]] [[_52]]
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_60]] [[_53]]
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_61]] [[_54]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_2]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_62]] [[_57]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]] [[_uint_2]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_63]] [[_58]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
