// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

int inner(int arr[], int n) {
  arr[1] = n;
}

int helper(int arr[], int n) {
  inner(arr, n);
}

kernel void foo(global int* A, int n) {
  int arr[2];
  helper(arr, n);
  *A = arr[1];
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 25
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_20:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_13:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_14:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_15:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_18]] Binding 0
// CHECK: OpDecorate [[_19:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_19]] Binding 1
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG: [[__struct_4]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_13]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_14]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_15]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_13]] [[_14]] [[_15]]
// CHECK: [[_17:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_19]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_20]] = OpFunction [[_void]] None [[_9]]
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_18]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_19]] [[_uint_0]]
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_23]]
// CHECK: OpStore [[_22]] [[_24]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
