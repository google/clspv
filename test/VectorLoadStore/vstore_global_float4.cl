// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float* A, float4 v, uint n) {
  vstore4(v, n, A);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 47
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_29:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_23:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7]] Block
// CHECK: OpMemberDecorate [[__struct_11:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_11]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_26:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_26]] Binding 0
// CHECK: OpDecorate [[_27:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 1
// CHECK: OpDecorate [[_28:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 2
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG: [[__struct_4]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_4:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__struct_7]] = OpTypeStruct [[_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__struct_11]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_11:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_15:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_21]] [[_22]] [[_23]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_29]] = OpFunction [[_void]] None [[_15]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_27]] [[_uint_0]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpLoad [[_v4float]] [[_31]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpLoad [[_uint]] [[_33]]
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[_uint]] [[_34]] [[_uint_2]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_32]] 0
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_32]] 1
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_32]] 2
// CHECK: [[_39:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]] [[_32]] 3
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_35]]
// CHECK: OpStore [[_40]] [[_36]]
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_35]] [[_uint_1]]
// CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_41]]
// CHECK: OpStore [[_42]] [[_37]]
// CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_1]]
// CHECK: [[_44:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_43]]
// CHECK: OpStore [[_44]] [[_38]]
// CHECK: [[_45:%[a-zA-Z0-9_]+]] = OpIAdd [[_uint]] [[_43]] [[_uint_1]]
// CHECK: [[_46:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_26]] [[_uint_0]] [[_45]]
// CHECK: OpStore [[_46]] [[_39]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
