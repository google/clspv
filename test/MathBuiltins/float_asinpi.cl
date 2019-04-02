// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float* A, float x)
{
  *A = asinpi(x);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 30
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_23:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_17:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_18:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_5:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpMemberDecorate [[__struct_7:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_7]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_21:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_21]] Binding 0
// CHECK: OpDecorate [[_22:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_22]] Binding 1
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG: [[__struct_5]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG: [[__struct_7]] = OpTypeStruct [[_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[_11:%[a-zA-Z0-9_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_float_0_31831:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] 0.3183
// CHECK: [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_17]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_18]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_16]] [[_17]] [[_18]]
// CHECK: [[_20:%[a-zA-Z0-9_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_21]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_22]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK: [[_23]] = OpFunction [[_void]] None [[_11]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_21]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_22]] [[_uint_0]]
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpLoad [[_float]] [[_26]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Asin [[_27]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpFMul [[_float]] [[_float_0_31831]] [[_28]]
// CHECK: OpStore [[_25]] [[_29]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
