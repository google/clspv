// RUN: clspv %s -S -o %t.spvasm -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  char c;
  uint a;
  float f;
} Foo;
__constant Foo ppp[3] = {{'a', 0x1234abcd, 1.0}, {'b', 0xffffffff, 1.5}, {0}};

kernel void foo(global uint* A, uint i) { *A = ppp[i].a; }

// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,61000000cdab34120000803f62000000ffffffff0000c03f000000000000000000000000
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4


// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Generator: Codeplay; 0
// CHECK:  ; Bound: 35
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_28:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpSource OpenCL_C 120
// CHECK:  OpDecorate [[_20:%[0-9a-zA-Z_]+]] SpecId 0
// CHECK:  OpDecorate [[_21:%[0-9a-zA-Z_]+]] SpecId 1
// CHECK:  OpDecorate [[_22:%[0-9a-zA-Z_]+]] SpecId 2
// CHECK:  OpDecorate [[__runtimearr_uint:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK:  OpMemberDecorate [[__struct_3:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_3]] Block
// CHECK:  OpMemberDecorate [[__struct_5:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[__struct_5]] Block
// CHECK:  OpMemberDecorate [[__struct_11:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[__struct_11]] 1 Offset 4
// CHECK:  OpMemberDecorate [[__struct_11]] 2 Offset 8
// CHECK:  OpMemberDecorate [[__struct_14:%[0-9a-zA-Z_]+]] 0 Offset 0
// CHECK:  OpDecorate [[_gl_WorkGroupSize:%[0-9a-zA-Z_]+]] BuiltIn WorkgroupSize
// CHECK:  OpDecorate [[_25:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK:  OpDecorate [[_25]] Binding 0
// CHECK:  OpDecorate [[_26:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_26]] Binding 0
// CHECK:  OpDecorate [[_27:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_27]] Binding 1
// CHECK:  OpDecorate [[__arr__struct_11_uint_3:%[0-9a-zA-Z_]+]] ArrayStride 12
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[__runtimearr_uint]] = OpTypeRuntimeArray [[_uint]]
// CHECK:  [[__struct_3]] = OpTypeStruct [[__runtimearr_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_3:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_3]]
// CHECK:  [[__struct_5]] = OpTypeStruct [[_uint]]
// CHECK:  [[__ptr_StorageBuffer__struct_5:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_5]]
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_8:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[__ptr_StorageBuffer_uint:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_uint]]
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK:  [[__struct_11]] = OpTypeStruct [[_uint]] [[_uint]] [[_float]]
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[__arr__struct_11_uint_3]] = OpTypeArray [[__struct_11]] [[_uint_3]]
// CHECK:  [[__struct_14]] = OpTypeStruct [[__arr__struct_11_uint_3]]
// CHECK:  [[__ptr_StorageBuffer__struct_14:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_14]]
// CHECK:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK:  [[__ptr_Private_v3uint:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[_v3uint]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_20]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_21]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_22]] = OpSpecConstant [[_uint]] 1
// CHECK:  [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_20]] [[_21]] [[_22]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Private_v3uint]] Private [[_gl_WorkGroupSize]]
// CHECK:  [[_25]] = OpVariable [[__ptr_StorageBuffer__struct_14]] StorageBuffer
// CHECK:  [[_26]] = OpVariable [[__ptr_StorageBuffer__struct_3]] StorageBuffer
// CHECK:  [[_27]] = OpVariable [[__ptr_StorageBuffer__struct_5]] StorageBuffer
// CHECK:  [[_28]] = OpFunction [[_void]] None [[_8]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_26]] [[_uint_0]] [[_uint_0]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_27]] [[_uint_0]]
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_31]]
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] [[_25]] [[_uint_0]] [[_32]] [[_uint_1]]
// CHECK:  [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_33]]
// CHECK:  OpStore [[_30]] [[_34]]
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
