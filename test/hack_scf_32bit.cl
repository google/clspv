// Test the -hack-scf option.

// RUN: clspv %s -S -o %t.spvasm -hack-scf
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-scf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void greaterthan_m2(__global float* outDest, int inWidth, int inHeight,
                           int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x + offset;
  int y_cmp = y + offset;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp > -3) ? 1.0f : -1.0f;
  } else {
    outDest[index] = 0.0f;
  }
}

kernel void greaterthan(__global float* outDest, int inWidth, int inHeight,
                        int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x - offset + 3;
  int y_cmp = offset - 1 - y;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp > y_cmp) ? 1.0f : -1.0f;
  } else {
    outDest[index] = 0.0f;
  }
}

kernel void lessthan(__global float* outDest, int inWidth, int inHeight,
                        int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x - offset + 3;
  int y_cmp = offset - 1 - y;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp < y_cmp) ? 1.0f : -1.0f;
  } else {
    outDest[index] = 0.0f;
  }
}

kernel void greaterequal(__global float* outDest, int inWidth, int inHeight,
                        int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x - offset + 3;
  int y_cmp = offset - 1 - y;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp >= y_cmp) ? 1.0f : -1.0f;
  } else {
    outDest[index] = 0.0f;
  }
}

kernel void lessequal(__global float* outDest, int inWidth, int inHeight,
                        int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x - offset + 3;
  int y_cmp = offset - 1 - y;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp <= y_cmp) ? 1.0f : -1.0f;
  } else {
    outDest[index] = 0.0f;
  }
}

kernel void greaterthan_const(__global float* outDest, int inWidth,
                              int inHeight, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x + offset;

  int index = (y * inWidth) + x;

  float value = 99.0f;
  switch (y) {
    case 0:
      value = (x_cmp > -4) ? 1.0f : -1.0f;
      break;
    case 1:
      value = (x_cmp > 3) ? 1.0f : -1.0f;
      break;
    case 2:
      value = (x_cmp > -2) ? 1.0f : -1.0f;
      break;
    case 3:
      value = (x_cmp > 1) ? 1.0f : -1.0f;
      break;
    case 4:
      value = (x_cmp > 0) ? 1.0f : -1.0f;
      break;
    case 5:
      value = (x_cmp > -1) ? 1.0f : -1.0f;
      break;
    case 6:
      value = (x_cmp > 2) ? 1.0f : -1.0f;
      break;
    case 7:
      value = (x_cmp > -3) ? 1.0f : -1.0f;
      break;
    default:
      break;
  }
  outDest[index] = value;
}

