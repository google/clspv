// RUN: clspv %s -o %t.spv -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck %s < %t2.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct S {
  int a; int b;
} S;

kernel void foo(local float *L, global float* A, float f, S local* LS, constant float* C, float g ) {
 *A = *L + *C + f + g + LS->b;
}

//      MAP: kernel,foo,arg,A,argOrdinal,1,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,2,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
// MAP-NEXT: kernel,foo,arg,C,argOrdinal,4,descriptorSet,0,binding,2,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,g,argOrdinal,5,descriptorSet,0,binding,3,offset,0,argKind,pod,argSize,4
// MAP-NEXT: kernel,foo,arg,L,argOrdinal,0,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3
// MAP-NEXT: kernel,foo,arg,LS,argOrdinal,3,argKind,local,arrayElemSize,8,arrayNumElemSpecId,4
// MAP-NOT: kernel

// CHECK:      ; SPIR-V
// CHECK:      ; Version: 1.0
// CHECK:      ; Bound: 54
// CHECK:      ; Schema: 0
// CHECK:      OpCapability Shader
// CHECK:      OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:      OpMemoryModel Logical GLSL450
// CHECK:      OpEntryPoint GLCompute [[_38:%[0-9a-zA-Z_]+]] "foo"
// CHECK:      OpSource OpenCL_C 120
// CHECK:      OpDecorate [[_29:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:      OpDecorate [[_30:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:      OpDecorate [[_31:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:      OpDecorate [[__runtimearr_float:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:      OpMemberDecorate [[__struct_13:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:      OpDecorate [[__struct_13]] Block
// CHECK:      OpMemberDecorate [[__struct_15:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:      OpDecorate [[__struct_15]] Block
// CHECK:      OpMemberDecorate [[__struct_22:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:      OpMemberDecorate [[__struct_22]] 1 Offset 4
// CHECK:      OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:      OpDecorate [[_34:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:      OpDecorate [[_34]] Binding 0
// CHECK:      OpDecorate [[_35:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:      OpDecorate [[_35]] Binding 1
// CHECK:      OpDecorate [[_36:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:      OpDecorate [[_36]] Binding 2
// CHECK:      OpDecorate [[_36]] NonWritable
// CHECK:      OpDecorate [[_37:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:      OpDecorate [[_37]] Binding 3
// CHECK:      OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK:      OpDecorate [[_7:%[0-9a-zA-Z_]+]] SpecId 4
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[__runtimearr_float]] = OpTypeRuntimeArray [[_float]]
// CHECK-DAG:  [[__struct_13]] = OpTypeStruct [[__runtimearr_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_13:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_13]]
// CHECK-DAG:  [[__struct_15]] = OpTypeStruct [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_15:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_15]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_19:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK-DAG:  [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK-DAG:  [[__struct_22]] = OpTypeStruct [[_uint]] [[_uint]]
// CHECK-DAG:  [[__ptr_Workgroup__struct_22:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__struct_22]]
// CHECK-DAG:  [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK-DAG:  [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK-DAG:  [[_7]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr__struct_22_7:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_22]] [[_7]]
// CHECK-DAG:  [[__ptr_Workgroup__arr__struct_22_7:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr__struct_22_7]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG:  [[_29]] = OpSpecConstant [[_uint]] 1
// CHECK:      [[_30]] = OpSpecConstant [[_uint]] 1
// CHECK:      [[_31]] = OpSpecConstant [[_uint]] 1
// CHECK:      [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_29]] [[_30]] [[_31]]
// CHECK:      [[_33:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:      [[_34]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:      [[_35]] = OpVariable [[__ptr_StorageBuffer__struct_15]] StorageBuffer
// CHECK:      [[_36]] = OpVariable [[__ptr_StorageBuffer__struct_13]] StorageBuffer
// CHECK:      [[_37]] = OpVariable [[__ptr_StorageBuffer__struct_15]] StorageBuffer
// CHECK:      [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK:      [[_6:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr__struct_22_7]] Workgroup
// CHECK:      [[_38]] = OpFunction [[_void]] None [[_19]]
// CHECK:      [[_39:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:      [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_uint_0]]
// CHECK:      [[_40:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_34]] [[_uint_0]] [[_uint_0]]
// CHECK:      [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_35]] [[_uint_0]]
// CHECK:      [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_41]]
// CHECK:      [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_36]] [[_uint_0]] [[_uint_0]]
// CHECK:      [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_float]] [[_37]] [[_uint_0]]
// CHECK:      [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_44]]
// CHECK:      [[_46:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_5]]
// CHECK:      [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_43]]
// CHECK:      [[_48:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_46]] [[_47]]
// CHECK:      [[_49:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_48]] [[_42]]
// CHECK:      [[_50:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_49]] [[_45]]
// CHECK:      [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_uint_0]] [[_uint_1]]
// CHECK:      [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:      [[_53:%[0-9a-zA-Z_]+]] = OpConvertSToF [[_float]] [[_52]]
// CHECK:      [[_54:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_50]] [[_53]]
// CHECK:      OpStore [[_40]] [[_54]]
// CHECK:      OpReturn
// CHECK:      OpFunctionEnd
