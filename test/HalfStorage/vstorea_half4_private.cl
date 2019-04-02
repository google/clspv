// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint2* A, float4 val, uint n) {
  uint2 arr[64];
  half* cast = (private half*) arr;
  vstorea_half4(val, n, cast+4);
  vstorea_half4_rte(val, n+1, cast+8);
  vstorea_half4_rtz(val, n+2, cast+12);
  *A = *(uint2*) arr;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 68
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_40:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_34:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v2uint:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_10]] Block
// CHECK: OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_13]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_37:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_37]] Binding 0
// CHECK: OpDecorate [[_38:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_38]] Binding 1
// CHECK: OpDecorate [[_39:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_39]] Binding 2
// CHECK: OpDecorate [[__arr_v2uint_uint_64:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[__ptr_StorageBuffer_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2uint]]
// CHECK-DAG: [[__runtimearr_v2uint]] = OpTypeRuntimeArray [[_v2uint]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v2uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__struct_10]] = OpTypeStruct [[_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__struct_13]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_64:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 64
// CHECK-DAG: [[__arr_v2uint_uint_64]] = OpTypeArray [[_v2uint]] [[_uint_64]]
// CHECK-DAG: [[__ptr_Function__arr_v2uint_uint_64:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_v2uint_uint_64]]
// CHECK-DAG: [[__ptr_Function_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_v2uint]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_27:%[0-9a-zA-Z_]+]] = OpConstantNull [[__arr_v2uint_uint_64]]
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_32]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_33]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_34]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_32]] [[_33]] [[_34]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_37]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_38]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK: [[_39]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK: [[_40]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_v2uint_uint_64]] Function
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_37]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_38]] [[_uint_0]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_44]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_39]] [[_uint_0]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_46]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_42]] [[_uint_0]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_45]] [[_26]] 0 1
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_45]] [[_26]] 2 3
// CHECK: OpStore [[_42]] [[_27]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_49]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_50]]
// CHECK: [[construct1:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_51]] [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_1]] [[_47]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_42]] [[_55]]
// CHECK: OpStore [[_56]] [[construct1]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_47]] [[_uint_1]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_49]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_50]]
// CHECK: [[construct2:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_58]] [[_59]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_2]] [[_57]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_42]] [[_62]]
// CHECK: OpStore [[_63]] [[construct2]]
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_47]] [[_uint_2]]
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_49]]
// CHECK: [[_66:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_50]]
// CHECK: [[construct3:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_65]] [[_66]]
// CHECK: [[_69:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_3]] [[_64]]
// CHECK: [[_70:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_42]] [[_69]]
// CHECK: OpStore [[_70]] [[construct3]]
// CHECK: [[_71:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_48]]
// CHECK: OpStore [[_43]] [[_71]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
