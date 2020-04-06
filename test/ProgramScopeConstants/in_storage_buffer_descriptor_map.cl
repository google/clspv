// RUN: clspv %s -o %t.spv -descriptormap=%t.map -module-constants-in-storage-buffer -int8=0
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  char c;
  uint a;
  float f;
} Foo;
__constant Foo ppp[3] = {{'a', 0x1234abcd, 1.0}, {'b', 0xffffffff, 1.5}, {0}};

kernel void foo(global uint* A, uint i) { *A = ppp[i].a; }

// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,61000000cdab34120000803f62000000ffffffff0000c03f000000000000000000000000
// MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,foo,arg,i,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4

