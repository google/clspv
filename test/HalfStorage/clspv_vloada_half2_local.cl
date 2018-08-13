// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float2* A, local uint* B, uint n) {
  A[0] = __clspv_vloada_half2(n, B);
  A[1] = __clspv_vloada_half2(0, B);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 42
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
// CHECK: OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_11]] Block
// CHECK: OpMemberDecorate [[__struct_14:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_14]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 0
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 1
// CHECK: OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG: [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK-DAG: [[__struct_11]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_11:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_11]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__struct_14]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_14:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_14]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_18:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_uint_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_24]] [[_25]] [[_26]]
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_11]] StorageBuffer
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_14]] StorageBuffer
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK: [[_31]] = OpFunction [[_void]] None [[_18]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_uint_0]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_34]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_36]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_37]]
// CHECK: OpStore [[_33]] [[_38]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_5]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_6]] UnpackHalf2x16 [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_29]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_41]] [[_40]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
