// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

void core(global int *A, int n, local int *B) { A[n] = B[n + 2]; }

void apple(local int *B, global int *A, int n) { core(A, n + 1, B); }

kernel void foo(global int *A, int n, local int *B) { apple(B, A, n); }

kernel void bar(global int *A, int n, local int *B) { apple(B, A, n); }
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 64
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpCapability VariablePointers
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpExtension "SPV_KHR_variable_pointers"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_52:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_58:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_13]] Block
// CHECK:  OpMemberDecorate [[__struct_15:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_15]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_33]] Binding 0
// CHECK:  OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_34]] Binding 1
// CHECK:  OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK:  OpDecorate [[_7:%[0-9a-zA-Z_]+]] SpecId 4
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_13]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK:  [[__struct_15]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_15:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_15]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK:  [[_21:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_StorageBuffer_uint]] [[_uint]] [[__ptr_Workgroup_uint]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]] [[__ptr_Workgroup_uint]] [[__ptr_StorageBuffer_uint]] [[_uint]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_2]]
// CHECK:  [[__ptr_Workgroup__arr_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_uint_2]]
// CHECK:  [[_7]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[__arr_uint_7:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_7]]
// CHECK:  [[__ptr_Workgroup__arr_uint_7:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_uint_7]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_28]] [[_29]] [[_30]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:  [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_15]] StorageBuffer
// CHECK:  [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK:  [[_6:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_uint_7]] Workgroup
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_21]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_Workgroup_uint]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_40:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_37]] [[_uint_2]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpPtrAccessChain [[__ptr_Workgroup_uint]] [[_38]] [[_40]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_41]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_37]]
// CHECK:  OpStore [[_43]] [[_42]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpFunction [[_void]] None [[_22]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_Workgroup_uint]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__ptr_StorageBuffer_uint]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_uint]]
// CHECK:  [[_48:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_50:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_47]] [[_uint_1]]
// CHECK:  [[_51:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_35]] [[_49]] [[_50]] [[_45]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_52]] = OpFunction [[_void]] None [[_18]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_1]] [[_uint_0]]
// CHECK:  [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_34]] [[_uint_0]]
// CHECK:  [[_56:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_55]]
// CHECK:  [[_57:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44]] [[_5]] [[_54]] [[_56]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
// CHECK:  [[_58]] = OpFunction [[_void]] None [[_18]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_10:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_uint_0]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_61:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_34]] [[_uint_0]]
// CHECK:  [[_62:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_61]]
// CHECK:  [[_63:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_44]] [[_10]] [[_60]] [[_62]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
