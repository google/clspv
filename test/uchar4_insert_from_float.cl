// Test for https://github.com/google/clspv/issues/15

kernel void foo(global uchar4* A, float f) {
 *A = (uchar4)(1,2,(uchar)f,4);
}

// RUN: clspv %s -o %t.spv -int8=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv





// This is ok because results ought to be unspecified if the conversion overflows.

// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 40
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_29:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_6]] Block
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_27]] Binding 0
// CHECK:  OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_28]] Binding 1
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__struct_6]] = OpTypeStruct [[_float]]
// CHECK:  [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_9:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_16908292:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16908292
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpUndef [[_uint]]
// CHECK:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK:  [[_uint_255:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 255
// CHECK:  [[_uint_16:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 16
// CHECK:  [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CHECK:  [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK:  [[_29]] = OpFunction [[_void]] None [[_9]]
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_32]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpConvertFToU [[_uint]] [[_33]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_uint_255]] [[_uint_16]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpNot [[_uint]] [[_35]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_uint_16908292]] [[_36]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_34]] [[_uint_16]]
// CHECK:  [[_39:%[0-9a-zA-Z_]+]] = OpBitwiseOr [[_uint]] [[_37]] [[_38]]
// CHECK:  OpStore [[_31]] [[_39]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
