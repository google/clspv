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
// CHECK-DAG: %[[uint_4294967295:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4294967295
// CHECK-DAG: %[[uint_3:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 3
// CHECK-DAG: %[[float_1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] 1
// CHECK-DAG: %[[float_n1:[0-9a-zA-Z_]+]] = OpConstant %[[float]] -1
// CHECK-DAG: %[[__original_id_25:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_26:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_27:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]] %[[__original_id_25]] %[[__original_id_26]] %[[__original_id_27]]
// CHECK:     %[[__original_id_33:[0-9]+]] = OpFunction %[[void]] None %[[__original_id_9]]
// CHECK:     %[[__original_id_34:[0-9]+]] = OpLabel
// CHECK:     %[[__original_id_43:[0-9]+]] = OpISub %[[uint]] %[[__original_id_36:[0-9]+]] %[[__original_id_40:[0-9]+]]
// CHECK:     %[[__original_id_44:[0-9]+]] = OpISub %[[uint]] %[[__original_id_43]] %[[uint_1]]
// CHECK:     %[[__original_id_45:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_44]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_46:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_45]] %[[uint_0]]
// CHECK:     %[[__original_id_47:[0-9]+]] = OpISub %[[uint]] %[[__original_id_36]] %[[__original_id_42:[0-9]+]]
// CHECK:     %[[__original_id_48:[0-9]+]] = OpISub %[[uint]] %[[__original_id_47]] %[[uint_1]]
// CHECK:     %[[__original_id_49:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_48]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_50:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_49]] %[[uint_0]]
// CHECK:     %[[__original_id_51:[0-9]+]] = OpLogicalAnd %[[bool]] %[[__original_id_46]] %[[__original_id_50]]
// CHECK:     OpSelectionMerge %[[__original_id_65:[0-9]+]] None
// CHECK:     OpBranchConditional %[[__original_id_51]] %[[__original_id_52:[0-9]+]] %[[__original_id_65]]
// CHECK:     %[[__original_id_52]] = OpLabel
// CHECK:     %[[__original_id_53:[0-9]+]] = OpIMul %[[uint]] %[[__original_id_42]] %[[__original_id_36]]
// CHECK:     %[[__original_id_54:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_53]] %[[__original_id_40]]
// CHECK:     %[[__original_id_55:[0-9]+]] = OpBitwiseXor %[[uint]] %[[__original_id_42]] %[[uint_4294967295]]
// CHECK:     %[[__original_id_56:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_38:[0-9]+]] %[[__original_id_55]]
// CHECK:     %[[__original_id_57:[0-9]+]] = OpISub %[[uint]] %[[uint_3]] %[[__original_id_38]]
// CHECK:     %[[__original_id_58:[0-9]+]] = OpIAdd %[[uint]] %[[__original_id_57]] %[[__original_id_40]]
// CHECK:     %[[__original_id_59:[0-9]+]] = OpISub %[[uint]] %[[__original_id_56]] %[[__original_id_58]]
// CHECK:     %[[__original_id_60:[0-9]+]] = OpISub %[[uint]] %[[__original_id_59]] %[[uint_1]]
// CHECK:     %[[__original_id_61:[0-9]+]] = OpBitwiseAnd %[[uint]] %[[__original_id_60]] %[[uint_2147483648]]
// CHECK:     %[[__original_id_62:[0-9]+]] = OpIEqual %[[bool]] %[[__original_id_61]] %[[uint_0]]
// CHECK:     %[[__original_id_63:[0-9]+]] = OpSelect %[[float]] %[[__original_id_62]] %[[float_1]] %[[float_n1]]
// CHECK:     OpBranch %[[__original_id_65]]
// CHECK:     %[[__original_id_65]] = OpLabel
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd

// Test the -hack-scf option.

kernel void lessthan(__global float* outDest, int inWidth, int offset) {
  int x = (int)get_global_id(0);
  int y = (int)get_global_id(1);
  int x_cmp = x - offset + 3;
  int y_cmp = offset - 1 - y;

  int index = (y * inWidth) + x;

  if (x < inWidth && y < inWidth) {
    outDest[index] = (x_cmp < y_cmp) ? 1.0f : -1.0f;
  }
}