// Note: This gets compiled down to OpSignedLessThan
kernel void greaterthan_const_left(__global float* outDest, int inWidth,
                                   int inHeight, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x + offset;

  int index = (y * inWidth) + x;

  float value = 0.0f;
  switch (y) {
    case 0:
      value = (-4 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 1:
      value = (3 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 2:
      value = (-2 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 3:
      value = (1 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 4:
      value = (0 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 5:
      value = (-1 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 6:
      value = (2 > x_cmp) ? 1.0f : -1.0f;
      break;
    case 7:
      value = (-3 > x_cmp) ? 1.0f : -1.0f;
      break;
    default:
      break;
  }
  outDest[index] = value;
}

// Compute the same thing as above but using vector int2 comparisons.
kernel void greaterthan_const_vec2(__global int* outDest, int inWidth,
                                  int inHeight, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int xcmp = x + offset;
  int2 x_cmp2 = (int2)(xcmp, xcmp);

  int index = (y * inWidth) + x;

  const int fake_float_one =  0x3f800000u;   // 1.0, same as 0x3F800000
  const int fake_float_mone = 0xbf800000u;  // -1.0, same as 0xBF800000
  int2 one = (int2)(fake_float_one);
  int2 mone = (int2)(fake_float_mone);

  int2 compare_to = (int2)(0, 0);
  if (y < 2) {
    compare_to = (int2)(-4, 3);
  } else if (y < 4) {
    compare_to = (int2)(-2, 1);
  } else if (y < 6) {
    compare_to = (int2)(0, -1);
  } else if (y < 8) {
    compare_to = (int2)(2, -3);
  }
  int2 value = ((x_cmp2 > compare_to) & one) | ((x_cmp2 <= compare_to) & mone);
  int component = (y & 1) ? value.y : value.x;
  outDest[index] = component;
}

// Compute the same thing as above but using vector int4 comparisons.
kernel void greaterthan_const_vec4(__global int* outDest, int inWidth,
                                   int inHeight, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int xcmp = x + offset;
  int4 x_cmp4 = (int4)(xcmp);

  int index = (y * inWidth) + x;

  const int fake_float_one = 0x3f800000u;   // 1.0, same as 0x3F800000
  const int fake_float_mone = 0xbf800000u;  // -1.0, same as 0xBF800000
  int4 one = (int4)(fake_float_one);
  int4 mone = (int4)(fake_float_mone);

  int4 compare_to = (y < 4) ? (int4)(-4, 3, -2, 1) : (int4)(0, -1, 2, -3);
  int4 value = ((x_cmp4 > compare_to) & one) | ((x_cmp4 <= compare_to) & mone);
  int2 components2 = (y & 2) ? value.zw : value.xy;
  int component = (y & 1) ? components2.y : components2.x;
  outDest[index] = component;
}


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 681
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_78:%[0-9a-zA-Z_]+]] "greaterthan_m2" [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK:  OpEntryPoint GLCompute [[_111:%[0-9a-zA-Z_]+]] "greaterthan" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_147:%[0-9a-zA-Z_]+]] "lessthan" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_183:%[0-9a-zA-Z_]+]] "greaterequal" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_219:%[0-9a-zA-Z_]+]] "lessequal" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_255:%[0-9a-zA-Z_]+]] "greaterthan_const" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_418:%[0-9a-zA-Z_]+]] "greaterthan_const_left" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_581:%[0-9a-zA-Z_]+]] "greaterthan_const_vec2" [[_gl_GlobalInvocationID]]
// CHECK:  OpEntryPoint GLCompute [[_639:%[0-9a-zA-Z_]+]] "greaterthan_const_vec4" [[_gl_GlobalInvocationID]]
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_68:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_69:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_70:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_9]] Block
// CHECK:  OpDecorate [[_gl_GlobalInvocationID]] BuiltIn GlobalInvocationId
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_73:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_73]] Binding 0
// CHECK:  OpDecorate [[_74:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_74]] Binding 1
// CHECK:  OpDecorate [[_75:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_75]] Binding 2
// CHECK:  OpDecorate [[_76:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_76]] Binding 3
// CHECK:  OpDecorate [[_77:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_77]] Binding 0
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__struct_6]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_9]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK:  [[_bool:%[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK:  [[_v2bool:%[0-9a-zA-Z_]+]] = OpTypeVector [[_bool]] 2
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_v4bool:%[0-9a-zA-Z_]+]] = OpTypeVector [[_bool]] 4
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2147483648:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2147483648
// CHECK:  [[_uint_4294967293:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967293
// CHECK:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK:  [[_float_n1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] -1
// CHECK:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK:  [[_uint_4294967295:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967295
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[_uint_6:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 6
// CHECK:  [[_uint_7:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 7
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpUndef [[_float]]
// CHECK:  [[_false:%[0-9a-zA-Z_]+]] = OpConstantFalse [[_bool]]
// CHECK:  [[_true:%[0-9a-zA-Z_]+]] = OpConstantTrue [[_bool]]
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK:  [[_float_99:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 99
// CHECK:  [[_uint_4294967292:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967292
// CHECK:  [[_uint_4294967294:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4294967294
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpUndef [[_v2uint]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_4294967292]] [[_uint_3]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_2147483648]] [[_uint_2147483648]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpConstantNull [[_v2uint]]
// CHECK:  [[_uint_1065353216:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1065353216
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_1065353216]] [[_uint_1065353216]]
// CHECK:  [[_uint_3212836864:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3212836864
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_3212836864]] [[_uint_3212836864]]
// CHECK:  [[_uint_8:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 8
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpUndef [[_v2bool]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_2]] [[_uint_4294967293]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_0]] [[_uint_4294967295]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v2uint]] [[_uint_4294967294]] [[_uint_1]]
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpUndef [[_v4uint]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpUndef [[_v4bool]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_4294967292]] [[_uint_3]] [[_uint_4294967294]] [[_uint_1]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_0]] [[_uint_4294967295]] [[_uint_2]] [[_uint_4294967293]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_1]] [[_uint_1]] [[_uint_1]] [[_uint_1]]
// CHECK:  [[_63:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_2147483648]] [[_uint_2147483648]] [[_uint_2147483648]] [[_uint_2147483648]]
// CHECK:  [[_64:%[0-9a-zA-Z_]+]] = OpConstantNull [[_v4uint]]
// CHECK:  [[_65:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_1065353216]] [[_uint_1065353216]] [[_uint_1065353216]] [[_uint_1065353216]]
// CHECK:  [[_66:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4uint]] [[_uint_3212836864]] [[_uint_3212836864]] [[_uint_3212836864]] [[_uint_3212836864]]
// CHECK:  [[_gl_GlobalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK:  [[_68]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_69]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_70]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_68]] [[_69]] [[_70]]
// CHECK:  [[_72:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_73]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_74]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_75]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_76]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_77]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK:  [[_78]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_79:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_80:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_81:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_80]]
// CHECK:  [[_82:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_83:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_82]]
// CHECK:  [[_84:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_85:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_84]]
// CHECK:  [[_86:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_87:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_86]]
// CHECK:  [[_88:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_89:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_88]]
// CHECK:  [[_90:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_89]] [[_81]]
// CHECK:  [[_91:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_90]] [[_87]]
// CHECK:  [[_92:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_81]] [[_87]]
// CHECK:  [[_93:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_92]] [[_uint_1]]
// CHECK:  [[_94:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_93]] [[_uint_2147483648]]
// CHECK:  [[_95:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_94]] [[_uint_0]]
// CHECK:  [[_96:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_81]] [[_89]]
// CHECK:  [[_97:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_96]] [[_uint_1]]
// CHECK:  [[_98:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_97]] [[_uint_2147483648]]
// CHECK:  [[_99:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_98]] [[_uint_0]]
// CHECK:  [[_100:%[0-9a-zA-Z_]+]] = OpLogicalAnd [[_bool]] [[_95]] [[_99]]
// CHECK:  OpSelectionMerge [[_108:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_100]] [[_101:%[0-9a-zA-Z_]+]] [[_108]]
// CHECK:  [[_101]] = OpLabel
// CHECK:  [[_102:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_87]] [[_85]]
// CHECK:  [[_103:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_102]] [[_uint_4294967293]]
// CHECK:  [[_104:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_103]] [[_uint_1]]
// CHECK:  [[_105:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_104]] [[_uint_2147483648]]
// CHECK:  [[_106:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_105]] [[_uint_0]]
// CHECK:  [[_107:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_106]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_108]]
// CHECK:  [[_108]] = OpLabel
// CHECK:  [[_109:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_79]] [[_107]] [[_101]]
// CHECK:  [[_110:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_91]]
// CHECK:  OpStore [[_110]] [[_109]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_111]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_112:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_113:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_114:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_113]]
// CHECK:  [[_115:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_116:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_115]]
// CHECK:  [[_117:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_118:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_117]]
// CHECK:  [[_119:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_120:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_119]]
// CHECK:  [[_121:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_122:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_121]]
// CHECK:  [[_123:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_122]] [[_114]]
// CHECK:  [[_124:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_123]] [[_120]]
// CHECK:  [[_125:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_114]] [[_120]]
// CHECK:  [[_126:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_125]] [[_uint_1]]
// CHECK:  [[_127:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_126]] [[_uint_2147483648]]
// CHECK:  [[_128:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_127]] [[_uint_0]]
// CHECK:  [[_129:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_114]] [[_122]]
// CHECK:  [[_130:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_129]] [[_uint_1]]
// CHECK:  [[_131:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_130]] [[_uint_2147483648]]
// CHECK:  [[_132:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_131]] [[_uint_0]]
// CHECK:  [[_133:%[0-9a-zA-Z_]+]] = OpLogicalAnd [[_bool]] [[_128]] [[_132]]
// CHECK:  OpSelectionMerge [[_144:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_133]] [[_134:%[0-9a-zA-Z_]+]] [[_144]]
// CHECK:  [[_134]] = OpLabel
// CHECK:  [[_135:%[0-9a-zA-Z_]+]] = OpBitwiseXor [[_uint]] [[_122]] [[_uint_4294967295]]
// CHECK:  [[_136:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_135]] [[_118]]
// CHECK:  [[_137:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_118]]
// CHECK:  [[_138:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_137]] [[_120]]
// CHECK:  [[_139:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_138]] [[_136]]
// CHECK:  [[_140:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_139]] [[_uint_1]]
// CHECK:  [[_141:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_140]] [[_uint_2147483648]]
// CHECK:  [[_142:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_141]] [[_uint_0]]
// CHECK:  [[_143:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_142]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_144]]
// CHECK:  [[_144]] = OpLabel
// CHECK:  [[_145:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_112]] [[_143]] [[_134]]
// CHECK:  [[_146:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_124]]
// CHECK:  OpStore [[_146]] [[_145]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_147]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_148:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_149:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_150:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_149]]
// CHECK:  [[_151:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_152:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_151]]
// CHECK:  [[_153:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_154:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_153]]
// CHECK:  [[_155:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_156:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_155]]
// CHECK:  [[_157:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_158:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_157]]
// CHECK:  [[_159:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_158]] [[_150]]
// CHECK:  [[_160:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_159]] [[_156]]
// CHECK:  [[_161:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_150]] [[_156]]
// CHECK:  [[_162:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_161]] [[_uint_1]]
// CHECK:  [[_163:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_162]] [[_uint_2147483648]]
// CHECK:  [[_164:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_163]] [[_uint_0]]
// CHECK:  [[_165:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_150]] [[_158]]
// CHECK:  [[_166:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_165]] [[_uint_1]]
// CHECK:  [[_167:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_166]] [[_uint_2147483648]]
// CHECK:  [[_168:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_167]] [[_uint_0]]
// CHECK:  [[_169:%[0-9a-zA-Z_]+]] = OpLogicalAnd [[_bool]] [[_164]] [[_168]]
// CHECK:  OpSelectionMerge [[_180:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_169]] [[_170:%[0-9a-zA-Z_]+]] [[_180]]
// CHECK:  [[_170]] = OpLabel
// CHECK:  [[_171:%[0-9a-zA-Z_]+]] = OpBitwiseXor [[_uint]] [[_158]] [[_uint_4294967295]]
// CHECK:  [[_172:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_171]] [[_154]]
// CHECK:  [[_173:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_154]]
// CHECK:  [[_174:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_173]] [[_156]]
// CHECK:  [[_175:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_172]] [[_174]]
// CHECK:  [[_176:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_175]] [[_uint_1]]
// CHECK:  [[_177:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_176]] [[_uint_2147483648]]
// CHECK:  [[_178:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_177]] [[_uint_0]]
// CHECK:  [[_179:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_178]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_180]]
// CHECK:  [[_180]] = OpLabel
// CHECK:  [[_181:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_148]] [[_179]] [[_170]]
// CHECK:  [[_182:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_160]]
// CHECK:  OpStore [[_182]] [[_181]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_183]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_184:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_185:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_186:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_185]]
// CHECK:  [[_187:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_188:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_187]]
// CHECK:  [[_189:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_190:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_189]]
// CHECK:  [[_191:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_192:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_191]]
// CHECK:  [[_193:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_194:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_193]]
// CHECK:  [[_195:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_194]] [[_186]]
// CHECK:  [[_196:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_195]] [[_192]]
// CHECK:  [[_197:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_186]] [[_192]]
// CHECK:  [[_198:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_197]] [[_uint_1]]
// CHECK:  [[_199:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_198]] [[_uint_2147483648]]
// CHECK:  [[_200:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_199]] [[_uint_0]]
// CHECK:  [[_201:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_186]] [[_194]]
// CHECK:  [[_202:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_201]] [[_uint_1]]
// CHECK:  [[_203:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_202]] [[_uint_2147483648]]
// CHECK:  [[_204:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_203]] [[_uint_0]]
// CHECK:  [[_205:%[0-9a-zA-Z_]+]] = OpLogicalAnd [[_bool]] [[_200]] [[_204]]
// CHECK:  OpSelectionMerge [[_216:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_205]] [[_206:%[0-9a-zA-Z_]+]] [[_216]]
// CHECK:  [[_206]] = OpLabel
// CHECK:  [[_207:%[0-9a-zA-Z_]+]] = OpBitwiseXor [[_uint]] [[_194]] [[_uint_4294967295]]
// CHECK:  [[_208:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_207]] [[_190]]
// CHECK:  [[_209:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_190]]
// CHECK:  [[_210:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_209]] [[_192]]
// CHECK:  [[_211:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_208]] [[_210]]
// CHECK:  [[_212:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_211]] [[_uint_1]]
// CHECK:  [[_213:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_212]] [[_uint_2147483648]]
// CHECK:  [[_214:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_213]] [[_uint_0]]
// CHECK:  [[_215:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_214]] [[_float_n1]] [[_float_1]]
// CHECK:  OpBranch [[_216]]
// CHECK:  [[_216]] = OpLabel
// CHECK:  [[_217:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_184]] [[_215]] [[_206]]
// CHECK:  [[_218:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_196]]
// CHECK:  OpStore [[_218]] [[_217]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_219]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_220:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_221:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_222:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_221]]
// CHECK:  [[_223:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_224:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_223]]
// CHECK:  [[_225:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_226:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_225]]
// CHECK:  [[_227:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_228:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_227]]
// CHECK:  [[_229:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_230:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_229]]
// CHECK:  [[_231:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_230]] [[_222]]
// CHECK:  [[_232:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_231]] [[_228]]
// CHECK:  [[_233:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_222]] [[_228]]
// CHECK:  [[_234:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_233]] [[_uint_1]]
// CHECK:  [[_235:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_234]] [[_uint_2147483648]]
// CHECK:  [[_236:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_235]] [[_uint_0]]
// CHECK:  [[_237:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_222]] [[_230]]
// CHECK:  [[_238:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_237]] [[_uint_1]]
// CHECK:  [[_239:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_238]] [[_uint_2147483648]]
// CHECK:  [[_240:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_239]] [[_uint_0]]
// CHECK:  [[_241:%[0-9a-zA-Z_]+]] = OpLogicalAnd [[_bool]] [[_236]] [[_240]]
// CHECK:  OpSelectionMerge [[_252:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_241]] [[_242:%[0-9a-zA-Z_]+]] [[_252]]
// CHECK:  [[_242]] = OpLabel
// CHECK:  [[_243:%[0-9a-zA-Z_]+]] = OpBitwiseXor [[_uint]] [[_230]] [[_uint_4294967295]]
// CHECK:  [[_244:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_243]] [[_226]]
// CHECK:  [[_245:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_226]]
// CHECK:  [[_246:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_245]] [[_228]]
// CHECK:  [[_247:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_246]] [[_244]]
// CHECK:  [[_248:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_247]] [[_uint_1]]
// CHECK:  [[_249:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_248]] [[_uint_2147483648]]
// CHECK:  [[_250:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_249]] [[_uint_0]]
// CHECK:  [[_251:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_250]] [[_float_n1]] [[_float_1]]
// CHECK:  OpBranch [[_252]]
// CHECK:  [[_252]] = OpLabel
// CHECK:  [[_253:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_220]] [[_251]] [[_242]]
// CHECK:  [[_254:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_232]]
// CHECK:  OpStore [[_254]] [[_253]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_255]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_256:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_257:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_258:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_257]]
// CHECK:  [[_259:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_260:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_259]]
// CHECK:  [[_261:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_262:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_261]]
// CHECK:  [[_263:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_264:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_263]]
// CHECK:  [[_265:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_266:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_265]]
// CHECK:  [[_267:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_264]] [[_262]]
// CHECK:  [[_268:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_266]] [[_258]]
// CHECK:  [[_269:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_268]] [[_264]]
// CHECK:  OpBranch [[_270:%[0-9a-zA-Z_]+]]
// CHECK:  [[_270]] = OpLabel
// CHECK:  [[_271:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4]] [[_266]]
// CHECK:  [[_272:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_271]] [[_uint_1]]
// CHECK:  [[_273:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_272]] [[_uint_2147483648]]
// CHECK:  [[_274:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_273]] [[_uint_0]]
// CHECK:  [[_275:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_274]]
// CHECK:  OpSelectionMerge [[_340:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_275]] [[_276:%[0-9a-zA-Z_]+]] [[_340]]
// CHECK:  [[_276]] = OpLabel
// CHECK:  [[_277:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_6]] [[_266]]
// CHECK:  [[_278:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_277]] [[_uint_1]]
// CHECK:  [[_279:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_278]] [[_uint_2147483648]]
// CHECK:  [[_280:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_279]] [[_uint_0]]
// CHECK:  [[_281:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_280]]
// CHECK:  OpSelectionMerge [[_311:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_281]] [[_282:%[0-9a-zA-Z_]+]] [[_311]]
// CHECK:  [[_282]] = OpLabel
// CHECK:  [[_283:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_7]] [[_266]]
// CHECK:  [[_284:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_283]] [[_uint_1]]
// CHECK:  [[_285:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_284]] [[_uint_2147483648]]
// CHECK:  [[_286:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_285]] [[_uint_0]]
// CHECK:  [[_287:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_286]]
// CHECK:  OpSelectionMerge [[_299:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_287]] [[_288:%[0-9a-zA-Z_]+]] [[_299]]
// CHECK:  [[_288]] = OpLabel
// CHECK:  [[_289:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_266]] [[_uint_7]]
// CHECK:  OpSelectionMerge [[_296:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_289]] [[_290:%[0-9a-zA-Z_]+]] [[_296]]
// CHECK:  [[_290]] = OpLabel
// CHECK:  [[_291:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_4294967293]]
// CHECK:  [[_292:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_291]] [[_uint_1]]
// CHECK:  [[_293:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_292]] [[_uint_2147483648]]
// CHECK:  [[_294:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_293]] [[_uint_0]]
// CHECK:  [[_295:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_294]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_296]]
// CHECK:  [[_296]] = OpLabel
// CHECK:  [[_298:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_290]] [[_true]] [[_288]]
// CHECK:  [[_297:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_295]] [[_290]] [[_36]] [[_288]]
// CHECK:  OpBranch [[_299]]
// CHECK:  [[_299]] = OpLabel
// CHECK:  [[_302:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_296]] [[_true]] [[_282]]
// CHECK:  [[_301:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_298]] [[_296]] [[_false]] [[_282]]
// CHECK:  [[_300:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_297]] [[_296]] [[_36]] [[_282]]
// CHECK:  OpSelectionMerge [[_303:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_302]] [[_305:%[0-9a-zA-Z_]+]] [[_303]]
// CHECK:  [[_303]] = OpLabel
// CHECK:  [[_304:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_310:%[0-9a-zA-Z_]+]] [[_305]] [[_300]] [[_299]]
// CHECK:  OpBranch [[_311]]
// CHECK:  [[_305]] = OpLabel
// CHECK:  [[_306:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_2]]
// CHECK:  [[_307:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_306]] [[_uint_1]]
// CHECK:  [[_308:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_307]] [[_uint_2147483648]]
// CHECK:  [[_309:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_308]] [[_uint_0]]
// CHECK:  [[_310]] = OpSelect [[_float]] [[_309]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_303]]
// CHECK:  [[_311]] = OpLabel
// CHECK:  [[_314:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_303]] [[_true]] [[_276]]
// CHECK:  [[_313:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_301]] [[_303]] [[_false]] [[_276]]
// CHECK:  [[_312:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_304]] [[_303]] [[_36]] [[_276]]
// CHECK:  OpSelectionMerge [[_315:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_314]] [[_317:%[0-9a-zA-Z_]+]] [[_315]]
// CHECK:  [[_315]] = OpLabel
// CHECK:  [[_316:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_333:%[0-9a-zA-Z_]+]] [[_332:%[0-9a-zA-Z_]+]] [[_312]] [[_311]]
// CHECK:  OpBranch [[_340]]
// CHECK:  [[_317]] = OpLabel
// CHECK:  [[_318:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_5]] [[_266]]
// CHECK:  [[_319:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_318]] [[_uint_1]]
// CHECK:  [[_320:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_319]] [[_uint_2147483648]]
// CHECK:  [[_321:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_320]] [[_uint_0]]
// CHECK:  [[_322:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_321]]
// CHECK:  OpSelectionMerge [[_329:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_322]] [[_323:%[0-9a-zA-Z_]+]] [[_329]]
// CHECK:  [[_323]] = OpLabel
// CHECK:  [[_324:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_4294967295]]
// CHECK:  [[_325:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_324]] [[_uint_1]]
// CHECK:  [[_326:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_325]] [[_uint_2147483648]]
// CHECK:  [[_327:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_326]] [[_uint_0]]
// CHECK:  [[_328:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_327]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_329]]
// CHECK:  [[_329]] = OpLabel
// CHECK:  [[_331:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_323]] [[_true]] [[_317]]
// CHECK:  [[_330:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_328]] [[_323]] [[_36]] [[_317]]
// CHECK:  OpSelectionMerge [[_332]] None
// CHECK:  OpBranchConditional [[_331]] [[_334:%[0-9a-zA-Z_]+]] [[_332]]
// CHECK:  [[_332]] = OpLabel
// CHECK:  [[_333]] = OpPhi [[_float]] [[_339:%[0-9a-zA-Z_]+]] [[_334]] [[_330]] [[_329]]
// CHECK:  OpBranch [[_315]]
// CHECK:  [[_334]] = OpLabel
// CHECK:  [[_335:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_0]]
// CHECK:  [[_336:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_335]] [[_uint_1]]
// CHECK:  [[_337:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_336]] [[_uint_2147483648]]
// CHECK:  [[_338:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_337]] [[_uint_0]]
// CHECK:  [[_339]] = OpSelect [[_float]] [[_338]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_332]]
// CHECK:  [[_340]] = OpLabel
// CHECK:  [[_343:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_315]] [[_true]] [[_270]]
// CHECK:  [[_342:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_313]] [[_315]] [[_false]] [[_270]]
// CHECK:  [[_341:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_316]] [[_315]] [[_36]] [[_270]]
// CHECK:  OpSelectionMerge [[_344:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_343]] [[_361:%[0-9a-zA-Z_]+]] [[_344]]
// CHECK:  [[_344]] = OpLabel
// CHECK:  [[_347:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_396:%[0-9a-zA-Z_]+]] [[_393:%[0-9a-zA-Z_]+]] [[_342]] [[_340]]
// CHECK:  [[_346:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_395:%[0-9a-zA-Z_]+]] [[_393]] [[_false]] [[_340]]
// CHECK:  [[_345:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_394:%[0-9a-zA-Z_]+]] [[_393]] [[_341]] [[_340]]
// CHECK:  OpSelectionMerge [[_348:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_347]] [[_360:%[0-9a-zA-Z_]+]] [[_348]]
// CHECK:  [[_348]] = OpLabel
// CHECK:  [[_350:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_360]] [[_346]] [[_344]]
// CHECK:  [[_349:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_99]] [[_360]] [[_345]] [[_344]]
// CHECK:  OpSelectionMerge [[_351:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_350]] [[_354:%[0-9a-zA-Z_]+]] [[_351]]
// CHECK:  [[_351]] = OpLabel
// CHECK:  [[_352:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_349]] [[_348]] [[_359:%[0-9a-zA-Z_]+]] [[_354]]
// CHECK:  [[_353:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_269]]
// CHECK:  OpStore [[_353]] [[_352]]
// CHECK:  OpReturn
// CHECK:  [[_354]] = OpLabel
// CHECK:  [[_355:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_4294967292]]
// CHECK:  [[_356:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_355]] [[_uint_1]]
// CHECK:  [[_357:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_356]] [[_uint_2147483648]]
// CHECK:  [[_358:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_357]] [[_uint_0]]
// CHECK:  [[_359]] = OpSelect [[_float]] [[_358]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_351]]
// CHECK:  [[_360]] = OpLabel
// CHECK:  OpBranch [[_348]]
// CHECK:  [[_361]] = OpLabel
// CHECK:  [[_362:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_2]] [[_266]]
// CHECK:  [[_363:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_362]] [[_uint_1]]
// CHECK:  [[_364:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_363]] [[_uint_2147483648]]
// CHECK:  [[_365:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_364]] [[_uint_0]]
// CHECK:  [[_366:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_365]]
// CHECK:  OpSelectionMerge [[_390:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_366]] [[_367:%[0-9a-zA-Z_]+]] [[_390]]
// CHECK:  [[_367]] = OpLabel
// CHECK:  [[_368:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_266]]
// CHECK:  [[_369:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_368]] [[_uint_1]]
// CHECK:  [[_370:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_369]] [[_uint_2147483648]]
// CHECK:  [[_371:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_370]] [[_uint_0]]
// CHECK:  [[_372:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_371]]
// CHECK:  OpSelectionMerge [[_379:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_372]] [[_373:%[0-9a-zA-Z_]+]] [[_379]]
// CHECK:  [[_373]] = OpLabel
// CHECK:  [[_374:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_1]]
// CHECK:  [[_375:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_374]] [[_uint_1]]
// CHECK:  [[_376:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_375]] [[_uint_2147483648]]
// CHECK:  [[_377:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_376]] [[_uint_0]]
// CHECK:  [[_378:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_377]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_379]]
// CHECK:  [[_379]] = OpLabel
// CHECK:  [[_381:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_373]] [[_true]] [[_367]]
// CHECK:  [[_380:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_378]] [[_373]] [[_36]] [[_367]]
// CHECK:  OpSelectionMerge [[_382:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_381]] [[_384:%[0-9a-zA-Z_]+]] [[_382]]
// CHECK:  [[_382]] = OpLabel
// CHECK:  [[_383:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_389:%[0-9a-zA-Z_]+]] [[_384]] [[_380]] [[_379]]
// CHECK:  OpBranch [[_390]]
// CHECK:  [[_384]] = OpLabel
// CHECK:  [[_385:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_4294967294]]
// CHECK:  [[_386:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_385]] [[_uint_1]]
// CHECK:  [[_387:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_386]] [[_uint_2147483648]]
// CHECK:  [[_388:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_387]] [[_uint_0]]
// CHECK:  [[_389]] = OpSelect [[_float]] [[_388]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_382]]
// CHECK:  [[_390]] = OpLabel
// CHECK:  [[_392:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_382]] [[_true]] [[_361]]
// CHECK:  [[_391:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_383]] [[_382]] [[_341]] [[_361]]
// CHECK:  OpSelectionMerge [[_393]] None
// CHECK:  OpBranchConditional [[_392]] [[_397:%[0-9a-zA-Z_]+]] [[_393]]
// CHECK:  [[_393]] = OpLabel
// CHECK:  [[_396]] = OpPhi [[_bool]] [[_414:%[0-9a-zA-Z_]+]] [[_412:%[0-9a-zA-Z_]+]] [[_342]] [[_390]]
// CHECK:  [[_395]] = OpPhi [[_bool]] [[_413:%[0-9a-zA-Z_]+]] [[_412]] [[_false]] [[_390]]
// CHECK:  [[_394]] = OpPhi [[_float]] [[_410:%[0-9a-zA-Z_]+]] [[_412]] [[_391]] [[_390]]
// CHECK:  OpBranch [[_344]]
// CHECK:  [[_397]] = OpLabel
// CHECK:  [[_398:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_1]] [[_266]]
// CHECK:  [[_399:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_398]] [[_uint_1]]
// CHECK:  [[_400:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_399]] [[_uint_2147483648]]
// CHECK:  [[_401:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_400]] [[_uint_0]]
// CHECK:  [[_402:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_401]]
// CHECK:  OpSelectionMerge [[_409:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_402]] [[_403:%[0-9a-zA-Z_]+]] [[_409]]
// CHECK:  [[_403]] = OpLabel
// CHECK:  [[_404:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_267]] [[_uint_3]]
// CHECK:  [[_405:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_404]] [[_uint_1]]
// CHECK:  [[_406:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_405]] [[_uint_2147483648]]
// CHECK:  [[_407:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_406]] [[_uint_0]]
// CHECK:  [[_408:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_407]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_409]]
// CHECK:  [[_409]] = OpLabel
// CHECK:  [[_411:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_403]] [[_true]] [[_397]]
// CHECK:  [[_410]] = OpPhi [[_float]] [[_408]] [[_403]] [[_391]] [[_397]]
// CHECK:  OpSelectionMerge [[_412]] None
// CHECK:  OpBranchConditional [[_411]] [[_415:%[0-9a-zA-Z_]+]] [[_412]]
// CHECK:  [[_412]] = OpLabel
// CHECK:  [[_414]] = OpPhi [[_bool]] [[_417:%[0-9a-zA-Z_]+]] [[_415]] [[_342]] [[_409]]
// CHECK:  [[_413]] = OpPhi [[_bool]] [[_true]] [[_415]] [[_false]] [[_409]]
// CHECK:  OpBranch [[_393]]
// CHECK:  [[_415]] = OpLabel
// CHECK:  [[_416:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_266]] [[_uint_0]]
// CHECK:  [[_417]] = OpLogicalNot [[_bool]] [[_416]]
// CHECK:  OpBranch [[_412]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_418]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_419:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_420:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_421:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_420]]
// CHECK:  [[_422:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_423:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_422]]
// CHECK:  [[_424:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_425:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_424]]
// CHECK:  [[_426:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_427:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_426]]
// CHECK:  [[_428:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_429:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_428]]
// CHECK:  [[_430:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_427]] [[_425]]
// CHECK:  [[_431:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_429]] [[_421]]
// CHECK:  [[_432:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_431]] [[_427]]
// CHECK:  OpBranch [[_433:%[0-9a-zA-Z_]+]]
// CHECK:  [[_433]] = OpLabel
// CHECK:  [[_434:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4]] [[_429]]
// CHECK:  [[_435:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_434]] [[_uint_1]]
// CHECK:  [[_436:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_435]] [[_uint_2147483648]]
// CHECK:  [[_437:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_436]] [[_uint_0]]
// CHECK:  [[_438:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_437]]
// CHECK:  OpSelectionMerge [[_503:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_438]] [[_439:%[0-9a-zA-Z_]+]] [[_503]]
// CHECK:  [[_439]] = OpLabel
// CHECK:  [[_440:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_6]] [[_429]]
// CHECK:  [[_441:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_440]] [[_uint_1]]
// CHECK:  [[_442:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_441]] [[_uint_2147483648]]
// CHECK:  [[_443:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_442]] [[_uint_0]]
// CHECK:  [[_444:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_443]]
// CHECK:  OpSelectionMerge [[_474:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_444]] [[_445:%[0-9a-zA-Z_]+]] [[_474]]
// CHECK:  [[_445]] = OpLabel
// CHECK:  [[_446:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_7]] [[_429]]
// CHECK:  [[_447:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_446]] [[_uint_1]]
// CHECK:  [[_448:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_447]] [[_uint_2147483648]]
// CHECK:  [[_449:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_448]] [[_uint_0]]
// CHECK:  [[_450:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_449]]
// CHECK:  OpSelectionMerge [[_462:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_450]] [[_451:%[0-9a-zA-Z_]+]] [[_462]]
// CHECK:  [[_451]] = OpLabel
// CHECK:  [[_452:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_429]] [[_uint_7]]
// CHECK:  OpSelectionMerge [[_459:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_452]] [[_453:%[0-9a-zA-Z_]+]] [[_459]]
// CHECK:  [[_453]] = OpLabel
// CHECK:  [[_454:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4294967293]] [[_430]]
// CHECK:  [[_455:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_454]] [[_uint_1]]
// CHECK:  [[_456:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_455]] [[_uint_2147483648]]
// CHECK:  [[_457:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_456]] [[_uint_0]]
// CHECK:  [[_458:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_457]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_459]]
// CHECK:  [[_459]] = OpLabel
// CHECK:  [[_461:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_453]] [[_true]] [[_451]]
// CHECK:  [[_460:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_458]] [[_453]] [[_36]] [[_451]]
// CHECK:  OpBranch [[_462]]
// CHECK:  [[_462]] = OpLabel
// CHECK:  [[_465:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_459]] [[_true]] [[_445]]
// CHECK:  [[_464:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_461]] [[_459]] [[_false]] [[_445]]
// CHECK:  [[_463:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_460]] [[_459]] [[_36]] [[_445]]
// CHECK:  OpSelectionMerge [[_466:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_465]] [[_468:%[0-9a-zA-Z_]+]] [[_466]]
// CHECK:  [[_466]] = OpLabel
// CHECK:  [[_467:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_473:%[0-9a-zA-Z_]+]] [[_468]] [[_463]] [[_462]]
// CHECK:  OpBranch [[_474]]
// CHECK:  [[_468]] = OpLabel
// CHECK:  [[_469:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_2]] [[_430]]
// CHECK:  [[_470:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_469]] [[_uint_1]]
// CHECK:  [[_471:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_470]] [[_uint_2147483648]]
// CHECK:  [[_472:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_471]] [[_uint_0]]
// CHECK:  [[_473]] = OpSelect [[_float]] [[_472]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_466]]
// CHECK:  [[_474]] = OpLabel
// CHECK:  [[_477:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_466]] [[_true]] [[_439]]
// CHECK:  [[_476:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_464]] [[_466]] [[_false]] [[_439]]
// CHECK:  [[_475:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_467]] [[_466]] [[_36]] [[_439]]
// CHECK:  OpSelectionMerge [[_478:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_477]] [[_480:%[0-9a-zA-Z_]+]] [[_478]]
// CHECK:  [[_478]] = OpLabel
// CHECK:  [[_479:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_496:%[0-9a-zA-Z_]+]] [[_495:%[0-9a-zA-Z_]+]] [[_475]] [[_474]]
// CHECK:  OpBranch [[_503]]
// CHECK:  [[_480]] = OpLabel
// CHECK:  [[_481:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_5]] [[_429]]
// CHECK:  [[_482:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_481]] [[_uint_1]]
// CHECK:  [[_483:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_482]] [[_uint_2147483648]]
// CHECK:  [[_484:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_483]] [[_uint_0]]
// CHECK:  [[_485:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_484]]
// CHECK:  OpSelectionMerge [[_492:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_485]] [[_486:%[0-9a-zA-Z_]+]] [[_492]]
// CHECK:  [[_486]] = OpLabel
// CHECK:  [[_487:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4294967295]] [[_430]]
// CHECK:  [[_488:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_487]] [[_uint_1]]
// CHECK:  [[_489:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_488]] [[_uint_2147483648]]
// CHECK:  [[_490:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_489]] [[_uint_0]]
// CHECK:  [[_491:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_490]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_492]]
// CHECK:  [[_492]] = OpLabel
// CHECK:  [[_494:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_486]] [[_true]] [[_480]]
// CHECK:  [[_493:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_491]] [[_486]] [[_36]] [[_480]]
// CHECK:  OpSelectionMerge [[_495]] None
// CHECK:  OpBranchConditional [[_494]] [[_497:%[0-9a-zA-Z_]+]] [[_495]]
// CHECK:  [[_495]] = OpLabel
// CHECK:  [[_496]] = OpPhi [[_float]] [[_502:%[0-9a-zA-Z_]+]] [[_497]] [[_493]] [[_492]]
// CHECK:  OpBranch [[_478]]
// CHECK:  [[_497]] = OpLabel
// CHECK:  [[_498:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_0]] [[_430]]
// CHECK:  [[_499:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_498]] [[_uint_1]]
// CHECK:  [[_500:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_499]] [[_uint_2147483648]]
// CHECK:  [[_501:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_500]] [[_uint_0]]
// CHECK:  [[_502]] = OpSelect [[_float]] [[_501]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_495]]
// CHECK:  [[_503]] = OpLabel
// CHECK:  [[_506:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_478]] [[_true]] [[_433]]
// CHECK:  [[_505:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_476]] [[_478]] [[_false]] [[_433]]
// CHECK:  [[_504:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_479]] [[_478]] [[_36]] [[_433]]
// CHECK:  OpSelectionMerge [[_507:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_506]] [[_524:%[0-9a-zA-Z_]+]] [[_507]]
// CHECK:  [[_507]] = OpLabel
// CHECK:  [[_510:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_559:%[0-9a-zA-Z_]+]] [[_556:%[0-9a-zA-Z_]+]] [[_505]] [[_503]]
// CHECK:  [[_509:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_558:%[0-9a-zA-Z_]+]] [[_556]] [[_false]] [[_503]]
// CHECK:  [[_508:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_557:%[0-9a-zA-Z_]+]] [[_556]] [[_504]] [[_503]]
// CHECK:  OpSelectionMerge [[_511:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_510]] [[_523:%[0-9a-zA-Z_]+]] [[_511]]
// CHECK:  [[_511]] = OpLabel
// CHECK:  [[_513:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_523]] [[_509]] [[_507]]
// CHECK:  [[_512:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_float_0]] [[_523]] [[_508]] [[_507]]
// CHECK:  OpSelectionMerge [[_514:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_513]] [[_517:%[0-9a-zA-Z_]+]] [[_514]]
// CHECK:  [[_514]] = OpLabel
// CHECK:  [[_515:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_512]] [[_511]] [[_522:%[0-9a-zA-Z_]+]] [[_517]]
// CHECK:  [[_516:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_73]] [[_uint_0]] [[_432]]
// CHECK:  OpStore [[_516]] [[_515]]
// CHECK:  OpReturn
// CHECK:  [[_517]] = OpLabel
// CHECK:  [[_518:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4294967292]] [[_430]]
// CHECK:  [[_519:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_518]] [[_uint_1]]
// CHECK:  [[_520:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_519]] [[_uint_2147483648]]
// CHECK:  [[_521:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_520]] [[_uint_0]]
// CHECK:  [[_522]] = OpSelect [[_float]] [[_521]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_514]]
// CHECK:  [[_523]] = OpLabel
// CHECK:  OpBranch [[_511]]
// CHECK:  [[_524]] = OpLabel
// CHECK:  [[_525:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_2]] [[_429]]
// CHECK:  [[_526:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_525]] [[_uint_1]]
// CHECK:  [[_527:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_526]] [[_uint_2147483648]]
// CHECK:  [[_528:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_527]] [[_uint_0]]
// CHECK:  [[_529:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_528]]
// CHECK:  OpSelectionMerge [[_553:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_529]] [[_530:%[0-9a-zA-Z_]+]] [[_553]]
// CHECK:  [[_530]] = OpLabel
// CHECK:  [[_531:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_429]]
// CHECK:  [[_532:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_531]] [[_uint_1]]
// CHECK:  [[_533:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_532]] [[_uint_2147483648]]
// CHECK:  [[_534:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_533]] [[_uint_0]]
// CHECK:  [[_535:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_534]]
// CHECK:  OpSelectionMerge [[_542:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_535]] [[_536:%[0-9a-zA-Z_]+]] [[_542]]
// CHECK:  [[_536]] = OpLabel
// CHECK:  [[_537:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_1]] [[_430]]
// CHECK:  [[_538:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_537]] [[_uint_1]]
// CHECK:  [[_539:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_538]] [[_uint_2147483648]]
// CHECK:  [[_540:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_539]] [[_uint_0]]
// CHECK:  [[_541:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_540]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_542]]
// CHECK:  [[_542]] = OpLabel
// CHECK:  [[_544:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_536]] [[_true]] [[_530]]
// CHECK:  [[_543:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_541]] [[_536]] [[_36]] [[_530]]
// CHECK:  OpSelectionMerge [[_545:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_544]] [[_547:%[0-9a-zA-Z_]+]] [[_545]]
// CHECK:  [[_545]] = OpLabel
// CHECK:  [[_546:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_552:%[0-9a-zA-Z_]+]] [[_547]] [[_543]] [[_542]]
// CHECK:  OpBranch [[_553]]
// CHECK:  [[_547]] = OpLabel
// CHECK:  [[_548:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4294967294]] [[_430]]
// CHECK:  [[_549:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_548]] [[_uint_1]]
// CHECK:  [[_550:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_549]] [[_uint_2147483648]]
// CHECK:  [[_551:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_550]] [[_uint_0]]
// CHECK:  [[_552]] = OpSelect [[_float]] [[_551]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_545]]
// CHECK:  [[_553]] = OpLabel
// CHECK:  [[_555:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_545]] [[_true]] [[_524]]
// CHECK:  [[_554:%[0-9a-zA-Z_]+]] = OpPhi [[_float]] [[_546]] [[_545]] [[_504]] [[_524]]
// CHECK:  OpSelectionMerge [[_556]] None
// CHECK:  OpBranchConditional [[_555]] [[_560:%[0-9a-zA-Z_]+]] [[_556]]
// CHECK:  [[_556]] = OpLabel
// CHECK:  [[_559]] = OpPhi [[_bool]] [[_577:%[0-9a-zA-Z_]+]] [[_575:%[0-9a-zA-Z_]+]] [[_505]] [[_553]]
// CHECK:  [[_558]] = OpPhi [[_bool]] [[_576:%[0-9a-zA-Z_]+]] [[_575]] [[_false]] [[_553]]
// CHECK:  [[_557]] = OpPhi [[_float]] [[_573:%[0-9a-zA-Z_]+]] [[_575]] [[_554]] [[_553]]
// CHECK:  OpBranch [[_507]]
// CHECK:  [[_560]] = OpLabel
// CHECK:  [[_561:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_1]] [[_429]]
// CHECK:  [[_562:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_561]] [[_uint_1]]
// CHECK:  [[_563:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_562]] [[_uint_2147483648]]
// CHECK:  [[_564:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_563]] [[_uint_0]]
// CHECK:  [[_565:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_564]]
// CHECK:  OpSelectionMerge [[_572:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_565]] [[_566:%[0-9a-zA-Z_]+]] [[_572]]
// CHECK:  [[_566]] = OpLabel
// CHECK:  [[_567:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_3]] [[_430]]
// CHECK:  [[_568:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_567]] [[_uint_1]]
// CHECK:  [[_569:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_568]] [[_uint_2147483648]]
// CHECK:  [[_570:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_569]] [[_uint_0]]
// CHECK:  [[_571:%[0-9a-zA-Z_]+]] = OpSelect [[_float]] [[_570]] [[_float_1]] [[_float_n1]]
// CHECK:  OpBranch [[_572]]
// CHECK:  [[_572]] = OpLabel
// CHECK:  [[_574:%[0-9a-zA-Z_]+]] = OpPhi [[_bool]] [[_false]] [[_566]] [[_true]] [[_560]]
// CHECK:  [[_573]] = OpPhi [[_float]] [[_571]] [[_566]] [[_554]] [[_560]]
// CHECK:  OpSelectionMerge [[_575]] None
// CHECK:  OpBranchConditional [[_574]] [[_578:%[0-9a-zA-Z_]+]] [[_575]]
// CHECK:  [[_575]] = OpLabel
// CHECK:  [[_577]] = OpPhi [[_bool]] [[_580:%[0-9a-zA-Z_]+]] [[_578]] [[_505]] [[_572]]
// CHECK:  [[_576]] = OpPhi [[_bool]] [[_true]] [[_578]] [[_false]] [[_572]]
// CHECK:  OpBranch [[_556]]
// CHECK:  [[_578]] = OpLabel
// CHECK:  [[_579:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_429]] [[_uint_0]]
// CHECK:  [[_580]] = OpLogicalNot [[_bool]] [[_579]]
// CHECK:  OpBranch [[_575]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_581]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_582:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_583:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_584:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_583]]
// CHECK:  [[_585:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_586:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_585]]
// CHECK:  [[_587:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_588:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_587]]
// CHECK:  [[_589:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_590:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_589]]
// CHECK:  [[_591:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_592:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_591]]
// CHECK:  [[_593:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_590]] [[_588]]
// CHECK:  [[_594:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2uint]] [[_593]] [[_44]] 0
// CHECK:  [[_595:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2uint]] [[_594]] [[_44]] 0 0
// CHECK:  [[_596:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_592]] [[_584]]
// CHECK:  [[_597:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_596]] [[_590]]
// CHECK:  [[_598:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_2]] [[_592]]
// CHECK:  [[_599:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_598]] [[_uint_1]]
// CHECK:  [[_600:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_599]] [[_uint_2147483648]]
// CHECK:  [[_601:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_600]] [[_uint_0]]
// CHECK:  [[_602:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_601]]
// CHECK:  OpSelectionMerge [[_603:%[0-9a-zA-Z_]+]] None
// CHECK:  OpBranchConditional [[_602]] [[_616:%[0-9a-zA-Z_]+]] [[_603]]
// CHECK:  [[_603]] = OpLabel
// CHECK:  [[_604:%[0-9a-zA-Z_]+]] = OpPhi [[_v2uint]] [[_45]] [[_582]] [[_638:%[0-9a-zA-Z_]+]] [[_637:%[0-9a-zA-Z_]+]]
// CHECK:  [[_605:%[0-9a-zA-Z_]+]] = OpISub [[_v2uint]] [[_595]] [[_604]]
// CHECK:  [[_606:%[0-9a-zA-Z_]+]] = OpISub [[_v2uint]] [[_605]] [[_46]]
// CHECK:  [[_607:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v2uint]] [[_606]] [[_47]]
// CHECK:  [[_608:%[0-9a-zA-Z_]+]] = OpIEqual [[_v2bool]] [[_607]] [[_48]]
// CHECK:  [[_609:%[0-9a-zA-Z_]+]] = OpSelect [[_v2uint]] [[_608]] [[_50]] [[_52]]
// CHECK:  [[_610:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_592]] [[_uint_1]]
// CHECK:  [[_611:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_610]] [[_uint_0]]
// CHECK:  [[_612:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_609]] 1
// CHECK:  [[_613:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_609]] 0
// CHECK:  [[_614:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_611]] [[_613]] [[_612]]
// CHECK:  [[_615:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_77]] [[_uint_0]] [[_597]]
// CHECK:  OpStore [[_615]] [[_614]]
// CHECK:  OpReturn
// CHECK:  [[_616]] = OpLabel
// CHECK:  [[_617:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4]] [[_592]]
// CHECK:  [[_618:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_617]] [[_uint_1]]
// CHECK:  [[_619:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_618]] [[_uint_2147483648]]
// CHECK:  [[_620:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_619]] [[_uint_0]]
// CHECK:  [[_621:%[0-9a-zA-Z_]+]] = OpLogicalNot [[_bool]] [[_620]]
// CHECK:  OpSelectionMerge [[_637]] None
// CHECK:  OpBranchConditional [[_621]] [[_622:%[0-9a-zA-Z_]+]] [[_637]]
// CHECK:  [[_622]] = OpLabel
// CHECK:  [[_623:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_6]] [[_592]]
// CHECK:  [[_624:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_623]] [[_uint_1]]
// CHECK:  [[_625:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_624]] [[_uint_2147483648]]
// CHECK:  [[_626:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_625]] [[_uint_0]]
// CHECK:  [[_627:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_8]] [[_592]]
// CHECK:  [[_628:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_627]] [[_uint_1]]
// CHECK:  [[_629:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_628]] [[_uint_2147483648]]
// CHECK:  [[_630:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_629]] [[_uint_0]]
// CHECK:  [[_631:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2bool]] [[_630]] [[_54]] 0
// CHECK:  [[_632:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2bool]] [[_631]] [[_54]] 0 0
// CHECK:  [[_633:%[0-9a-zA-Z_]+]] = OpSelect [[_v2uint]] [[_632]] [[_55]] [[_48]]
// CHECK:  [[_634:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2bool]] [[_626]] [[_54]] 0
// CHECK:  [[_635:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2bool]] [[_634]] [[_54]] 0 0
// CHECK:  [[_636:%[0-9a-zA-Z_]+]] = OpSelect [[_v2uint]] [[_635]] [[_56]] [[_633]]
// CHECK:  OpBranch [[_637]]
// CHECK:  [[_637]] = OpLabel
// CHECK:  [[_638]] = OpPhi [[_v2uint]] [[_636]] [[_622]] [[_57]] [[_616]]
// CHECK:  OpBranch [[_603]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_639]] = OpFunction [[_void]] None [[_12]]
// CHECK:  [[_640:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_641:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_74]] [[_uint_0]]
// CHECK:  [[_642:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_641]]
// CHECK:  [[_643:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_75]] [[_uint_0]]
// CHECK:  [[_644:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_643]]
// CHECK:  [[_645:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_76]] [[_uint_0]]
// CHECK:  [[_646:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_645]]
// CHECK:  [[_647:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:  [[_648:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_647]]
// CHECK:  [[_649:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_1]]
// CHECK:  [[_650:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_649]]
// CHECK:  [[_651:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_648]] [[_646]]
// CHECK:  [[_652:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v4uint]] [[_651]] [[_58]] 0
// CHECK:  [[_653:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4uint]] [[_652]] [[_58]] 0 0 0 0
// CHECK:  [[_654:%[0-9a-zA-Z_]+]] = OpIMul [[_uint]] [[_650]] [[_642]]
// CHECK:  [[_655:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_654]] [[_648]]
// CHECK:  [[_656:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_uint_4]] [[_650]]
// CHECK:  [[_657:%[0-9a-zA-Z_]+]] = OpISub [[_uint]] [[_656]] [[_uint_1]]
// CHECK:  [[_658:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_657]] [[_uint_2147483648]]
// CHECK:  [[_659:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_658]] [[_uint_0]]
// CHECK:  [[_660:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v4bool]] [[_659]] [[_59]] 0
// CHECK:  [[_661:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4bool]] [[_660]] [[_59]] 0 0 0 0
// CHECK:  [[_662:%[0-9a-zA-Z_]+]] = OpSelect [[_v4uint]] [[_661]] [[_60]] [[_61]]
// CHECK:  [[_663:%[0-9a-zA-Z_]+]] = OpISub [[_v4uint]] [[_653]] [[_662]]
// CHECK:  [[_664:%[0-9a-zA-Z_]+]] = OpISub [[_v4uint]] [[_663]] [[_62]]
// CHECK:  [[_665:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_v4uint]] [[_664]] [[_63]]
// CHECK:  [[_666:%[0-9a-zA-Z_]+]] = OpIEqual [[_v4bool]] [[_665]] [[_64]]
// CHECK:  [[_667:%[0-9a-zA-Z_]+]] = OpSelect [[_v4uint]] [[_666]] [[_65]] [[_66]]
// CHECK:  [[_668:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_650]] [[_uint_2]]
// CHECK:  [[_669:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_668]] [[_uint_0]]
// CHECK:  [[_670:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2uint]] [[_667]] [[_58]] 2 3
// CHECK:  [[_671:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2uint]] [[_667]] [[_58]] 0 1
// CHECK:  [[_672:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2bool]] [[_669]] [[_54]] 0
// CHECK:  [[_673:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2bool]] [[_672]] [[_54]] 0 0
// CHECK:  [[_674:%[0-9a-zA-Z_]+]] = OpSelect [[_v2uint]] [[_673]] [[_671]] [[_670]]
// CHECK:  [[_675:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_650]] [[_uint_1]]
// CHECK:  [[_676:%[0-9a-zA-Z_]+]] = OpIEqual [[_bool]] [[_675]] [[_uint_0]]
// CHECK:  [[_677:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_674]] 1
// CHECK:  [[_678:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_674]] 0
// CHECK:  [[_679:%[0-9a-zA-Z_]+]] = OpSelect [[_uint]] [[_676]] [[_678]] [[_677]]
// CHECK:  [[_680:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_77]] [[_uint_0]] [[_655]]
// CHECK:  OpStore [[_680]] [[_679]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
