// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Proves ConstantDataVector and ConstantArray work.

__constant uint ppp[2][3] = {{1,2,3}, {5}};

kernel void foo(global uint* A, uint i) { *A = ppp[i][i]; }

// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,010000000200000003000000050000000000000000000000
