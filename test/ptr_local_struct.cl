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

// CHECK:      OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK:      OpDecorate [[_7:%[0-9a-zA-Z_]+]] SpecId 4
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK-DAG:  [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK-DAG:  [[__struct_22:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_uint]] [[_uint]]
// CHECK-DAG:  [[__ptr_Workgroup__struct_22:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__struct_22]]
// CHECK-DAG:  [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK-DAG:  [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK-DAG:  [[_7]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr__struct_22_7:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_22]] [[_7]]
// CHECK-DAG:  [[__ptr_Workgroup__arr__struct_22_7:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr__struct_22_7]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:      [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK:      [[_6:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr__struct_22_7]] Workgroup
// CHECK:      [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_uint_0]]
// CHECK:      [[_46:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_5]]
// CHECK:      [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_uint_0]] [[_uint_1]]
// CHECK:      [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:      [[_53:%[0-9a-zA-Z_]+]] = OpConvertSToF [[_float]] [[_52]]
