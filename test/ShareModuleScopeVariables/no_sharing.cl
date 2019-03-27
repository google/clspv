// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int helper(local int* A, int idx) { return A[idx]; }

kernel void foo(global int *in, global int* out, int n) {
  local int tmp1[32];
  local int tmp2[32];
  tmp1[n] = in[n];
  barrier(CLK_LOCAL_MEM_FENCE);
  tmp2[n] = helper(tmp1, n);
  barrier(CLK_LOCAL_MEM_FENCE);
  out[n] = helper(tmp2, n);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 49
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_36:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[_3]] Block
// CHECK: OpMemberDecorate [[_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[_5]] Block
// CHECK: OpDecorate [[_25:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 0
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 1
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 2
// CHECK: OpDecorate [[_11:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG: [[_1:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_2]] = OpTypeRuntimeArray [[_1]]
// CHECK-DAG: [[_3]] = OpTypeStruct [[_2]]
// CHECK-DAG: [[_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_3]]
// CHECK-DAG: [[_5]] = OpTypeStruct [[_1]]
// CHECK-DAG: [[_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_5]]
// CHECK-DAG: [[_7:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_7]]
// CHECK-DAG: [[_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_1]]
// CHECK-DAG: [[_10:%[0-9a-zA-Z_]+]] = OpConstant [[_1]] 32
// CHECK-DAG: [[_11]] = OpTypeArray [[_1]] [[_10]]
// CHECK-DAG: [[_12:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_11]]
// CHECK-DAG: [[_13:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_1]]
// CHECK-DAG: [[_14:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_1]] [[_13]] [[_1]]
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpTypeVector [[_1]] 3
// CHECK-DAG: [[_16:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_15]]
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpConstant [[_1]] 0
// CHECK-DAG: [[_18:%[0-9a-zA-Z_]+]] = OpConstant [[_1]] 2
// CHECK-DAG: [[_19:%[0-9a-zA-Z_]+]] = OpConstant [[_1]] 272
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpVariable [[_12]] Workgroup
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpVariable [[_12]] Workgroup
// CHECK-DAG: [[_22]] = OpSpecConstant [[_1]] 1
// CHECK-DAG: [[_23]] = OpSpecConstant [[_1]] 1
// CHECK-DAG: [[_24]] = OpSpecConstant [[_1]] 1
// CHECK-DAG: [[_25]] = OpSpecConstantComposite [[_15]] [[_22]] [[_23]] [[_24]]
// CHECK-DAG: [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[_16]] Private [[_25]]
// CHECK-DAG: [[_27]] = OpVariable [[_4]] StorageBuffer
// CHECK-DAG: [[_28]] = OpVariable [[_4]] StorageBuffer
// CHECK-DAG: [[_29]] = OpVariable [[_6]] StorageBuffer
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpFunction [[_1]] Pure [[_14]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_13]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_1]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[_13]] [[_31]] [[_32]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_1]] [[_34]]
// CHECK: OpReturnValue [[_35]]
// CHECK: OpFunctionEnd
// CHECK: [[_36]] = OpFunction [[_7]] None [[_8]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[_9]] [[_29]] [[_17]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_1]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[_9]] [[_27]] [[_17]] [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_1]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[_13]] [[_20]] [[_39]]
// CHECK: OpStore [[_42]] [[_41]]
// CHECK: OpControlBarrier [[_18]] [[_18]] [[_19]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[_13]] [[_20]] [[_17]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_1]] [[_30]] [[_43]] [[_39]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[_13]] [[_21]] [[_39]]
// CHECK: OpStore [[_45]] [[_44]]
// CHECK: OpControlBarrier [[_18]] [[_18]] [[_19]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[_13]] [[_21]] [[_17]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_1]] [[_30]] [[_46]] [[_39]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[_9]] [[_28]] [[_17]] [[_39]]
// CHECK: OpStore [[_48]] [[_47]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
