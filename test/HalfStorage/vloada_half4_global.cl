// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, global uint2* B, uint n) {
  A[0] = vloada_half4(n, (global half*)B);
  A[1] = vloada_half4(0, (global half*)B+2);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 55
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[__runtimearr_v2uint:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpMemberDecorate [[__struct_14:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_14]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_31]] Binding 0
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 1
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[__ptr_StorageBuffer_v2uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2uint]]
// CHECK-DAG: [[__runtimearr_v2uint]] = OpTypeRuntimeArray [[_v2uint]]
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[__runtimearr_v2uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__struct_14]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_14:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_14]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_18:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_26]] [[_27]] [[_28]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_14]] StorageBuffer
// CHECK: [[_34]] = OpFunction [[_void]] None [[_18]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_31]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_37]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_32]] [[_uint_0]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 0
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 1
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_41]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_42]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_43]] [[_44]] 0 1 2 3
// CHECK: OpStore [[_36]] [[_45]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpSDiv [[_uint]] [[_uint_2]] [[_uint_4]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2uint]] [[_32]] [[_uint_0]] [[_46]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_47]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_48]] 0
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_48]] 1
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_49]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_50]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_51]] [[_52]] 0 1 2 3
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_31]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_54]] [[_53]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
