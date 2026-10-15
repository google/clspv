// RUN: clspv %target %s -O3 -module-constants-in-storage-buffer -spv-version=1.5 -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK: OpVariable %_ptr_Private__arr_uint_uint_4 Private %{{[0-9]+}}
// CHECK-NOT: OpVariable %_ptr_StorageBuffer__arr_{{[a-z]+}}_uint_{{[0-9]+(_[0-9]+)?}} StorageBuffer %{{[0-9]+}}

kernel void test_switch_table(global uint *out, uint x) {
  uint t = 0;
  switch (x & 3) {
    case 0: t = 0u; break;
    case 1: t = 16777216u; break;
    case 2: t = 65536u; break;
    case 3: t = 256u; break;
  }
  out[0] = t;
}
