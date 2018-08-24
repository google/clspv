// RUN: clspv %s -S -o %t.spvasm -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void write_local(__global int* in, __local int* tmp, unsigned int id) {
  tmp[id] = in[id];
}

void read_local(__global int* out, __local int* tmp, unsigned int id) {
  out[id] = tmp[id];
}

__kernel void local_memory(__global int* in, __global int* out, __local int* temp) {
  unsigned int gid = get_global_id(0);
  write_local(in, temp, gid);
  barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
  read_local(out, temp, gid);
}

// CHECK:     ; SPIR-V
// CHECK:     ; Version: 1.0
// CHECK:     ; Generator: Codeplay; 0
// CHECK:     ; Bound: 55
// CHECK:     ; Schema: 0
// CHECK:     OpCapability Shader
// CHECK:     OpCapability VariablePointers
// CHECK:     OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:     OpExtension "SPV_KHR_variable_pointers"
// CHECK:     OpMemoryModel Logical GLSL450
// CHECK:     OpEntryPoint GLCompute [[_46:%[0-9a-zA-Z_]+]] "local_memory" [[_gl_GlobalInvocationID:%[0-9a-zA-Z_]+]]
// CHECK:     OpSource OpenCL_C 120
// CHECK:     OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:     OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:     OpDecorate [[_25:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:     OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:     OpMemberDecorate [[__struct_7:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:     OpDecorate [[__struct_7:%[0-9a-zA-Z_]+]] Block
// CHECK:     OpDecorate [[_gl_GlobalInvocationID]] BuiltIn GlobalInvocationId
// CHECK:     OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:     OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:     OpDecorate [[_28]] Binding 0
// CHECK:     OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:     OpDecorate [[_29]] Binding 1
// CHECK:     OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG: [[__struct_7]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_7:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_7]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_10:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Input_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_v3uint]]
// CHECK-DAG: [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK-DAG: [[_16:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[__ptr_Workgroup_uint]] [[_uint]]
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_2]]
// CHECK-DAG: [[__ptr_Workgroup__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_uint_2]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_336:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 336
// CHECK-DAG: [[_gl_GlobalInvocationID]] = OpVariable [[__ptr_Input_v3uint]] Input
// CHECK-DAG: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[_25]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_23]] [[_24]] [[_25]]
// CHECK-DAG: [[_27:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK-DAG: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK-DAG: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK-DAG: [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK:     [[_30:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_16]]
// CHECK:     [[_31:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:     [[_32:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_Workgroup_uint]]
// CHECK:     [[_33:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:     [[_34:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:     [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_33]]
// CHECK:     [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_35]]
// CHECK:     [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_33]]
// CHECK:     OpStore [[_37]] [[_36]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd
// CHECK:     [[_38:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_16]]
// CHECK:     [[_39:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:     [[_40:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_Workgroup_uint]]
// CHECK:     [[_41:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:     [[_42:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:     [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_41]]
// CHECK:     [[_44:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_43]]
// CHECK:     [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_41]]
// CHECK:     OpStore [[_45]] [[_44]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd
// CHECK:     [[_46:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_10]]
// CHECK:     [[_47:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:     [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_uint_0]]
// CHECK:     [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]] [[_uint_0]]
// CHECK:     [[_50:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]] [[_uint_0]]
// CHECK:     [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Input_uint]] [[_gl_GlobalInvocationID]] [[_uint_0]]
// CHECK:     [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:     [[_53:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_30]] [[_49]] [[_48]] [[_52]]
// CHECK:     OpControlBarrier [[_uint_2]] [[_uint_1]] [[_uint_336]]
// CHECK:     [[_54:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_38]] [[_50]] [[_48]] [[_52]]
// CHECK:     OpReturn
// CHECK:     OpFunctionEnd
