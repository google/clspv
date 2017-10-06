// Generating the descriptor map goes through two different flows in the compiler.
// Check both.

// RUN: clspv %s -o %t.spv -descriptormap=%t.map
// RUN: FileCheck %s < %t.map
// RUN: clspv %s -o %t.spv -descriptormap=%t.cluster.map -cluster-pod-kernel-args 
// RUN: FileCheck -check-prefix=CLUSTER %s < %t.cluster.map

// CHECK: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// CHECK-NEXT: kernel,foo,arg,RO,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,foo,arg,WO,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,wo_image
// CHECK-NEXT: kernel,foo,arg,SAM,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,sampler
// CHECK-NEXT: kernel,foo,arg,c,argOrdinal,4,descriptorSet,0,binding,4,offset,0,argKind,pod
// CHECK-NEXT: kernel,foo,arg,d,argOrdinal,5,descriptorSet,0,binding,5,offset,0,argKind,pod
// CHECK-NOT: foo

// CLUSTER: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// CLUSTER-NEXT: kernel,foo,arg,RO,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,ro_image
// CLUSTER-NEXT: kernel,foo,arg,WO,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,wo_image
// CLUSTER-NEXT: kernel,foo,arg,SAM,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,sampler
// CLUSTER-NEXT: kernel,foo,arg,c,argOrdinal,4,descriptorSet,0,binding,4,offset,0,argKind,pod
// CLUSTER-NEXT: kernel,foo,arg,d,argOrdinal,5,descriptorSet,0,binding,4,offset,4,argKind,pod
// CLUSTER-NOT: foo

kernel void foo(global int *A, read_only image2d_t RO, write_only image2d_t WO,
                sampler_t SAM, int c, int d) {}
