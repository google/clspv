// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float3* A, float3 y, float3 x)
{
  *A = atan2pi(y, x);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 35
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_26:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v3float:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_6:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_8:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_8]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_23:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_23]] Binding 0
// CHECK: OpDecorate [[_24:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_24]] Binding 1
// CHECK: OpDecorate [[_25:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_25]] Binding 2
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v3float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 3
// CHECK-DAG: [[__ptr_StorageBuffer_v3float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v3float]]
// CHECK-DAG: [[__runtimearr_v3float]] = OpTypeRuntimeArray [[_v3float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v3float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[__struct_8]] = OpTypeStruct [[_v3float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_12:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v3float]] [[_float_0_31831]] [[_float_0_31831]] [[_float_0_31831]]
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_19]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_18]] [[_19]] [[_20]]
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK: [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK: [[_26]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_24]] [[_uint_0]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpLoad [[_v3float]] [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v3float]] [[_25]] [[_uint_0]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpLoad [[_v3float]] [[_31]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpExtInst [[_v3float]] [[_1]] Atan2 [[_30]] [[_32]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpFMul [[_v3float]] [[_17]] [[_33]]
// CHECK: OpStore [[_28]] [[_34]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
