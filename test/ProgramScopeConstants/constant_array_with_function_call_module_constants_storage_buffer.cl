// RUN: clspv %s -S -o %t.spvasm -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv


constant uint b[4] = {42, 13, 0, 5};

uint bar(constant uint* a)
{
  return a[get_local_id(0)];
}

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = bar(b);
}


// MAP: constant,descriptorSet,0,binding,0,kind,buffer,hexbytes,2a0000000d0000000000000005000000
// MAP-NEXT: kernel,foo,arg,a,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,buffer


// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 39
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo" [[_gl_LocalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK: OpExecutionMode [[_33]] LocalSize 4 1 1
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_10:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[_gl_LocalInvocationID]] BuiltIn LocalInvocationId
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_24]] Binding 0
// CHECK: OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK: OpDecorate [[_25]] Binding 0
// CHECK: OpDecorate [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpDecorate [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__ptr_StorageBuffer_uint]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK: [[__struct_4]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_7:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK: [[__arr_uint_uint_4]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK: [[__struct_10]] = OpTypeStruct [[__arr_uint_uint_4]]
// CHECK: [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK: [[__ptr_StorageBuffer__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__arr_uint_uint_4]]
// CHECK: [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_uint]] [[__ptr_StorageBuffer_uint]]
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK: [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK: [[_uint_13:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 13
// CHECK: [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_uint_uint_4]] [[_uint_42]] [[_uint_13]] [[_uint_0]] [[_uint_5]]
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__struct_10]] [[_21]]
// CHECK: [[_gl_LocalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK: [[_24]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK: [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpFunction [[_uint]] Pure [[_13]]
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK: [[_28:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_LocalInvocationID]] [[_uint_0]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_29]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_30]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK: OpReturnValue [[_32]]
// CHECK: OpFunctionEnd
// CHECK: [[_33]] = OpFunction [[_void]] None [[_7]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_25]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer__arr_uint_uint_4]] [[_24]] [[_uint_0]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_36]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[_26]] [[_37]]
// CHECK: OpStore [[_35]] [[_38]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
