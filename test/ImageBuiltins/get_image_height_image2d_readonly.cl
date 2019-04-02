// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// #219: Sampled images cannot be queried in Vulkan.
// RUN: not spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global int* out, read_only image2d_t im)
{
  *out = get_image_height(im);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 21
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability ImageQuery
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_15:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpExecutionMode [[_15]] LocalSize 1 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[_13:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_13]] Binding 0
// CHECK: OpDecorate [[_14:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_14]] Binding 1
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_8:%[0-9a-zA-Z_]+]] = OpTypeImage [[_float]] 2D 0 0 0 1 Unknown
// CHECK-DAG: [[__ptr_UniformConstant_8:%[0-9a-zA-Z_]+]] = OpTypePointer UniformConstant [[_8]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_11:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_13]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_14]] = OpVariable [[__ptr_UniformConstant_8]] UniformConstant
// CHECK: [[_15]] = OpFunction [[_void]] None [[_11]]
// CHECK: [[_16:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_17:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_13]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_18:%[0-9a-zA-Z_]+]] = OpLoad [[_8]] [[_14]]
// CHECK: [[_19:%[0-9a-zA-Z_]+]] = OpImageQuerySize [[_v2uint]] [[_18]]
// CHECK: [[_20:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_19]] 1
// CHECK: OpStore [[_17]] [[_20]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
