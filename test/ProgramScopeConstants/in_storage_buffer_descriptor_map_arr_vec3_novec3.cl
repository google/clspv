// RUN: clspv %s -o %t.spv -module-constants-in-storage-buffer -vec3-to-vec4
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -module-constants-in-storage-buffer -vec3-to-vec4 --enable-opaque-pointers
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Proves ConstantDataVector and ConstantArray work.

__constant uint3 ppp[2] = {(uint3)(1,2,3), (uint3)(5)};

kernel void foo(global uint* A, uint i) { *A = ppp[i].x; }



// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,010000000200000003000000{{........}}050000000500000005000000{{........}}
