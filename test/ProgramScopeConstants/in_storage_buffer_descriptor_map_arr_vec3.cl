// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Proves ConstantDataVector and ConstantArray work.

__constant uint3 ppp[2] = {(uint3)(1,2,3), (uint3)(5)};

kernel void foo(global uint* A, uint i) { *A = ppp[i].x; }



// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,0100000002000000030000000000000005000000050000000500000000000000
// MAP-NEXT: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,i,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
