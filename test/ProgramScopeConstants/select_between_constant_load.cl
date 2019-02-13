// Ensure that instcombine does not convert a selection between
// loads into a selection between the pointer and then loading
// from that pointer.
// https://github.com/google/clspv/issues/71

// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


__constant float kFirst[3] = {1.0f, 2.0f, 3.0f};
__constant float kSecond[3] = {10.0f, 11.0f, 12.0f};

kernel void foo(global float *A, int c, int i) {
  *A = c == 0 ? kFirst[i] : kSecond[i];
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 61
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_41:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_31:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_32:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_33:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4:%[a-zA-Z0-9_]+]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7:%[a-zA-Z0-9_]+]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_38:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_38:%[a-zA-Z0-9_]+]] Binding 0
// CHECK: OpDecorate [[_39:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_39:%[a-zA-Z0-9_]+]] Binding 1
// CHECK: OpDecorate [[_40:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_40:%[a-zA-Z0-9_]+]] Binding 2
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__runtimearr_float:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[_float:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__struct_4:%[a-zA-Z0-9_]+]] = OpTypeStruct [[__runtimearr_float:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_7:%[a-zA-Z0-9_]+]] = OpTypeStruct [[_uint:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_11:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[_uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[_uint:%[a-zA-Z0-9_]+]] 3
// CHECK-DAG: [[__arr_float_uint_3:%[a-zA-Z0-9_]+]] = OpTypeArray [[_float:%[a-zA-Z0-9_]+]] [[_uint_3:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__ptr_Private__arr_float_uint_3:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[__arr_float_uint_3:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[__ptr_Private_float:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_float:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint:%[a-zA-Z0-9_]+]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint:%[a-zA-Z0-9_]+]] 0
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpUndef [[_float:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_false:%[a-zA-Z0-9_]+]] = OpConstantFalse [[_bool:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_true:%[a-zA-Z0-9_]+]] = OpConstantTrue [[_bool:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_float_1:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 1
// CHECK-DAG: [[_float_2:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 2
// CHECK-DAG: [[_float_3:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 3
// CHECK-DAG: [[_26:%[a-zA-Z0-9_]+]] = OpConstantComposite [[__arr_float_uint_3:%[a-zA-Z0-9_]+]] [[_float_1:%[a-zA-Z0-9_]+]] [[_float_2:%[a-zA-Z0-9_]+]] [[_float_3:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[_float_10:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 10
// CHECK-DAG: [[_float_11:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 11
// CHECK-DAG: [[_float_12:%[a-zA-Z0-9_]+]] = OpConstant [[_float:%[a-zA-Z0-9_]+]] 12
// CHECK-DAG: [[_30:%[a-zA-Z0-9_]+]] = OpConstantComposite [[__arr_float_uint_3:%[a-zA-Z0-9_]+]] [[_float_10:%[a-zA-Z0-9_]+]] [[_float_11:%[a-zA-Z0-9_]+]] [[_float_12:%[a-zA-Z0-9_]+]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpSpecConstant [[_uint:%[a-zA-Z0-9_]+]] 1
// CHECK: [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] = OpSpecConstantComposite [[_v3uint:%[a-zA-Z0-9_]+]] [[_31:%[a-zA-Z0-9_]+]] [[_32:%[a-zA-Z0-9_]+]] [[_33:%[a-zA-Z0-9_]+]]
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] Private [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private__arr_float_uint_3:%[a-zA-Z0-9_]+]] Private [[_26:%[a-zA-Z0-9_]+]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private__arr_float_uint_3:%[a-zA-Z0-9_]+]] Private [[_30:%[a-zA-Z0-9_]+]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] StorageBuffer
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpFunction [[_void:%[a-zA-Z0-9_]+]] None [[_11:%[a-zA-Z0-9_]+]]
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] [[_38:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_44:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] [[_39:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_45:%[a-zA-Z0-9_]+]] = OpLoad [[_uint:%[a-zA-Z0-9_]+]] [[_44:%[a-zA-Z0-9_]+]]
// CHECK: [[_46:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] [[_40:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_47:%[a-zA-Z0-9_]+]] = OpLoad [[_uint:%[a-zA-Z0-9_]+]] [[_46:%[a-zA-Z0-9_]+]]
// CHECK: [[_48:%[a-zA-Z0-9_]+]] = OpIEqual [[_bool:%[a-zA-Z0-9_]+]] [[_45:%[a-zA-Z0-9_]+]] [[_uint_0:%[a-zA-Z0-9_]+]]
// CHECK: [[_49:%[a-zA-Z0-9_]+]] = OpLogicalNot [[_bool:%[a-zA-Z0-9_]+]] [[_48:%[a-zA-Z0-9_]+]]
// CHECK: OpSelectionMerge [[_53:%[a-zA-Z0-9_]+]] None
// CHECK: OpBranchConditional [[_49:%[a-zA-Z0-9_]+]] [[_50:%[a-zA-Z0-9_]+]] [[_53:%[a-zA-Z0-9_]+]]
// CHECK: [[_50:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_51:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_Private_float:%[a-zA-Z0-9_]+]] [[_37:%[a-zA-Z0-9_]+]] [[_47:%[a-zA-Z0-9_]+]]
// CHECK: [[_52:%[a-zA-Z0-9_]+]] = OpLoad [[_float:%[a-zA-Z0-9_]+]] [[_51:%[a-zA-Z0-9_]+]]
// CHECK: OpBranch [[_53:%[a-zA-Z0-9_]+]]
// CHECK: [[_53:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_55:%[a-zA-Z0-9_]+]] = OpPhi [[_bool:%[a-zA-Z0-9_]+]] [[_false:%[a-zA-Z0-9_]+]] [[_50:%[a-zA-Z0-9_]+]] [[_true:%[a-zA-Z0-9_]+]] [[_42:%[a-zA-Z0-9_]+]]
// CHECK: [[_54:%[a-zA-Z0-9_]+]] = OpPhi [[_float:%[a-zA-Z0-9_]+]] [[_52:%[a-zA-Z0-9_]+]] [[_50:%[a-zA-Z0-9_]+]] [[_20:%[a-zA-Z0-9_]+]] [[_42:%[a-zA-Z0-9_]+]]
// CHECK: OpSelectionMerge [[_56:%[a-zA-Z0-9_]+]] None
// CHECK: OpBranchConditional [[_55:%[a-zA-Z0-9_]+]] [[_58:%[a-zA-Z0-9_]+]] [[_56:%[a-zA-Z0-9_]+]]
// CHECK: [[_56:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_57:%[a-zA-Z0-9_]+]] = OpPhi [[_float:%[a-zA-Z0-9_]+]] [[_54:%[a-zA-Z0-9_]+]] [[_53:%[a-zA-Z0-9_]+]] [[_60:%[a-zA-Z0-9_]+]] [[_58:%[a-zA-Z0-9_]+]]
// CHECK: OpStore [[_43:%[a-zA-Z0-9_]+]] [[_57:%[a-zA-Z0-9_]+]]
// CHECK: OpReturn
// CHECK: [[_58:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_59:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_Private_float:%[a-zA-Z0-9_]+]] [[_36:%[a-zA-Z0-9_]+]] [[_47:%[a-zA-Z0-9_]+]]
// CHECK: [[_60:%[a-zA-Z0-9_]+]] = OpLoad [[_float:%[a-zA-Z0-9_]+]] [[_59:%[a-zA-Z0-9_]+]]
// CHECK: OpBranch [[_56:%[a-zA-Z0-9_]+]]
// CHECK: OpFunctionEnd
