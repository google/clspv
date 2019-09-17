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
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[v2bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 2
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_21:[0-9]+]] = OpUndef %[[v4uint]]
// CHECK-DAG: %[[uint_4:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[__original_id_24:[0-9]+]] = OpUndef %[[v4bool]]
// CHECK-DAG: %[[uint_4294967292:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967292
// CHECK-DAG: %[[uint_3:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3
// CHECK-DAG: %[[uint_4294967294:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967294
// CHECK-DAG: %[[__original_id_28:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_4294967292]] %[[uint_3]] %[[uint_4294967294]] %[[uint_1]]
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[uint_4294967293:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967293
// CHECK-DAG: %[[__original_id_32:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_0]] %[[uint_4294967295]] %[[uint_2]] %[[uint_4294967293]]
// CHECK-DAG: %[[__original_id_33:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_1]] %[[uint_1]] %[[uint_1]] %[[uint_1]]
// CHECK-DAG: %[[__original_id_34:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_2147483648]] %[[uint_2147483648]] %[[uint_2147483648]] %[[uint_2147483648]]
// CHECK-DAG: %[[__original_id_35:[0-9]+]] = OpConstantNull %[[v4uint]]
// CHECK-DAG: %[[uint_1065353216:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1065353216
// CHECK-DAG: %[[__original_id_37:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_1065353216]] %[[uint_1065353216]] %[[uint_1065353216]] %[[uint_1065353216]]
// CHECK-DAG: %[[uint_3212836864:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3212836864
// CHECK-DAG: %[[__original_id_39:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_3212836864]] %[[uint_3212836864]] %[[uint_3212836864]] %[[uint_3212836864]]
// CHECK-DAG: %[[__original_id_40:[0-9]+]] = OpUndef %[[v2bool]]
// CHECK-DAG: %[[__original_id_42:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_43:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_44:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_42]] %[[__original_id_43]] %[[__original_id_44]]
// CHECK:     %[[__original_id_50:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_8]]
// CHECK:     %[[__original_id_51:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_60:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_57:[0-9]+]] %[[__original_id_55:[0-9]+]]
// CHECK:     %[[__original_id_61:[0-9]+]] = OpCompositeInsert %[[v4uint]] %[[__original_id_60]] %[[__original_id_21]] 0
// CHECK:     %[[__original_id_62:[0-9]+]] = OpVectorShuffle %[[v4uint]] %[[__original_id_61]] %[[__original_id_21]] 0 0 0 0
// CHECK:     %[[__original_id_63:[0-9]+]] = OpIMul %[[uint]] %[[__original_id_59:[0-9]+]] %[[__original_id_53:[0-9]+]]
// CHECK:     %[[__original_id_64:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_63]] %[[__original_id_57]]
// CHECK:     %[[__original_id_65:[0-9]+]] = OpISub %[[uint]] %[[uint_4]] %[[__original_id_59]]
// CHECK:     %[[__original_id_66:[0-9]+]] = OpISub %[[uint]] %[[__original_id_65]] %[[uint_1]]
// CHECK:     %[[__original_id_67:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_66]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_68:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_67]] %[[uint_0]]
// CHECK:     %[[__original_id_69:[0-9]+]] = OpCompositeInsert %[[v4bool]] %[[__original_id_68]] %[[__original_id_24]] 0
// CHECK:     %[[__original_id_70:[0-9]+]] = OpVectorShuffle %[[v4bool]] %[[__original_id_69]] %[[__original_id_24]] 0 0 0 0
// CHECK:     %[[__original_id_71:[0-9]+]] = OpSelect %[[v4uint]] %[[__original_id_70]] %[[__original_id_28]] %[[__original_id_32]]
// CHECK:     %[[__original_id_72:[0-9]+]] = OpISub %[[v4uint]] %[[__original_id_62]] %[[__original_id_71]]
// CHECK:     %[[__original_id_73:[0-9]+]] = OpISub %[[v4uint]] %[[__original_id_72]] %[[__original_id_33]]
// CHECK:     %[[__original_id_74:[0-9]+]] = OpBitwiseAnd %[[v4uint]] %[[__original_id_73]] %[[__original_id_34]]
// CHECK:     %[[__original_id_75:[0-9]+]] = OpIEqual %[[v4bool]] %[[__original_id_74]] %[[__original_id_35]]
// CHECK:     %[[__original_id_76:[0-9]+]] = OpSelect %[[v4uint]] %[[__original_id_75]] %[[__original_id_37]] %[[__original_id_39]]
// CHECK:     %[[__original_id_77:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_59]] %[[uint_2]]
// CHECK:     %[[__original_id_78:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_77]] %[[uint_0]]
// CHECK:     %[[__original_id_79:[0-9]+]] = OpVectorShuffle %[[v2uint]] %[[__original_id_76]] %[[__original_id_21]] 2 3
// CHECK:     %[[__original_id_80:[0-9]+]] = OpVectorShuffle %[[v2uint]] %[[__original_id_76]] %[[__original_id_21]] 0 1
// CHECK:     %[[__original_id_81:[0-9]+]] = OpCompositeInsert %[[v2bool]] %[[__original_id_78]] %[[__original_id_40]] 0
// CHECK:     %[[__original_id_82:[0-9]+]] = OpVectorShuffle %[[v2bool]] %[[__original_id_81]] %[[__original_id_40]] 0 0
// CHECK:     %[[__original_id_83:[0-9]+]] = OpSelect %[[v2uint]] %[[__original_id_82]] %[[__original_id_80]] %[[__original_id_79]]
// CHECK:     %[[__original_id_84:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_59]] %[[uint_1]]
// CHECK:     %[[__original_id_85:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_84]] %[[uint_0]]
// CHECK:     %[[__original_id_86:[0-9]+]] = OpCompositeExtract %[[uint]] %[[__original_id_83]] 1
// CHECK:     %[[__original_id_87:[0-9]+]] = OpCompositeExtract %[[uint]] %[[__original_id_83]] 0
// CHECK:     %[[__original_id_88:[0-9]+]] = OpSelect %[[uint]] %[[__original_id_85]] %[[__original_id_87]] %[[__original_id_86]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd

// Test the -hack-scf option.

kernel void greaterthan_const_vec4(__global int *outDest, int inWidth,
                                   int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int xcmp = x + offset;
  int4 x_cmp4 = (int4)(xcmp);

  int index = (y * inWidth) + x;

  const int fake_float_one = (int)0x3f800000u;  // 1.0, same as 0x3F800000
  const int fake_float_mone = (int)0xbf800000u; // -1.0, same as 0xBF800000
  int4 one = (int4)(fake_float_one);
  int4 mone = (int4)(fake_float_mone);

  int4 compare_to = (y < 4) ? (int4)(-4, 3, -2, 1) : (int4)(0, -1, 2, -3);
  int4 value = ((x_cmp4 > compare_to) & one) | ((x_cmp4 <= compare_to) & mone);
  int2 components2 = (y & 2) ? value.zw : value.xy;
  int component = (y & 1) ? components2.y : components2.x;
  outDest[index] = component;
}

