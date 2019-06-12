// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm

// TODO(dneto): OpPtrAccessChain on pointer to Private is not alloweed by SPV_KHR_variable_pointers
// RUN: not spirv-val --target-env vulkan1.0 %t.spv

constant uint b[4] = {42, 13, 0, 5};

uint bar(constant uint* a)
{
  return a[get_local_id(0)];
}

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = bar(b);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 36
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo" [[_gl_LocalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK:  OpExecutionMode [[_31]] LocalSize 4 1 1
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpDecorate [[_gl_LocalInvocationID]] BuiltIn LocalInvocationId
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_23]] Binding 0
// CHECK:  OpDecorate [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_6:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG:  [[__arr_uint_uint_4]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK-DAG:  [[__ptr_Private__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr_uint_uint_4]]
// CHECK-DAG:  [[__ptr_Private_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_uint]]
// CHECK-DAG:  [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_uint]] [[__ptr_Private_uint]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK-DAG:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK-DAG:  [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK-DAG:  [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG:  [[_20:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_4]] [[_uint_42]] [[_uint_13]] [[_uint_0]] [[_uint_5]]
// CHECK-DAG:  [[_gl_LocalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK-DAG:  [[_22:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private__arr_uint_uint_4]] Private [[_20]]
// CHECK-DAG:  [[_23]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunction [[_uint]] Pure [[_12]]
// CHECK:  [[_25:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_Private_uint]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_27:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_LocalInvocationID]] [[_uint_0]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_27]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Private_uint]] [[_22]] [[_28]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_29]]
// CHECK:  OpReturnValue [[_30]]
// CHECK:  OpFunctionEnd
// CHECK:  [[_31]] = OpFunction [[_void]] None [[_6]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_23]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Private_uint]] [[_22]] [[_uint_0]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_24]] [[_34]]
// CHECK:  OpStore [[_33]] [[_35]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
