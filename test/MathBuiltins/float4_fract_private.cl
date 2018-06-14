// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float4* A, global float4* B, float4 x)
{
  float4 z;
  *A = fract(x, &z);
  *B = z;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 35
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_26:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_19:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_20:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[a-zA-Z0-9_]+]] ArrayStride 16
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
// CHECK-DAG: [[_v4float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[__struct_8]] = OpTypeStruct [[_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_8:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_8]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_12:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_float_1:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] {{1|0.99999}}
// CHECK-DAG: [[_17:%[a-zA-Z0-9_]+]] = OpConstantComposite [[_v4float]] [[_float_1]] [[_float_1]] [[_float_1]] [[_float_1]]
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_19]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_18]] [[_19]] [[_20]]
// CHECK: [[_22:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_8]] StorageBuffer
// CHECK: [[_26]] = OpFunction [[_void]] None [[_12]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_24]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_25]] [[_uint_0]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpLoad [[_v4float]] [[_30]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] Floor [[_31]]
// CHECK: [[_33:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] Fract [[_31]]
// CHECK: [[_34:%[a-zA-Z0-9_]+]] = OpExtInst [[_v4float]] [[_1]] FMin [[_33]] [[_17]]
// CHECK: OpStore [[_28]] [[_34]]
// CHECK: OpStore [[_29]] [[_32]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
