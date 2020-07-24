// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -global-offset -inline-entry-points
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global int* out, char c, short s, int i, long l, float f, half h, double d) {
  *out = i + get_global_id(0);
}

// CHECK: pushconstant,name,global_offset,offset,0,size,12
// CHECK: pushconstant,name,region_offset,offset,16,size,12
// CHECK: kernel,foo,arg,out,argOrdinal,0
// CHECK: kernel,foo,arg,c,argOrdinal,1,offset,32,argKind,pod_pushconstant,argSize,1
// CHECK: kernel,foo,arg,s,argOrdinal,2,offset,34,argKind,pod_pushconstant,argSize,2
// CHECK: kernel,foo,arg,i,argOrdinal,3,offset,36,argKind,pod_pushconstant,argSize,4
// CHECK: kernel,foo,arg,l,argOrdinal,4,offset,40,argKind,pod_pushconstant,argSize,8
// CHECK: kernel,foo,arg,f,argOrdinal,5,offset,48,argKind,pod_pushconstant,argSize,4
// CHECK: kernel,foo,arg,h,argOrdinal,6,offset,52,argKind,pod_pushconstant,argSize,2
// CHECK: kernel,foo,arg,d,argOrdinal,7,offset,56,argKind,pod_pushconstant,argSize,8
