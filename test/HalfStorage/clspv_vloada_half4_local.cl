// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, local float4* B, uint n) {
  A[0] = __clspv_vloada_half4(n, (local uint2*)B);
  A[1] = __clspv_vloada_half4(0, (local uint2*)B);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 66
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_6:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_35:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_11]] Block
// CHECK: OpMemberDecorate [[__struct_14:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_14]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 0
// CHECK: OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_34]] Binding 1
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_11]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__struct_14]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_14:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_14]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_18:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Workgroup_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_v4float]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_v4float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_v4float]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_v4float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_v4float_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpUndef [[_v2float]]
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_28]] [[_29]] [[_30]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_14]] StorageBuffer
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_v4float_2]] Workgroup
// CHECK: [[_35]] = OpFunction [[_void]] None [[_18]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_v4float]] [[_1]] [[_uint_0]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_33]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_34]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_Workgroup_v4float]] [[_5]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_41]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_43]] [[_uint_1]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_42]] [[_44]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2float]] [[_45]] [[_26]] 0
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_44]] [[_uint_1]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_42]] [[_47]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpCompositeInsert [[_v2float]] [[_48]] [[_46]] 1
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_49]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_50]] 0
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_50]] 1
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_51]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_53]] [[_54]] 0 1 2 3
// CHECK: OpStore [[_37]] [[_55]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_v4float]] [[_5]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_56]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_57]] [[_27]] 0 1
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_58]]
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_59]] 0
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_59]] 1
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_60]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_61]]
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_62]] [[_63]] 0 1 2 3
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_33]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_65]] [[_64]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
