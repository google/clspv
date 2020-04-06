// RUN: clspv %s -o %t.spv -pod-pushconstant -cluster-pod-kernel-args -descriptormap=%t.map
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[foo_cluster:%[a-zA-Z0-9_]+]] = OpTypeStruct [[int]] [[int]]
// CHECK-DAG: [[foo_block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[foo_cluster]]
// CHECK-DAG: [[foo_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[foo_block]]
// CHECK-DAG: [[foo_var:%[a-zA-Z0-9_]+]] = OpVariable [[foo_ptr]] PushConstant
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[bar_cluster:%[a-zA-Z0-9_]+]] = OpTypeStruct [[float]] [[float]]
// CHECK-DAG: [[bar_block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[bar_cluster]]
// CHECK-DAG: [[bar_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[bar_block]]
// CHECK-DAG: [[bar_var:%[a-zA-Z0-9_]+]] = OpVariable [[bar_ptr]] PushConstant

//      MAP: kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,x,argOrdinal,1,offset,0,argKind,pod_pushconstant,argSize,4
// MAP-NEXT: kernel,foo,arg,y,argOrdinal,2,offset,4,argKind,pod_pushconstant,argSize,4
//      MAP: kernel,bar,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,bar,arg,a,argOrdinal,1,offset,0,argKind,pod_pushconstant,argSize,4
// MAP-NEXT: kernel,bar,arg,b,argOrdinal,2,offset,4,argKind,pod_pushconstant,argSize,4

kernel void foo(global int* out, int x, int y) {
  *out = x + y;
}

kernel void bar(global float *out, float a, float b) {
  *out = a + b;
}
