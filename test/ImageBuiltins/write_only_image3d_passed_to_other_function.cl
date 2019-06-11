// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable












void bar(write_only image3d_t i, int4 c, float4 a)
{
  write_imagef(i, c, a);
}


void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(write_only image3d_t i, int4 c, global float4* a)
{
  bar(i, c, *a);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 35
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability StorageImageWriteWithoutFormat
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_27:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_27]] LocalSize 1 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[__runtimearr_v4float:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK:  OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_10]] Block
// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_18]] Binding 0
// CHECK:  OpDecorate [[_18]] NonReadable
// CHECK:  OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_19]] Binding 1
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_20]] Binding 2
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_2:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 3D 0 0 0 2 Unknown
// CHECK-DAG:  [[__ptr_UniformConstant_2:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_2]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK-DAG:  [[__struct_6]] = OpTypeStruct [[_v4uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG:  [[__runtimearr_v4float]] = OpTypeRuntimeArray [[_v4float]]
// CHECK-DAG:  [[__struct_10]] = OpTypeStruct [[__runtimearr_v4float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[_2]] [[_v4uint]] [[_v4float]]
// CHECK-DAG:  [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_v4uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer_v4float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v4float]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_18]] = OpVariable [[__ptr_UniformConstant_2]] UniformConstant
// CHECK-DAG:  [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK-DAG:  [[_20]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_16]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_2]]
// CHECK:  [[_23:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4uint]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_v4float]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_18]]
// CHECK:  OpImageWrite [[_26]] [[_23]] [[_24]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_27]] = OpFunction [[_void]] None [[_13]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLoad [[_2]] [[_18]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4uint]] [[_19]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v4float]] [[_20]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_21]] [[_29]] [[_31]] [[_33]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
