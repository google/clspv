// RUN: clspv --hack-scf %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[_struct_3:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_float:[0-9a-zA-Z_]+]]
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_struct_6:[0-9a-zA-Z_]+]] = OpTypeStruct %[[uint]]
// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[__original_id_9:[0-9]+]] = OpTypeFunction %[[void]]
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_4:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[uint_6:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 6
// CHECK-DAG: %[[uint_7:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 7
// CHECK-DAG: %[[uint_4294967293:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967293
// CHECK-DAG: %[[float_1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 1
// CHECK-DAG: %[[float_n1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] -1
// CHECK-DAG: %[[__original_id_26:[0-9]+]] = OpUndef %[[float]]
// CHECK-DAG: %[[false:[0-9a-zA-Z_]+]] = OpConstantFalse %[[bool]]
// CHECK-DAG: %[[true:[0-9a-zA-Z_]+]] = OpConstantTrue %[[bool]]
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[uint_5:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 5
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[float_0:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 0
// CHECK-DAG: %[[uint_4294967292:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967292
// CHECK-DAG: %[[uint_3:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3
// CHECK-DAG: %[[uint_4294967294:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967294
// CHECK-DAG: %[[__original_id_37:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_38:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_39:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_37]] %[[__original_id_38]] %[[__original_id_39]]
// CHECK:     %[[__original_id_45:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_9]]
// CHECK:     %[[__original_id_46:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_55:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_52:[0-9]+]] %[[__original_id_50:[0-9]+]]
// CHECK:     %[[__original_id_56:[0-9]+]] = OpIMul %[[uint]] %[[__original_id_54:[0-9]+]] %[[__original_id_48:[0-9]+]]
// CHECK:     %[[__original_id_57:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_56]] %[[__original_id_52]]
// CHECK:     OpBranch %[[__original_id_58:[0-9]+]]
// CHECK:     %[[__original_id_58]] = OpLabel
// CHECK:     %[[__original_id_59:[0-9]+]] = OpISub %[[uint]] %[[uint_4]] %[[__original_id_54]]
// CHECK:     %[[__original_id_60:[0-9]+]] = OpISub %[[uint]] %[[__original_id_59]] %[[uint_1]]
// CHECK:     %[[__original_id_61:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_60]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_62:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_61]] %[[uint_0]]
// CHECK:     %[[__original_id_63:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_62]]
// CHECK:     OpSelectionMerge %[[__original_id_128:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_63]] %[[__original_id_64:[0-9]+]] %[[__original_id_128]]
// CHECK:     %[[__original_id_64]] = OpLabel
// CHECK:     %[[__original_id_65:[0-9]+]] = OpISub %[[uint]] %[[uint_6]] %[[__original_id_54]]
// CHECK:     %[[__original_id_66:[0-9]+]] = OpISub %[[uint]] %[[__original_id_65]] %[[uint_1]]
// CHECK:     %[[__original_id_67:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_66]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_68:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_67]] %[[uint_0]]
// CHECK:     %[[__original_id_69:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_68]]
// CHECK:     OpSelectionMerge %[[__original_id_99:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_69]] %[[__original_id_70:[0-9]+]] %[[__original_id_99]]
// CHECK:     %[[__original_id_70]] = OpLabel
// CHECK:     %[[__original_id_71:[0-9]+]] = OpISub %[[uint]] %[[uint_7]] %[[__original_id_54]]
// CHECK:     %[[__original_id_72:[0-9]+]] = OpISub %[[uint]] %[[__original_id_71]] %[[uint_1]]
// CHECK:     %[[__original_id_73:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_72]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_74:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_73]] %[[uint_0]]
// CHECK:     %[[__original_id_75:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_74]]
// CHECK:     OpSelectionMerge %[[__original_id_87:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_75]] %[[__original_id_76:[0-9]+]] %[[__original_id_87]]
// CHECK:     %[[__original_id_76]] = OpLabel
// CHECK:     %[[__original_id_77:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_54]] %[[uint_7]]
// CHECK:     OpSelectionMerge %[[__original_id_84:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_77]] %[[__original_id_78:[0-9]+]] %[[__original_id_84]]
// CHECK:     %[[__original_id_78]] = OpLabel
// CHECK:     %[[__original_id_79:[0-9]+]] = OpISub %[[uint]] %[[uint_4294967293]] %[[__original_id_55]]
// CHECK:     %[[__original_id_80:[0-9]+]] = OpISub %[[uint]] %[[__original_id_79]] %[[uint_1]]
// CHECK:     %[[__original_id_81:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_80]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_82:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_81]] %[[uint_0]]
// CHECK:     %[[__original_id_83:[0-9]+]] = OpSelect %[[float]] %[[__original_id_82]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_84]]
// CHECK:     %[[__original_id_84]] = OpLabel
// CHECK:     %[[__original_id_86:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_78]] %[[true]] %[[__original_id_76]]
// CHECK:     %[[__original_id_85:[0-9]+]] = OpPhi %[[float]] %[[__original_id_83]] %[[__original_id_78]] %[[__original_id_26]] %[[__original_id_76]]
// CHECK:     OpBranch %[[__original_id_87]]
// CHECK:     %[[__original_id_87]] = OpLabel
// CHECK:     %[[__original_id_90:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_84]] %[[true]] %[[__original_id_70]]
// CHECK:     %[[__original_id_89:[0-9]+]] = OpPhi %[[bool]] %[[__original_id_86]] %[[__original_id_84]] %[[false]] %[[__original_id_70]]
// CHECK:     %[[__original_id_88:[0-9]+]] = OpPhi %[[float]] %[[__original_id_85]] %[[__original_id_84]] %[[__original_id_26]] %[[__original_id_70]]
// CHECK:     OpSelectionMerge %[[__original_id_91:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_90]] %[[__original_id_93:[0-9]+]] %[[__original_id_91]]
// CHECK:     %[[__original_id_91]] = OpLabel
// CHECK:     %[[__original_id_92:[0-9]+]] = OpPhi %[[float]] %[[__original_id_98:[0-9]+]] %[[__original_id_93]] %[[__original_id_88]] %[[__original_id_87]]
// CHECK:     OpBranch %[[__original_id_99]]
// CHECK:     %[[__original_id_93]] = OpLabel
// CHECK:     %[[__original_id_94:[0-9]+]] = OpISub %[[uint]] %[[uint_2]] %[[__original_id_55]]
// CHECK:     %[[__original_id_95:[0-9]+]] = OpISub %[[uint]] %[[__original_id_94]] %[[uint_1]]
// CHECK:     %[[__original_id_96:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_95]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_97:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_96]] %[[uint_0]]
// CHECK:     %[[__original_id_98]] = OpSelect %[[float]] %[[__original_id_97]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_91]]
// CHECK:     %[[__original_id_99]] = OpLabel
// CHECK:     %[[__original_id_102:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_91]] %[[true]] %[[__original_id_64]]
// CHECK:     %[[__original_id_101:[0-9]+]] = OpPhi %[[bool]] %[[__original_id_89]] %[[__original_id_91]] %[[false]] %[[__original_id_64]]
// CHECK:     %[[__original_id_100:[0-9]+]] = OpPhi %[[float]] %[[__original_id_92]] %[[__original_id_91]] %[[__original_id_26]] %[[__original_id_64]]
// CHECK:     OpSelectionMerge %[[__original_id_103:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_102]] %[[__original_id_105:[0-9]+]] %[[__original_id_103]]
// CHECK:     %[[__original_id_103]] = OpLabel
// CHECK:     %[[__original_id_104:[0-9]+]] = OpPhi %[[float]] %[[__original_id_121:[0-9]+]] %[[__original_id_120:[0-9]+]] %[[__original_id_100]] %[[__original_id_99]]
// CHECK:     OpBranch %[[__original_id_128]]
// CHECK:     %[[__original_id_105]] = OpLabel
// CHECK:     %[[__original_id_106:[0-9]+]] = OpISub %[[uint]] %[[uint_5]] %[[__original_id_54]]
// CHECK:     %[[__original_id_107:[0-9]+]] = OpISub %[[uint]] %[[__original_id_106]] %[[uint_1]]
// CHECK:     %[[__original_id_108:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_107]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_109:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_108]] %[[uint_0]]
// CHECK:     %[[__original_id_110:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_109]]
// CHECK:     OpSelectionMerge %[[__original_id_117:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_110]] %[[__original_id_111:[0-9]+]] %[[__original_id_117]]
// CHECK:     %[[__original_id_111]] = OpLabel
// CHECK:     %[[__original_id_112:[0-9]+]] = OpISub %[[uint]] %[[uint_4294967295]] %[[__original_id_55]]
// CHECK:     %[[__original_id_113:[0-9]+]] = OpISub %[[uint]] %[[__original_id_112]] %[[uint_1]]
// CHECK:     %[[__original_id_114:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_113]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_115:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_114]] %[[uint_0]]
// CHECK:     %[[__original_id_116:[0-9]+]] = OpSelect %[[float]] %[[__original_id_115]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_117]]
// CHECK:     %[[__original_id_117]] = OpLabel
// CHECK:     %[[__original_id_119:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_111]] %[[true]] %[[__original_id_105]]
// CHECK:     %[[__original_id_118:[0-9]+]] = OpPhi %[[float]] %[[__original_id_116]] %[[__original_id_111]] %[[__original_id_26]] %[[__original_id_105]]
// CHECK:     OpSelectionMerge %[[__original_id_120]] None
// CHECK:     OpBranchConditional %[[__original_id_119]] %[[__original_id_122:[0-9]+]] %[[__original_id_120]]
// CHECK:     %[[__original_id_120]] = OpLabel
// CHECK:     %[[__original_id_121]] = OpPhi %[[float]] %[[__original_id_127:[0-9]+]] %[[__original_id_122]] %[[__original_id_118]] %[[__original_id_117]]
// CHECK:     OpBranch %[[__original_id_103]]
// CHECK:     %[[__original_id_122]] = OpLabel
// CHECK:     %[[__original_id_123:[0-9]+]] = OpISub %[[uint]] %[[uint_0]] %[[__original_id_55]]
// CHECK:     %[[__original_id_124:[0-9]+]] = OpISub %[[uint]] %[[__original_id_123]] %[[uint_1]]
// CHECK:     %[[__original_id_125:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_124]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_126:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_125]] %[[uint_0]]
// CHECK:     %[[__original_id_127]] = OpSelect %[[float]] %[[__original_id_126]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_120]]
// CHECK:     %[[__original_id_128]] = OpLabel
// CHECK:     %[[__original_id_131:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_103]] %[[true]] %[[__original_id_58]]
// CHECK:     %[[__original_id_130:[0-9]+]] = OpPhi %[[bool]] %[[__original_id_101]] %[[__original_id_103]] %[[false]] %[[__original_id_58]]
// CHECK:     %[[__original_id_129:[0-9]+]] = OpPhi %[[float]] %[[__original_id_104]] %[[__original_id_103]] %[[__original_id_26]] %[[__original_id_58]]
// CHECK:     OpSelectionMerge %[[__original_id_132:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_131]] %[[__original_id_149:[0-9]+]] %[[__original_id_132]]
// CHECK:     %[[__original_id_132]] = OpLabel
// CHECK:     %[[__original_id_135:[0-9]+]] = OpPhi %[[bool]] %[[__original_id_184:[0-9]+]] %[[__original_id_181:[0-9]+]] %[[__original_id_130]] %[[__original_id_128]]
// CHECK:     %[[__original_id_134:[0-9]+]] = OpPhi %[[bool]] %[[__original_id_183:[0-9]+]] %[[__original_id_181]] %[[false]] %[[__original_id_128]]
// CHECK:     %[[__original_id_133:[0-9]+]] = OpPhi %[[float]] %[[__original_id_182:[0-9]+]] %[[__original_id_181]] %[[__original_id_129]] %[[__original_id_128]]
// CHECK:     OpSelectionMerge %[[__original_id_136:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_135]] %[[__original_id_148:[0-9]+]] %[[__original_id_136]]
// CHECK:     %[[__original_id_136]] = OpLabel
// CHECK:     %[[__original_id_138:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_148]] %[[__original_id_134]] %[[__original_id_132]]
// CHECK:     %[[__original_id_137:[0-9]+]] = OpPhi %[[float]] %[[float_0]] %[[__original_id_148]] %[[__original_id_133]] %[[__original_id_132]]
// CHECK:     OpSelectionMerge %[[__original_id_139:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_138]] %[[__original_id_142:[0-9]+]] %[[__original_id_139]]
// CHECK:     %[[__original_id_139]] = OpLabel
// CHECK:     %[[__original_id_140:[0-9]+]] = OpPhi %[[float]] %[[__original_id_137]] %[[__original_id_136]] %[[__original_id_147:[0-9]+]] %[[__original_id_142]]
// CHECK:     OpReturn
// CHECK:     %[[__original_id_142]] = OpLabel
// CHECK:     %[[__original_id_143:[0-9]+]] = OpISub %[[uint]] %[[uint_4294967292]] %[[__original_id_55]]
// CHECK:     %[[__original_id_144:[0-9]+]] = OpISub %[[uint]] %[[__original_id_143]] %[[uint_1]]
// CHECK:     %[[__original_id_145:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_144]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_146:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_145]] %[[uint_0]]
// CHECK:     %[[__original_id_147]] = OpSelect %[[float]] %[[__original_id_146]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_139]]
// CHECK:     %[[__original_id_148]] = OpLabel
// CHECK:     OpBranch %[[__original_id_136]]
// CHECK:     %[[__original_id_149]] = OpLabel
// CHECK:     %[[__original_id_150:[0-9]+]] = OpISub %[[uint]] %[[uint_2]] %[[__original_id_54]]
// CHECK:     %[[__original_id_151:[0-9]+]] = OpISub %[[uint]] %[[__original_id_150]] %[[uint_1]]
// CHECK:     %[[__original_id_152:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_151]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_153:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_152]] %[[uint_0]]
// CHECK:     %[[__original_id_154:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_153]]
// CHECK:     OpSelectionMerge %[[__original_id_178:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_154]] %[[__original_id_155:[0-9]+]] %[[__original_id_178]]
// CHECK:     %[[__original_id_155]] = OpLabel
// CHECK:     %[[__original_id_156:[0-9]+]] = OpISub %[[uint]] %[[uint_3]] %[[__original_id_54]]
// CHECK:     %[[__original_id_157:[0-9]+]] = OpISub %[[uint]] %[[__original_id_156]] %[[uint_1]]
// CHECK:     %[[__original_id_158:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_157]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_159:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_158]] %[[uint_0]]
// CHECK:     %[[__original_id_160:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_159]]
// CHECK:     OpSelectionMerge %[[__original_id_167:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_160]] %[[__original_id_161:[0-9]+]] %[[__original_id_167]]
// CHECK:     %[[__original_id_161]] = OpLabel
// CHECK:     %[[__original_id_162:[0-9]+]] = OpISub %[[uint]] %[[uint_1]] %[[__original_id_55]]
// CHECK:     %[[__original_id_163:[0-9]+]] = OpISub %[[uint]] %[[__original_id_162]] %[[uint_1]]
// CHECK:     %[[__original_id_164:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_163]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_165:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_164]] %[[uint_0]]
// CHECK:     %[[__original_id_166:[0-9]+]] = OpSelect %[[float]] %[[__original_id_165]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_167]]
// CHECK:     %[[__original_id_167]] = OpLabel
// CHECK:     %[[__original_id_169:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_161]] %[[true]] %[[__original_id_155]]
// CHECK:     %[[__original_id_168:[0-9]+]] = OpPhi %[[float]] %[[__original_id_166]] %[[__original_id_161]] %[[__original_id_26]] %[[__original_id_155]]
// CHECK:     OpSelectionMerge %[[__original_id_170:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_169]] %[[__original_id_172:[0-9]+]] %[[__original_id_170]]
// CHECK:     %[[__original_id_170]] = OpLabel
// CHECK:     %[[__original_id_171:[0-9]+]] = OpPhi %[[float]] %[[__original_id_177:[0-9]+]] %[[__original_id_172]] %[[__original_id_168]] %[[__original_id_167]]
// CHECK:     OpBranch %[[__original_id_178]]
// CHECK:     %[[__original_id_172]] = OpLabel
// CHECK:     %[[__original_id_173:[0-9]+]] = OpISub %[[uint]] %[[uint_4294967294]] %[[__original_id_55]]
// CHECK:     %[[__original_id_174:[0-9]+]] = OpISub %[[uint]] %[[__original_id_173]] %[[uint_1]]
// CHECK:     %[[__original_id_175:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_174]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_176:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_175]] %[[uint_0]]
// CHECK:     %[[__original_id_177]] = OpSelect %[[float]] %[[__original_id_176]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_170]]
// CHECK:     %[[__original_id_178]] = OpLabel
// CHECK:     %[[__original_id_180:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_170]] %[[true]] %[[__original_id_149]]
// CHECK:     %[[__original_id_179:[0-9]+]] = OpPhi %[[float]] %[[__original_id_171]] %[[__original_id_170]] %[[__original_id_129]] %[[__original_id_149]]
// CHECK:     OpSelectionMerge %[[__original_id_181]] None
// CHECK:     OpBranchConditional %[[__original_id_180]] %[[__original_id_185:[0-9]+]] %[[__original_id_181]]
// CHECK:     %[[__original_id_181]] = OpLabel
// CHECK:     %[[__original_id_184]] = OpPhi %[[bool]] %[[__original_id_202:[0-9]+]] %[[__original_id_200:[0-9]+]] %[[__original_id_130]] %[[__original_id_178]]
// CHECK:     %[[__original_id_183]] = OpPhi %[[bool]] %[[__original_id_201:[0-9]+]] %[[__original_id_200]] %[[false]] %[[__original_id_178]]
// CHECK:     %[[__original_id_182]] = OpPhi %[[float]] %[[__original_id_198:[0-9]+]] %[[__original_id_200]] %[[__original_id_179]] %[[__original_id_178]]
// CHECK:     OpBranch %[[__original_id_132]]
// CHECK:     %[[__original_id_185]] = OpLabel
// CHECK:     %[[__original_id_186:[0-9]+]] = OpISub %[[uint]] %[[uint_1]] %[[__original_id_54]]
// CHECK:     %[[__original_id_187:[0-9]+]] = OpISub %[[uint]] %[[__original_id_186]] %[[uint_1]]
// CHECK:     %[[__original_id_188:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_187]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_189:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_188]] %[[uint_0]]
// CHECK:     %[[__original_id_190:[0-9]+]] = OpLogicalNot %[[bool]] %[[__original_id_189]]
// CHECK:     OpSelectionMerge %[[__original_id_197:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_190]] %[[__original_id_191:[0-9]+]] %[[__original_id_197]]
// CHECK:     %[[__original_id_191]] = OpLabel
// CHECK:     %[[__original_id_192:[0-9]+]] = OpISub %[[uint]] %[[uint_3]] %[[__original_id_55]]
// CHECK:     %[[__original_id_193:[0-9]+]] = OpISub %[[uint]] %[[__original_id_192]] %[[uint_1]]
// CHECK:     %[[__original_id_194:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_193]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_195:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_194]] %[[uint_0]]
// CHECK:     %[[__original_id_196:[0-9]+]] = OpSelect %[[float]] %[[__original_id_195]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_197]]
// CHECK:     %[[__original_id_197]] = OpLabel
// CHECK:     %[[__original_id_199:[0-9]+]] = OpPhi %[[bool]] %[[false]] %[[__original_id_191]] %[[true]] %[[__original_id_185]]
// CHECK:     %[[__original_id_198]] = OpPhi %[[float]] %[[__original_id_196]] %[[__original_id_191]] %[[__original_id_179]] %[[__original_id_185]]
// CHECK:     OpSelectionMerge %[[__original_id_200]] None
// CHECK:     OpBranchConditional %[[__original_id_199]] %[[__original_id_203:[0-9]+]] %[[__original_id_200]]
// CHECK:     %[[__original_id_200]] = OpLabel
// CHECK:     %[[__original_id_202]] = OpPhi %[[bool]] %[[__original_id_205:[0-9]+]] %[[__original_id_203]] %[[__original_id_130]] %[[__original_id_197]]
// CHECK:     %[[__original_id_201]] = OpPhi %[[bool]] %[[true]] %[[__original_id_203]] %[[false]] %[[__original_id_197]]
// CHECK:     OpBranch %[[__original_id_181]]
// CHECK:     %[[__original_id_203]] = OpLabel
// CHECK:     %[[__original_id_204:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_54]] %[[uint_0]]
// CHECK:     %[[__original_id_205]] = OpLogicalNot %[[bool]] %[[__original_id_204]]
// CHECK:     OpBranch %[[__original_id_200]]
// CHECK:     OpFunctionEnd

// Test the -hack-scf option.

// Note: This gets compiled down to OpSignedLessThan
kernel void greaterthan_const_left(__global float *outDest, int inWidth,
                                   int offset) {
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


