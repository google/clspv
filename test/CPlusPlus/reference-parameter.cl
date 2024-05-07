// RUN: clspv --cl-std=CLC++ --inline-entry-points %s --output-format=ll -O3 -o %t.ll
// RUN: FileCheck %s < %t.ll

// CHECK: define dso_local spir_func i32 @_Z1fRU3AS4i(ptr addrspace(4) align 4 dereferenceable(4) %x)
int f(int &x) {
    return x;
}
