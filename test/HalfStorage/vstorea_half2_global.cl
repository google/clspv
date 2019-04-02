// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global uint* A, float2 val, uint n) {
  vstorea_half2(val, n, (global half*) A);
  vstorea_half2_rte(val, n+1, (global half*) A);
  vstorea_half2_rtz(val, n+2, (global half*) A);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 43
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_29:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_26]] Binding 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 1
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 2
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG: [[__struct_5]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[__struct_9]] = OpTypeStruct [[_v2float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG: [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_21]] [[_22]] [[_23]]
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_29]] = OpFunction [[_void]] None [[_15]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_27]] [[_uint_0]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_31]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_33]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_32]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_34]]
// CHECK: OpStore [[_36]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_32]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_37]]
// CHECK: OpStore [[_39]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_34]] [[_uint_2]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_32]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_40]]
// CHECK: OpStore [[_42]] [[_41]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
