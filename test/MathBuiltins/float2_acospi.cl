// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float2* A, float2 x)
{
  *A = acospi(x);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 32
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_25:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v2float:%[a-zA-Z0-9_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_6:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_8:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_8]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_23:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_23]] Binding 0
// CHECK: OpDecorate [[_24:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_24]] Binding 1
// CHECK: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK: [[__ptr_StorageBuffer_v2float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK: [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK: [[__struct_6]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK: [[__struct_8]] = OpTypeStruct [[_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK: [[_12:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.31831
// CHECK: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v2float]] [[_float_0_31831]] [[_float_0_31831]]
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_19]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_18]] [[_19]] [[_20]]
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK: [[_25]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_24]] [[_uint_0]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_v2float]] [[_28]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_v2float]] [[_1]] Acos [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpFMul [[_v2float]] [[_17]] [[_30]]
// CHECK: OpStore [[_27]] [[_31]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
