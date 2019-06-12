// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, uint2 v, uint2 w, uint n) {
  uint2 arr[2] = {v, w};
  A[0] = __clspv_vloada_half4(n, &arr[0]);
  A[1] = __clspv_vloada_half4(0, &v);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Bound: 61
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_36:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_10]] Block
// CHECK: OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_13]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 0
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 1
// CHECK: OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_34]] Binding 2
// CHECK: OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_35]] Binding 3
// CHECK: OpDecorate [[__arr_v2uint_uint_2:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[__ptr_StorageBuffer_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2uint]]
// CHECK-DAG: [[__struct_10]] = OpTypeStruct [[_v2uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__struct_13]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_17:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[__arr_v2uint_uint_2]] = OpTypeArray [[_v2uint]] [[_uint_2]]
// CHECK-DAG: [[__ptr_Function__arr_v2uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_v2uint_uint_2]]
// CHECK-DAG: [[__ptr_Function_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_v2uint]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_27]] [[_28]] [[_29]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK: [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK: [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK: [[_36]] = OpFunction [[_void]] None [[_17]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_v2uint_uint_2]] Function
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_32]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_33]] [[_uint_0]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_34]] [[_uint_0]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_42]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_35]] [[_uint_0]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_44]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_38]] [[_uint_0]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_38]] [[_uint_1]]
// CHECK: OpStore [[_46]] [[_41]]
// CHECK: OpStore [[_47]] [[_43]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_v2uint]] [[_38]] [[_45]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_48]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_49]] 0
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_49]] 1
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_50]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_51]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_52]] [[_53]] 0 1 2 3
// CHECK: OpStore [[_39]] [[_54]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_41]] 0
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_41]] 1
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_55]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_56]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_57]] [[_58]] 0 1 2 3
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_32]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_60]] [[_59]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
