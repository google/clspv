// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The __clspv_vloada_half4 is like vloada_half4 but the pointer argument
// is pointer to uint2.

kernel void foo(global float4* A, global float4* B, uint n) {
  // Demonstrate fully general indexing.
  A[0] = __clspv_vloada_half4(n, (global uint2*)B);
  // The zero case optimizes quite nicely.
  A[1] = __clspv_vloada_half4(0, (global uint2*)B);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 59
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_30:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 0
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 1
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__struct_9]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_30]] = OpFunction [[_void]] None [[_13]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_33]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_28]] [[_uint_0]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_36]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_38]] [[_uint_1]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_37]] [[_39]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_37]] [[_42]]
// CHECK: [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_40]] [[_43]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[construct]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_45]] 0
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_45]] 1
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_46]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_47]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_48]] [[_49]] 0 1 2 3
// CHECK: OpStore [[_32]] [[_50]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_51]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_52]] [[_21]] 0 1
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_53]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_54]] 0
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_54]] 1
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_55]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_56]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_57]] [[_58]] 0 1 2 3
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_27]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_60]] [[_59]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
