// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float2* A, uint v, uint w, uint n) {
  uint arr[2] = {v, w};
  A[0] = __clspv_vloada_half2(n, &arr[0]);
  A[1] = __clspv_vloada_half2(0, &v);
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 48
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpCapability VariablePointers
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpExtension "SPV_KHR_variable_pointers"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_31:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_v2float:%[0-9a-zA-Z_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 0
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 1
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_29]] Binding 2
// CHECK: OpDecorate [[_30:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_30]] Binding 3
// CHECK: OpDecorate [[__arr_uint_uint_2:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK: [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK: [[__runtimearr_v2float]] = OpTypeRuntimeArray [[_v2float]]
// CHECK: [[__struct_6]] = OpTypeStruct [[__runtimearr_v2float]]
// CHECK: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[__struct_9]] = OpTypeStruct [[_uint]]
// CHECK: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK: [[_13:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[__arr_uint_uint_2]] = OpTypeArray [[_uint]] [[_uint_2]]
// CHECK: [[__ptr_Function__arr_uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_uint_uint_2]]
// CHECK: [[__ptr_Function_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_uint]]
// CHECK: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_29]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_30]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_31]] = OpFunction [[_void]] None [[_13]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_uint_uint_2]] Function
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_27]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_28]] [[_uint_0]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_29]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_37]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_30]] [[_uint_0]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_33]] [[_uint_0]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_33]] [[_uint_1]]
// CHECK: OpStore [[_41]] [[_36]]
// CHECK: OpStore [[_42]] [[_38]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_33]] [[_40]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_43]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_44]]
// CHECK: OpStore [[_34]] [[_45]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] [[_1]] UnpackHalf2x16 [[_36]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_27]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_47]] [[_46]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
