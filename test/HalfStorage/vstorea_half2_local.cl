// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(local uint* A, float2 val, uint n) {
  vstorea_half2(val, n, (local half*) A);
  vstorea_half2_rte(val, n+1, (local half*) A);
  vstorea_half2_rtz(val, n+2, (local half*) A);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 45
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_6:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_13]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 0
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 1
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK: [[__struct_9]] = OpTypeStruct [[_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK: [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_13]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK: [[__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_2]]
// CHECK: [[__ptr_Workgroup__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_uint_2]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_24]] [[_25]] [[_26]]
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK: [[_31]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_uint_0]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_29]] [[_uint_0]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_33]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_34]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_Workgroup_uint]] [[_5]] [[_36]]
// CHECK: OpStore [[_38]] [[_37]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_1]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_34]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_Workgroup_uint]] [[_5]] [[_39]]
// CHECK: OpStore [[_41]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_2]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_34]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_Workgroup_uint]] [[_5]] [[_42]]
// CHECK: OpStore [[_44]] [[_43]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
