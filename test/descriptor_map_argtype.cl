// Generating the descriptor map goes through two different flows in the compiler.
// Check both.

// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args=0
// RUN: clspv-reflection -d %t.spv -o %t.map
// RUN: FileCheck %s < %t.map
// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args 
// RUN: clspv-reflection -d %t.spv -o %t.cluster.map
// RUN: FileCheck -check-prefix=CLUSTER %s < %t.cluster.map

// CHECK: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// CHECK-NEXT: kernel,foo,arg,RO,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,foo,arg,WO,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,wo_image
// CHECK-NEXT: kernel,foo,arg,SAM,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,sampler
// CHECK-NEXT: kernel,foo,arg,c,argOrdinal,4,descriptorSet,0,binding,4,offset,0,argKind,pod_ubo,argSize,4
// CHECK-NEXT: kernel,foo,arg,d,argOrdinal,5,descriptorSet,0,binding,5,offset,0,argKind,pod_ubo,argSize,4
// CHECK-NOT: foo

// CLUSTER: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// CLUSTER-NEXT: kernel,foo,arg,RO,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,ro_image
// CLUSTER-NEXT: kernel,foo,arg,WO,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,wo_image
// CLUSTER-NEXT: kernel,foo,arg,SAM,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,sampler
// CLUSTER-NEXT: kernel,foo,arg,c,argOrdinal,4,offset,0,argKind,pod_pushconstant,argSize,4
// CLUSTER-NEXT: kernel,foo,arg,d,argOrdinal,5,offset,4,argKind,pod_pushconstant,argSize,4
// CLUSTER-NOT: foo

kernel void foo(global int *A, read_only image2d_t RO, write_only image2d_t WO,
                sampler_t SAM, int c, int d) {}
