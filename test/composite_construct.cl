// Test rewriting complete sets of insertions into a struct.
// The rewrite is done by default.

// RUN: clspv %s -S -o %t.spvasm -no-inline-single
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


typedef struct { float a, b, c, d; } S;

S boo(float a) {
  S result;
  // This entire chain of insertions is replaced by a single 
  // OpCompositeConstruct
  result.a = a;
  result.c = a+2.0f;
  result.b = a+1.0f;
  result.d = a+3.0f;
  return result;
}

kernel void foo(global S* data, float f) {
  *data = boo(f);
}

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: ; Generator: Codeplay; 0
// CHECK: ; Bound: 49
// CHECK: ; Schema: 0
// CHECK: OpCapability Shader
// CHECK: OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK: OpMemoryModel Logical GLSL450
// CHECK: OpEntryPoint GLCompute [[_36:%[0-9a-zA-Z_]+]] "foo"
// CHECK: OpSource OpenCL_C 120
// CHECK: OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK: OpDecorate [[_23:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK: OpDecorate [[_24:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK: OpMemberDecorate [[__struct_2:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[__struct_2]] 1 Offset 4
// CHECK: OpMemberDecorate [[__struct_2]] 2 Offset 8
// CHECK: OpMemberDecorate [[__struct_2]] 3 Offset 12
// CHECK: OpDecorate [[__runtimearr__struct_2:%[0-9a-zA-Z_]+]] ArrayStride 16
// CHECK: OpMemberDecorate [[__struct_4:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_4]] Block
// CHECK: OpMemberDecorate [[__struct_6:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK: OpDecorate [[__struct_6]] Block
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_27]] Binding 0
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK: OpDecorate [[_28]] Binding 1
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__struct_2]] = OpTypeStruct [[_float]] [[_float]] [[_float]] [[_float]]
// CHECK-DAG: [[__runtimearr__struct_2]] = OpTypeRuntimeArray [[__struct_2]]
// CHECK-DAG: [[__struct_4]] = OpTypeStruct [[__runtimearr__struct_2]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_4:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_4]]
// CHECK-DAG: [[__struct_6]] = OpTypeStruct [[_float]]
// CHECK-DAG: [[__ptr_StorageBuffer__struct_6:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_6]]
// CHECK-DAG: [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_11:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG: [[_12:%[0-9a-zA-Z_]+]] = OpTypeFunction [[__struct_2]] [[_float]]
// CHECK-DAG: [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG: [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK-DAG: [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK-DAG: [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK-DAG: [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK: [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_23]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_24]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_22]] [[_23]] [[_24]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK: [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_4]] StorageBuffer
// CHECK: [[_28]] = OpVariable [[__ptr_StorageBuffer__struct_6]] StorageBuffer
// CHECK: [[_29:%[0-9a-zA-Z_]+]] = OpFunction [[__struct_2]] Const [[_12]]
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_float]]
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_30]] [[_float_2]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_30]] [[_float_1]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_30]] [[_float_3]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_30]] [[_33]] [[_32]] [[_34]]
// CHECK: OpReturnValue [[_35]]
// CHECK: OpFunctionEnd
// CHECK: [[_36]] = OpFunction [[_void]] None [[_11]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_28]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpFunctionCall [[__struct_2]] [[_29]] [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_40]] 0
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_40]] 1
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_40]] 2
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_40]] 3
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_45]] [[_41]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_46]] [[_42]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]] [[_uint_2]]
// CHECK: OpStore [[_47]] [[_43]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_27]] [[_uint_0]] [[_uint_0]] [[_uint_3]]
// CHECK: OpStore [[_48]] [[_44]]
// CHECK: OpReturn
// CHECK: OpFunctionEnd
