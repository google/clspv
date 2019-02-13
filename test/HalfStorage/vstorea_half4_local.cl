// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(local uint2* A, float4 val, uint n) {
  vstorea_half4(val, n, ((local half*) A)+4);
  vstorea_half4_rte(val, n+1, ((local half*) A)+8);
  vstorea_half4_rte(val, n+2, ((local half*) A)+12);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 59
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_6:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_36:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_31:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_13]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_34]] Binding 0
// CHECK: OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_35]] Binding 1
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__struct_9]] = OpTypeStruct [[_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_13]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[__ptr_Workgroup_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_v2uint]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_v2uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_v2uint]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_v2uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_v2uint_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_31]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_29]] [[_30]] [[_31]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_v2uint_2]] Workgroup
// CHECK: [[_36]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_34]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_35]] [[_uint_0]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_39]] [[_24]] 0 1
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_39]] [[_24]] 2 3
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_42]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_43]]
// CHECK: [[construct1:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_44]] [[_45]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_1]] [[_41]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_v2uint]] [[_1]] [[_48]]
// CHECK: OpStore [[_49]] [[construct1]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_1]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_42]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_43]]
// CHECK: [[construct2:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_51]] [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_2]] [[_50]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_v2uint]] [[_1]] [[_55]]
// CHECK: OpStore [[_56]] [[construct2]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_2]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_42]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_6]] PackHalf2x16 [[_43]]
// CHECK: [[construct3:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_58]] [[_59]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_3]] [[_57]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_v2uint]] [[_1]] [[_62]]
// CHECK: OpStore [[_63]] [[construct3]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
