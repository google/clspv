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

