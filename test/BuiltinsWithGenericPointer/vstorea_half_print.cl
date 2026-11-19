// RUN: clspv %target %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space -o %t.spv -print-before-all 2> %t.ll
// RUN: FileCheck %s < %t.ll
// RUN: spirv-val --target-env spv1.0 %t.spv

// CHECK: declare spir_func void @_Z17vstorea_half2_rtnDv2_f[[SZ:[jm]]]PU3AS4Dh(<2 x float>, i{{32|64}}, ptr addrspace(4))

// CHECK: @clspv.builtins.used = appending global [3 x ptr] [ptr @_Z17vstorea_half2_rtnDv2_f[[SZ]]PDh, ptr @_Z17vstorea_half2_rtnDv2_f[[SZ]]PU3AS1Dh, ptr @_Z17vstorea_half2_rtnDv2_f[[SZ]]PU3AS3Dh], section "llvm.metadata"
// CHECK-DAG: define {{.*}} void @_Z17vstorea_half2_rtnDv2_f[[SZ]]PDh(
// CHECK-DAG: define {{.*}} void @_Z17vstorea_half2_rtnDv2_f[[SZ]]PU3AS3Dh(
// CHECK-DAG: define {{.*}} void @_Z17vstorea_half2_rtnDv2_f[[SZ]]PU3AS1Dh(

static void store(generic half *p, float2 v) {
  vstorea_half2_rtn(v, 0, p);
}

__kernel void foo(__global half *g, __local half *l, float2 v) {
  store(g, v);
  store(l, v);
}
