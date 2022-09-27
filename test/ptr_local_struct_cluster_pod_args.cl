// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args -pod-ubo -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck %s < %t2.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args -pod-ubo -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: clspv-reflection %t.spv -o %t2.map
// RUN: FileCheck %s < %t2.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct S {
  int a; int b;
} S;

kernel void foo(local float *L, global float* A, S local* LS, constant float* C, float f, float g ) {
 *A = *L + *C + f + g + LS->a;
}

//      MAP: kernel,foo,arg,L,argOrdinal,0,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,1,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,LS,argOrdinal,2,argKind,local,arrayElemSize,8,arrayNumElemSpecId,4
// MAP-NEXT: kernel,foo,arg,C,argOrdinal,3,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,f,argOrdinal,4,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo,argSize,4
// MAP-NEXT: kernel,foo,arg,g,argOrdinal,5,descriptorSet,0,binding,2,offset,4,argKind,pod_ubo,argSize,4
// MAP-NOT: kernel

// CHECK:      OpDecorate [[_37:%[0-9a-zA-Z_]+]] Binding 2
// CHECK:      OpDecorate [[_2:%[0-9a-zA-Z_]+]] SpecId 3
// CHECK:      OpDecorate [[_7:%[0-9a-zA-Z_]+]] SpecId 4
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[__struct_15:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]] [[_float]]
// CHECK-DAG:  [[__struct_16:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__struct_15]]
// CHECK-DAG:  [[__ptr_Uniform__struct_16:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_16]]
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[__ptr_Workgroup_float:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_float]]
// CHECK-DAG:  [[__ptr_StorageBuffer_float:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[_float]]
// CHECK-DAG:  [[__ptr_Uniform__struct_15:%[0-9a-zA-Z_]+]] = OpTypePointer Uniform [[__struct_15]]
// CHECK-DAG:  [[__ptr_Workgroup_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[_uint]]
// CHECK-DAG:  [[_v3uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 3
// CHECK-DAG:  [[__struct_24:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_uint]] [[_uint]]
// CHECK-DAG:  [[_2]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_2]]
// CHECK-DAG:  [[__ptr_Workgroup__arr_float_2:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr_float_2]]
// CHECK-DAG:  [[_7]] = OpSpecConstant [[_uint]] 1
// CHECK-DAG:  [[__arr__struct_24_7:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_24]] [[_7]]
// CHECK-DAG:  [[__ptr_Workgroup__arr__struct_24_7:%[0-9a-zA-Z_]+]] = OpTypePointer Workgroup [[__arr__struct_24_7]]
// CHECK-DAG:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG:  [[_37]] = OpVariable [[__ptr_Uniform__struct_16]] Uniform
// CHECK-DAG:  [[_1:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr_float_2]] Workgroup
// CHECK-DAG:  [[_6:%[0-9a-zA-Z_]+]] = OpVariable [[__ptr_Workgroup__arr__struct_24_7]] Workgroup
// CHECK-64-DAG: [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-64-DAG: [[_ulong_0:%[0-9a-zA-Z_]+]] = OpConstant [[_ulong]] 0
// CHECK:      [[_5:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_float]] [[_1]] [[_uint_0]]
// CHECK:      [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Uniform__struct_15]] [[_37]] [[_uint_0]]
// CHECK:      [[_43:%[0-9a-zA-Z_]+]] = OpLoad [[__struct_15]] [[_42]]
// CHECK:      [[_44:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_43]] 0
// CHECK:      [[_45:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_43]] 1
// CHECK:      [[_46:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_5]]
// CHECK-64:   [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_ulong_0]] [[_uint_0]]
// CHECK-32:   [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain [[__ptr_Workgroup_uint]] [[_6]] [[_uint_0]] [[_uint_0]]
// CHECK:      [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]] [[_51]]
// CHECK:      [[_53:%[0-9a-zA-Z_]+]] = OpConvertSToF [[_float]] [[_52]]
