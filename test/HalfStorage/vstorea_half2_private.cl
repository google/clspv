// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint* A, float2 val, uint n) {
  uint arr[5];
  half* cast = (private half*) arr;
  vstorea_half2(val, n, cast);
  vstorea_half2_rte(val, n+1, cast);
  vstorea_half2_rtz(val, n+2, cast);
  *A = *(uint*) arr;
}
// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 52
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_34:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_26:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK: OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_5]] Block
// CHECK: OpMemberDecorate [[__struct_9:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_9]] Block
// CHECK: OpMemberDecorate [[__struct_12:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_12]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_31:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_31]] Binding 0
// CHECK: OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_32]] Binding 1
// CHECK: OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_33]] Binding 2
// CHECK: OpDecorate [[__arr_uint_uint_5:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK-DAG: [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK-DAG: [[__struct_5]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[__struct_9]] = OpTypeStruct [[_v2float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_9:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_9]]
// CHECK-DAG: [[__ptr_StorageBuffer_v2float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_v2float]]
// CHECK-DAG: [[__struct_12]] = OpTypeStruct [[_uint]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_12:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_12]]
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_uint_5:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 5
// CHECK-DAG: [[__arr_uint_uint_5]] = OpTypeArray [[_uint]] [[_uint_5]]
// CHECK-DAG: [[__ptr_Function__arr_uint_uint_5:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[__arr_uint_uint_5]]
// CHECK-DAG: [[__ptr_Function_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Function [[_uint]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_23:%[0-9a-zA-Z_]+]] = OpConstantNull [[__arr_uint_uint_5]]
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_26]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_27]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_28]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_26]] [[_27]] [[_28]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_31]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK: [[_32]] = OpVariable [[__ptr_StorageBuffer__struct_9]] StorageBuffer
// CHECK: [[_33]] = OpVariable [[__ptr_StorageBuffer__struct_12]] StorageBuffer
// CHECK: [[_34]] = OpFunction [[_void]] None [[_15]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Function__arr_uint_uint_5]] Function
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_31]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_v2float]] [[_32]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_33]] [[_uint_0]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_36]] [[_uint_0]]
// CHECK: OpStore [[_36]] [[_23]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_39]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_36]] [[_41]]
// CHECK: OpStore [[_44]] [[_43]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_1]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_39]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_36]] [[_45]]
// CHECK: OpStore [[_47]] [[_46]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_2]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] [[_1]] PackHalf2x16 [[_39]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Function_uint]] [[_36]] [[_48]]
// CHECK: OpStore [[_50]] [[_49]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_42]]
// CHECK: OpStore [[_37]] [[_51]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
