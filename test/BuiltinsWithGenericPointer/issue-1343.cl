// RUN: clspv --cl-std=CLC++ --inline-entry-points %s --print-before=annotation-to-metadata -o %t.spv &> %t.ll
// RUN: FileCheck %s < %t.ll
// RUN: spirv-val %t.spv

// CHECK: define dso_local spir_func float @_Z22contains_frexp_in_namefPU3AS4i(float %0, ptr addrspace(4) %1)
// CHECK: define dso_local spir_func void @_Z12vstore_half5Dv2_fjPU3AS4Dh(<2 x float> %0, i32 %1, ptr addrspace(4) %2)
// CHECK: define dso_local spir_func void @_Z13xvstore_half2Dv2_fjPU3AS4Dh(<2 x float> %0, i32 %1, ptr addrspace(4) %2)

void kernel foo() {}
float contains_frexp_in_name(float, int *) { return 0.f; }

void vstore_half5(float2, size_t, half *) {}

void xvstore_half2(float2, size_t, half *) {}
