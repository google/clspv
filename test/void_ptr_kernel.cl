// RUN: clspv %s -o %t.spv -cl-kernel-arg-info -int8 -enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: FileCheck %s < %t2.spvasm

static void test_inner(global int* in, global int* out, size_t i) {
  out[i] = in[i];
}

void kernel test(global void* a, global void* b, int n) {
  test_inner(a, b, get_global_id(0));
}

// Check reflection info has void* arguments (clspv-reflection doesn't parse the
// extended arg info so just check the SPIR-V directly)
// CHECK: [[void_ty1:%[a-zA-Z0-9_.]+]] = OpString "void*"
// CHECK: [[void_ty2:%[a-zA-Z0-9_.]+]] = OpString "void*"
// CHECK: ArgumentInfo %{{[a-zA-Z0-9_.]+}} [[void_ty1]]
// CHECK: ArgumentInfo %{{[a-zA-Z0-9_.]+}} [[void_ty2]]
