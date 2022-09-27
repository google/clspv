// RUN: clspv %target %s -o %t.spv -cluster-pod-kernel-args
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test_restrict,arg,ptr1,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,test_restrict,arg,ptr2,argOrdinal,3,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP-NEXT: kernel,test_restrict,arg,ptr3,argOrdinal,4,descriptorSet,0,binding,2,offset,0,argKind,buffer
// MAP-NEXT: kernel,test_restrict,arg,pod1,argOrdinal,1,offset,0,argKind,pod_pushconstant,argSize,4
// MAP-NEXT: kernel,test_restrict,arg,pod2,argOrdinal,2,offset,4,argKind,pod_pushconstant,argSize,4

kernel void test_restrict(global int* restrict ptr1, int pod1, int pod2, global int* ptr2, global int* restrict ptr3)
{
}

