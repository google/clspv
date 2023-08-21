// RUN: clspv %s -o %t.spv -cl-std=CLC++ -inline-entry-points -O3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct S { int i1; };

kernel void Kernel(global void* Memory)
{
    long a = (long) Memory;

    //* (int*) a = 0; // OK, address space inferred
     * (S*) a = {}; // Fails, address space not inferred. OK if externally optimized
    // * (global S*) a = {}; // OK, address space explicit
}
