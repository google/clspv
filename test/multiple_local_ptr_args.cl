// RUN: clspv %s -o %t.spv -descriptormap=%t.map -cluster-pod-kernel-args
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck  %s < %t.spvasm
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv
//
// RUN: clspv %s -o %t2.spv -descriptormap=%t2.map -cluster-pod-kernel-args=0
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck  %s < %t2.spvasm
// RUN: FileCheck --check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

kernel void foo(global int* out, local int* l1, int a, int b, local int* l2) {
  *out = *l1 + a + b + *l2;
}

kernel void bar(global int* out, local int* l1, int a, int b, local int* l2) {
  *out = *l1 - a - b - *l2;
}

// MAP: kernel,foo,arg,l1,argOrdinal,1,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3
// MAP: kernel,foo,arg,l2,argOrdinal,4,argKind,local,arrayElemSize,4,arrayNumElemSpecId,4

// CHECK: OpDecorate [[spec_id_3:%[a-zA-Z0-9_]+]] SpecId 3
// CHECK: OpDecorate [[spec_id_4:%[a-zA-Z0-9_]+]] SpecId 4
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[spec_id_3]] = OpSpecConstant [[uint]] 1
// CHECK-DAG: [[array_3:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[spec_id_3]]
// CHECK-DAG: [[ptr_id_3:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[array_3]]
// CHECK-DAG: [[spec_id_4]] = OpSpecConstant [[uint]] 1
// CHECK-DAG: [[array_4:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[spec_id_4]]
// CHECK-DAG: [[ptr_id_4:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[array_4]]
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-DAG: [[var_3:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_id_3]] Workgroup
// CHECK-DAG: [[var_4:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_id_4]] Workgroup
// CHECK: [[gep_3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var_3]] [[uint_0]]
// CHECK: [[gep_4:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var_4]] [[uint_0]]
// CHECK: OpLoad [[uint]] [[gep_3]]
// CHECK: OpLoad [[uint]] [[gep_4]]
