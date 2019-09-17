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
// CHECK-DAG: %[[uint_2147483648:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[uint_4294967293:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967293
// CHECK-DAG: %[[float_1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 1
// CHECK-DAG: %[[float_n1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] -1
// CHECK-DAG: %[[__original_id_24:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_25:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_26:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_24]] %[[__original_id_25]] %[[__original_id_26]]
// CHECK:     %[[__original_id_32:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_9]]
// CHECK:     %[[__original_id_33:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_42:[0-9]+]] = OpISub %[[uint]] %[[__original_id_35:[0-9]+]] %[[__original_id_39:[0-9]+]]
// CHECK:     %[[__original_id_43:[0-9]+]] = OpISub %[[uint]] %[[__original_id_42]] %[[uint_1]]
// CHECK:     %[[__original_id_44:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_43]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_45:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_44]] %[[uint_0]]
// CHECK:     %[[__original_id_46:[0-9]+]] = OpISub %[[uint]] %[[__original_id_35]] %[[__original_id_41:[0-9]+]]
// CHECK:     %[[__original_id_47:[0-9]+]] = OpISub %[[uint]] %[[__original_id_46]] %[[uint_1]]
// CHECK:     %[[__original_id_48:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_47]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_49:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_48]] %[[uint_0]]
// CHECK:     %[[__original_id_50:[0-9]+]] = OpLogicalAnd %[[bool]] %[[__original_id_45]] %[[__original_id_49]]
// CHECK:     OpSelectionMerge %[[__original_id_61:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_50]] %[[__original_id_51:[0-9]+]] %[[__original_id_61]]
// CHECK:     %[[__original_id_51]] = OpLabel
// CHECK:     %[[__original_id_52:[0-9]+]] = OpIMul %[[uint]] %[[__original_id_41]] %[[__original_id_35]]
// CHECK:     %[[__original_id_53:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_52]] %[[__original_id_39]]
// CHECK:     %[[__original_id_54:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_39]] %[[__original_id_37:[0-9]+]]
// CHECK:     %[[__original_id_55:[0-9]+]] = OpISub %[[uint]] %[[__original_id_54]] %[[uint_4294967293]]
// CHECK:     %[[__original_id_56:[0-9]+]] = OpISub %[[uint]] %[[__original_id_55]] %[[uint_1]]
// CHECK:     %[[__original_id_57:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_56]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_58:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_57]] %[[uint_0]]
// CHECK:     %[[__original_id_59:[0-9]+]] = OpSelect %[[float]] %[[__original_id_58]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_61]]
// CHECK:     %[[__original_id_61]] = OpLabel
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd

// Test the -hack-scf option.

// RUN: clspv %s -o %t.spv -hack-scf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void greaterthan_m2(__global float *outDest, int inWidth, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x + offset;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp > -3) ? 1.0f : -1.0f;
  }
}

