// RUN: clspv --hack-scf %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_3:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_uint:[0-9a-zA-Z_]+]]
// CHECK-DAG: %[[_struct_5:[0-9a-zA-Z_]+]] = OpTypeStruct %[[uint]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_8:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_19:[0-9]+]] = OpUndef %[[v2uint]]
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[uint_4294967292:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967292
// CHECK-DAG: %[[uint_3:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3
// CHECK-DAG: %[[__original_id_24:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_4294967292]] %[[uint_3]]
// CHECK-DAG: %[[__original_id_25:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_1]] %[[uint_1]]
// CHECK-DAG: %[[__original_id_26:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2147483648]] %[[uint_2147483648]]
// CHECK-DAG: %[[__original_id_27:[0-9]+]] = OpConstantNull %[[v2uint]]
// CHECK-DAG: %[[uint_1065353216:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1065353216
// CHECK-DAG: %[[__original_id_29:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_1065353216]] %[[uint_1065353216]]
// CHECK-DAG: %[[uint_3212836864:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3212836864
// CHECK-DAG: %[[__original_id_31:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_3212836864]] %[[uint_3212836864]]
// CHECK-DAG: %[[uint_4:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4
// CHECK-DAG: %[[uint_6:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 6
// CHECK-DAG: %[[uint_8:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 8
// CHECK-DAG: %[[__original_id_35:[0-9]+]] = OpUndef %[[v2bool]]
// CHECK-DAG: %[[uint_4294967293:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967293
// CHECK-DAG: %[[__original_id_37:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2]] %[[uint_4294967293]]
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[__original_id_39:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_0]] %[[uint_4294967295]]
// CHECK-DAG: %[[uint_4294967294:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967294
// CHECK-DAG: %[[__original_id_41:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_4294967294]] %[[uint_1]]
// CHECK-DAG: %[[__original_id_43:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_44:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_45:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_43]] %[[__original_id_44]] %[[__original_id_45]]
// CHECK:     %[[__original_id_51:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_8]]
// CHECK:     %[[__original_id_52:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_61:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_58:[0-9]+]] %[[__original_id_56:[0-9]+]]
// CHECK:     %[[__original_id_62:[0-9]+]] = OpCompositeInsert %[[v2uint]] %[[__original_id_61]] %[[__original_id_19]] 0
// CHECK:     %[[__original_id_63:[0-9]+]] = OpVectorShuffle %[[v2uint]] %[[__original_id_62]] %[[__original_id_19]] 0 0
// CHECK:     %[[__original_id_64:[0-9]+]] = OpIMul %[[uint]] %[[__original_id_60:[0-9]+]] %[[__original_id_54:[0-9]+]]
// CHECK:     %[[__original_id_65:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_64]] %[[__original_id_58]]
// CHECK:     %[[__original_id_66:[0-9]+]] = OpISub %[[uint]] %[[uint_2]] %[[__original_id_60]]
// CHECK:     %[[__original_id_67:[0-9]+]] = OpISub %[[uint]] %[[__original_id_66]] %[[uint_1]]
// CHECK:     %[[__original_id_68:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_67]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_69:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_68]] %[[uint_0]]
// CHECK:     %[[__original_id_70:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_69]]
// CHECK:     OpSelectionMerge %[[__original_id_71:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_70]] %[[__original_id_84:[0-9]+]] %[[__original_id_71]]
// CHECK:     %[[__original_id_71]] = OpLabel
// CHECK:     %[[__original_id_72:[0-9]+]] = OpPhi %[[v2uint]] %[[__original_id_24]] %[[__original_id_52]] %[[__original_id_106:[0-9]+]] %[[__original_id_105:[0-9]+]]
// CHECK:     %[[__original_id_73:[0-9]+]] = OpISub %[[v2uint]] %[[__original_id_63]] %[[__original_id_72]]
// CHECK:     %[[__original_id_74:[0-9]+]] = OpISub %[[v2uint]] %[[__original_id_73]] %[[__original_id_25]]
// CHECK:     %[[__original_id_75:[0-9]+]] = OpBitwiseAnd %[[v2uint]] %[[__original_id_74]] %[[__original_id_26]]
// CHECK:     %[[__original_id_76:[0-9]+]] = OpIEqual %[[v2bool]] %[[__original_id_75]] %[[__original_id_27]]
// CHECK:     %[[__original_id_77:[0-9]+]] = OpSelect %[[v2uint]] %[[__original_id_76]] %[[__original_id_29]] %[[__original_id_31]]
// CHECK:     %[[__original_id_78:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_60]] %[[uint_1]]
// CHECK:     %[[__original_id_79:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_78]] %[[uint_0]]
// CHECK:     %[[__original_id_80:[0-9]+]] = OpCompositeExtract %[[uint]] %[[__original_id_77]] 1
// CHECK:     %[[__original_id_81:[0-9]+]] = OpCompositeExtract %[[uint]] %[[__original_id_77]] 0
// CHECK:     %[[__original_id_82:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_79]] %[[__original_id_81]] %[[__original_id_80]]
// CHECK:     OpReturn
// CHECK:     %[[__original_id_84]] = OpLabel
// CHECK:     %[[__original_id_85:[0-9]+]] = OpISub %[[uint]] %[[uint_4]] %[[__original_id_60]]
// CHECK:     %[[__original_id_86:[0-9]+]] = OpISub %[[uint]] %[[__original_id_85]] %[[uint_1]]
// CHECK:     %[[__original_id_87:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_86]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_88:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_87]] %[[uint_0]]
// CHECK:     %[[__original_id_89:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_88]]
// CHECK:     OpSelectionMerge %[[__original_id_105]] None
// CHECK:     OpBranchConditional %[[__original_id_89]] %[[__original_id_90:[0-9]+]] %[[__original_id_105]]
// CHECK:     %[[__original_id_90]] = OpLabel
// CHECK:     %[[__original_id_91:[0-9]+]] = OpISub %[[uint]] %[[uint_6]] %[[__original_id_60]]
// CHECK:     %[[__original_id_92:[0-9]+]] = OpISub %[[uint]] %[[__original_id_91]] %[[uint_1]]
// CHECK:     %[[__original_id_93:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_92]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_94:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_93]] %[[uint_0]]
// CHECK:     %[[__original_id_95:[0-9]+]] = OpISub %[[uint]] %[[uint_8]] %[[__original_id_60]]
// CHECK:     %[[__original_id_96:[0-9]+]] = OpISub %[[uint]] %[[__original_id_95]] %[[uint_1]]
// CHECK:     %[[__original_id_97:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_96]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_98:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_97]] %[[uint_0]]
// CHECK:     %[[__original_id_99:[0-9]+]] = OpCompositeInsert %[[v2bool]] %[[__original_id_98]] %[[__original_id_35]] 0
// CHECK:     %[[__original_id_100:[0-9]+]] = OpVectorShuffle %[[v2bool]] %[[__original_id_99]] %[[__original_id_35]] 0 0
// CHECK:     %[[__original_id_101:[0-9]+]] = OpSelect %[[v2uint]] %[[__original_id_100]] %[[__original_id_37]] %[[__original_id_27]]
// CHECK:     %[[__original_id_102:[0-9]+]] = OpCompositeInsert %[[v2bool]] %[[__original_id_94]] %[[__original_id_35]] 0
// CHECK:     %[[__original_id_103:[0-9]+]] = OpVectorShuffle %[[v2bool]] %[[__original_id_102]] %[[__original_id_35]] 0 0
// CHECK:     %[[__original_id_104:[0-9]+]] = OpSelect %[[v2uint]] %[[__original_id_103]] %[[__original_id_39]] %[[__original_id_101]]
// CHECK:     OpBranch %[[__original_id_105]]
// CHECK:     %[[__original_id_105]] = OpLabel
// CHECK:     %[[__original_id_106]] = OpPhi %[[v2uint]] %[[__original_id_104]] %[[__original_id_90]] %[[__original_id_41]] %[[__original_id_84]]
// CHECK:     OpBranch %[[__original_id_71]]
// CHECK:     OpFunctionEnd

// Test the -hack-scf option.

kernel void greaterthan_const_vec2(__global int *outDest, int inWidth,
                                   int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int xcmp = x + offset;
  int2 x_cmp2 = (int2)(xcmp, xcmp);

  int index = (y * inWidth) + x;

  const int fake_float_one = (int)0x3f800000u;  // 1.0, same as 0x3F800000
  const int fake_float_mone = (int)0xbf800000u; // -1.0, same as 0xBF800000
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

