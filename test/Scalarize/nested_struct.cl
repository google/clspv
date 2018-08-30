// RUN: clspv %s -S -o %t.spvasm -hack-phis
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-phis
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { int arr[2]; } S1;
typedef struct { S1 s1; int a; S1 s2; } S2;

S2 make_s2(int n) {
  S2 s2;
  s2.s1.arr[0] = n;
  s2.s1.arr[1] = n+1;
  s2.a = n+2;
  s2.s2.arr[0] = n+3;
  s2.s2.arr[1] = n+4;
  return s2;
}

S2 choose(int n) {
  if (n > 0) return make_s2(n - 5);
  return make_s2(n + 10);
}

kernel void foo(global S2 *data, int n) {
  *data = choose(n);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 107
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_88:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 2
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
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 0
// CHECK: OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_34]] Binding 1
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
// CHECK: [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[__struct_5]] [[_uint]]
// CHECK: [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK: [[_uint_10:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 10
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpUndef [[__arr_uint_uint_2]]
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpUndef [[_uint]]
// CHECK: [[_false:%[0-9a-zA-Z_]+]] = OpConstantFalse [[_bool]]
// CHECK: [[_true:%[0-9a-zA-Z_]+]] = OpConstantTrue [[_bool]]
// CHECK: [[_uint_4294967291:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967291
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_28]] [[_29]] [[_30]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpFunction [[__struct_5]] Const [[_14]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_1]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_2]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_3]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_4]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__arr_uint_uint_2]] [[_36]] [[_38]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_42]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__arr_uint_uint_2]] [[_40]] [[_41]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_44]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_43]] [[_39]] [[_45]]
// CHECK: OpReturnValue [[_46]]
// CHECK: OpFunctionEnd
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpFunction [[__struct_5]] Const [[_14]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpSGreaterThan [[_bool]] [[_48]] [[_uint_0]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_50]]
// CHECK: OpSelectionMerge [[_60:%[0-9a-zA-Z_]+]] None
// CHECK: OpBranchConditional [[_51]] [[_52:%[0-9a-zA-Z_]+]] [[_60:%[0-9a-zA-Z_]+]]
// CHECK: [[_52]] = OpLabel
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_48]] [[_uint_10]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_5]] [[_35]] [[_53]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_54]] 0
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_55]] 0
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_54]] 1
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_54]] 2
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_58]] 0
// CHECK: OpBranch [[_60:%[0-9a-zA-Z_]+]]
// CHECK: [[_60]] = OpLabel
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_52]] [[_true]] [[_49]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_59]] [[_52]] [[_23]] [[_49]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_57]] [[_52]] [[_24]] [[_49]]
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_56]] [[_52]] [[_23]] [[_49]]
// CHECK: [[_66:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_63]]
// CHECK: [[_67:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_61]]
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_67]] [[_62]] [[_66]]
// CHECK: [[_68:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_65]] 0
// CHECK: [[_69:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_68]] 0
// CHECK: [[_70:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_65]] 1
// CHECK: [[_71:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_65]] 2
// CHECK: [[_72:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_71]] 0
// CHECK: OpSelectionMerge [[_73:%[0-9a-zA-Z_]+]] None
// CHECK: OpBranchConditional [[_64]] [[_80:%[0-9a-zA-Z_]+]] [[_73:%[0-9a-zA-Z_]+]]
// CHECK: [[_73]] = OpLabel
// CHECK: [[_76:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_72]] [[_60]] [[_87:%[0-9a-zA-Z_]+]] [[_80]]
// CHECK: [[_75:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_70]] [[_60]] [[_85:%[0-9a-zA-Z_]+]] [[_80]]
// CHECK: [[_74:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_69]] [[_60]] [[_84:%[0-9a-zA-Z_]+]] [[_80]]
// CHECK: [[_78:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_76]]
// CHECK: [[_79:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_74]]
// CHECK: [[_77:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_79]] [[_75]] [[_78]]
// CHECK: OpReturnValue [[_77]]
// CHECK: [[_80]] = OpLabel
// CHECK: [[_81:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_48]] [[_uint_4294967291]]
// CHECK: [[_82:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_5]] [[_35]] [[_81]]
// CHECK: [[_83:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_82]] 0
// CHECK: [[_84]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_83]] 0
// CHECK: [[_85]] = OpCompositeExtract [[_uint]] [[_82]] 1
// CHECK: [[_86:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_82]] 2
// CHECK: [[_87]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_86]] 0
// CHECK: OpBranch [[_73]]
// CHECK: OpFunctionEnd
// CHECK: [[_88:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_89:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_90:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_34]] [[_uint_0]]
// CHECK: [[_91:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_90]]
// CHECK: [[_92:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_5]] [[_47]] [[_91]]
// CHECK: [[_93:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_92]] 0
// CHECK: [[_94:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_93]] 0
// CHECK: [[_95:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_94]] 0
// CHECK: [[_96:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_94]] 1
// CHECK: [[_97:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_92]] 1
// CHECK: [[_98:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_92]] 2
// CHECK: [[_99:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_98]] 0
// CHECK: [[_100:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_99]] 0
// CHECK: [[_101:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_99]] 1
// CHECK: [[_102:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_102]] [[_95]]
// CHECK: [[_103:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_103]] [[_96]]
// CHECK: [[_104:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_104]] [[_97]]
// CHECK: [[_105:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]] [[_uint_2]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_105]] [[_100]]
// CHECK: [[_106:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]] [[_uint_2]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_106]] [[_101]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
