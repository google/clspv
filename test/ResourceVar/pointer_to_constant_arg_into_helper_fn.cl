// Have to preserve the address space of pointer-to-constant.
// RUN: clspv %s
void helper(global int* A, constant int* B) { *A = *B; }

kernel void foo(global int* A, constant int* B) { helper(A, B); }

