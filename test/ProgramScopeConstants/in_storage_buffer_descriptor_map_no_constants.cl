// RUN: clspv %s -o %t.spv -module-constants-in-storage-buffer
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint* A, uint i) { A[i] = 0; }

// MAP-NOT: constant,descriptorSet
// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NOT: constant,descriptorSet
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,offset,0,argKind,pod_pushconstant,argSize,4
// MAP-NOT: constant,descriptorSet
