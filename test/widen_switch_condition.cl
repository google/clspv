// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// Prove that we can widen narrow bit widths on a switch condition, which can
// be generated for the switch condition by SimplifyCFG followed by InstCombine.

// There is a special check not assertion in the pattern checks below.

kernel void foo(global float *out, float x, float y) {

  int first_result;

  if (y >= 1.25f) {
    if (x > 0) {
      first_result = 0;
    } else {
      first_result = 1;
    }
  } else if (y >= 1.5f) {
    if (x > 0) {
      first_result = 2;
    } else {
      first_result = 3;
    }
  } else {
    if (y + 1.0f > 0) {
      first_result = 4;
    } else {
      first_result = 5;
    }
  }

  float fr = (float)(first_result);

  float result = -1.0f;
  if (fr == 0)
    result = 1.0f;
  else if (fr == 1)
    result = 0.0f;
  else if (fr == 2)
    result = 2.0f;

  *out = result;
}



// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 114
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_38:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_31:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_35]] Binding 0
// CHECK:  OpDecorate [[_36:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_36]] Binding 1
// CHECK:  OpDecorate [[_37:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_37]] Binding 2
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// There is one one integer width declared.
// CHECK-NOT: OpTypeInt
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_float_1_25:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1.25
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpUndef [[_uint]]
// CHECK:  [[_false:%[0-9a-zA-Z_]+]] = OpConstantFalse [[_bool]]
// CHECK:  [[_true:%[0-9a-zA-Z_]+]] = OpConstantTrue [[_bool]]
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpUndef [[_float]]
// CHECK:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK:  [[_float_n1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] -1
// CHECK:  [[_float_1_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1.5
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_31]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_32]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_30]] [[_31]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_36]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_37]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_38]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_35]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_36]] [[_uint_0]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_41]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_37]] [[_uint_0]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_43]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpFUnordLessThan [[_bool]] [[_44]] [[_float_1_25]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_45]]
// CHECK:  OpSelectionMerge [[_50:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_46]] [[_47:%[0-9a-zA-Z_]+]] [[_50]]
// CHECK:  [[_47]] = OpLabel
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpFUnordLessThanEqual [[_bool]] [[_42]] [[_float_0]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_48]] [[_uint_1]] [[_uint_0]]
// CHECK:  OpBranch [[_50]]
// CHECK:  [[_50]] = OpLabel
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_47]] [[_true]] [[_39]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_49]] [[_47]] [[_18]] [[_39]]
// CHECK:  OpSelectionMerge [[_53:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_52]] [[_99:%[0-9a-zA-Z_]+]] [[_53]]
// CHECK:  [[_53]] = OpLabel
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_51]] [[_50]] [[_109:%[0-9a-zA-Z_]+]] [[_108:%[0-9a-zA-Z_]+]]
// CHECK:  OpBranch [[_55:%[0-9a-zA-Z_]+]]
// CHECK:  [[_55]] = OpLabel
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpSLessThan [[_bool]] [[_54]] [[_uint_1]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_56]]
// CHECK:  OpSelectionMerge [[_73:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_57]] [[_58:%[0-9a-zA-Z_]+]] [[_73]]
// CHECK:  [[_58]] = OpLabel
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpSLessThan [[_bool]] [[_54]] [[_uint_2]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_59]]
// CHECK:  OpSelectionMerge [[_68:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_60]] [[_61:%[0-9a-zA-Z_]+]] [[_68]]
// CHECK:  [[_61]] = OpLabel
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_54]] [[_uint_2]]
// CHECK:  OpSelectionMerge [[_64:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_62]] [[_63:%[0-9a-zA-Z_]+]] [[_64]]
// CHECK:  [[_63]] = OpLabel
// CHECK:  OpBranch [[_64]]
// CHECK:  [[_64]] = OpLabel
// CHECK:  [[_67:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_63]] [[_true]] [[_61]]
// CHECK:  [[_66:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_true]] [[_63]] [[_false]] [[_61]]
// CHECK:  [[_65:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_2]] [[_63]] [[_23]] [[_61]]
// CHECK:  OpBranch [[_68]]
// CHECK:  [[_68]] = OpLabel
// CHECK:  [[_72:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_67]] [[_64]] [[_false]] [[_58]]
// CHECK:  [[_71:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_66]] [[_64]] [[_false]] [[_58]]
// CHECK:  [[_70:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_64]] [[_true]] [[_58]]
// CHECK:  [[_69:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_65]] [[_64]] [[_23]] [[_58]]
// CHECK:  OpBranch [[_73]]
// CHECK:  [[_73]] = OpLabel
// CHECK:  [[_79:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_68]] [[_true]] [[_55]]
// CHECK:  [[_78:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_72]] [[_68]] [[_false]] [[_55]]
// CHECK:  [[_77:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_71]] [[_68]] [[_false]] [[_55]]
// CHECK:  [[_76:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_70]] [[_68]] [[_false]] [[_55]]
// CHECK:  [[_75:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_69]] [[_68]] [[_23]] [[_55]]
// CHECK:  [[_74:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_68]] [[_23]] [[_55]]
// CHECK:  OpSelectionMerge [[_80:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_79]] [[_96:%[0-9a-zA-Z_]+]] [[_80]]
// CHECK:  [[_80]] = OpLabel
// CHECK:  [[_82:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_98:%[0-9a-zA-Z_]+]] [[_96]] [[_78]] [[_73]]
// CHECK:  [[_81:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_1]] [[_96]] [[_23]] [[_73]]
// CHECK:  OpSelectionMerge [[_83:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_82]] [[_95:%[0-9a-zA-Z_]+]] [[_83]]
// CHECK:  [[_83]] = OpLabel
// CHECK:  [[_85:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_true]] [[_95]] [[_77]] [[_80]]
// CHECK:  [[_84:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_n1]] [[_95]] [[_75]] [[_80]]
// CHECK:  OpSelectionMerge [[_86:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_85]] [[_93:%[0-9a-zA-Z_]+]] [[_86]]
// CHECK:  [[_86]] = OpLabel
// CHECK:  [[_88:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_true]] [[_93]] [[_76]] [[_83]]
// CHECK:  [[_87:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_94:%[0-9a-zA-Z_]+]] [[_93]] [[_74]] [[_83]]
// CHECK:  OpSelectionMerge [[_89:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_88]] [[_91:%[0-9a-zA-Z_]+]] [[_89]]
// CHECK:  [[_89]] = OpLabel
// CHECK:  [[_90:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_81]] [[_86]] [[_92:%[0-9a-zA-Z_]+]] [[_91]]
// CHECK:  OpStore [[_40]] [[_90]]
// CHECK:  OpReturn
// CHECK:  [[_91]] = OpLabel
// CHECK:  [[_92]] = OpPhi [[_float]] [[_87]] [[_86]]
// CHECK:  OpBranch [[_89]]
// CHECK:  [[_93]] = OpLabel
// CHECK:  [[_94]] = OpPhi [[_float]] [[_84]] [[_83]]
// CHECK:  OpBranch [[_86]]
// CHECK:  [[_95]] = OpLabel
// CHECK:  OpBranch [[_83]]
// CHECK:  [[_96]] = OpLabel
// CHECK:  [[_97:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_54]] [[_uint_0]]
// CHECK:  [[_98]] = OpLogicalNot [[_bool]] [[_97]]
// CHECK:  OpBranch [[_80]]
// CHECK:  [[_99]] = OpLabel
// CHECK:  [[_100:%[0-9a-zA-Z_]+]] = OpFUnordLessThan [[_bool]] [[_44]] [[_float_1_5]]
// CHECK:  [[_101:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_100]]
// CHECK:  OpSelectionMerge [[_105:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_101]] [[_102:%[0-9a-zA-Z_]+]] [[_105]]
// CHECK:  [[_102]] = OpLabel
// CHECK:  [[_103:%[0-9a-zA-Z_]+]] = OpFOrdGreaterThan [[_bool]] [[_42]] [[_float_0]]
// CHECK:  [[_104:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_103]] [[_uint_2]] [[_uint_3]]
// CHECK:  OpBranch [[_105]]
// CHECK:  [[_105]] = OpLabel
// CHECK:  [[_107:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_102]] [[_true]] [[_99]]
// CHECK:  [[_106:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_104]] [[_102]] [[_18]] [[_99]]
// CHECK:  OpSelectionMerge [[_108]] None
// CHECK:  OpBranchConditional [[_107]] [[_110:%[0-9a-zA-Z_]+]] [[_108]]
// CHECK:  [[_108]] = OpLabel
// CHECK:  [[_109]] = OpPhi [[_uint]] [[_113:%[0-9a-zA-Z_]+]] [[_110]] [[_106]] [[_105]]
// CHECK:  OpBranch [[_53]]
// CHECK:  [[_110]] = OpLabel
// CHECK:  [[_111:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_44]] [[_float_1]]
// CHECK:  [[_112:%[0-9a-zA-Z_]+]] = OpFOrdGreaterThan [[_bool]] [[_111]] [[_float_0]]
// CHECK:  [[_113]] = OpSelect [[_uint]] [[_112]] [[_uint_4]] [[_uint_5]]
// CHECK:  OpBranch [[_108]]
// CHECK:  OpFunctionEnd
