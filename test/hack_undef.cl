// Test the -hack-undef option.
// It's a workaround for https://github.com/google/clspv/issues/95
// This test no longer is powerful due to zero-initizalization of allocas.

// RUN: clspv %s -S -o %t.spvasm -hack-undef
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -hack-undef
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float4* A)
{
  float4 value;
  value.w = 1111.0f;
  *A = value;
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 25
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_22:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_16:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_17:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_18:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_21:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 0
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG: [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG: [[__struct_5]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK-DAG: [[_float_1111:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1111
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_0]] [[_float_0]] [[_float_0]] [[_float_1111]]
// CHECK: [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_16]] [[_17]] [[_18]]
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_22]] = OpFunction [[_void]] None [[_9]]
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_24]] [[_15]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
