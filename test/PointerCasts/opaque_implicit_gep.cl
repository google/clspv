// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that with opaque pointers we don't optimize away a GEP into the 1st
// element of the global ID and omit the OpAccessChain required to access
// individual elements

void kernel test(global int* out, int n) {
  out[get_global_id(0)] = n;
}

// If the OpAccessChain is omited then spirv-val should catch it, but check the
// spvasm anyway
// CHECK: OpDecorate %[[global_id:[a-zA-Z0-9_.]+]] BuiltIn GlobalInvocationId
// CHECK: %[[access_chain:[a-zA-Z0-9_.]+]] = OpAccessChain %{{[a-zA-Z0-9_.]+}} %[[global_id]]
// CHECK: OpLoad %{{[a-zA-Z0-9_.]+}} %[[access_chain]]
