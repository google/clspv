// The optimizer's switch-to-lookup-table conversion creates internal
// read-only globals in the Global address space with constant initializers
// (visible at -O3). Emitting them as StorageBuffer resources is invalid on
// three counts for Vulkan: the variable type is not a struct, the storage
// class does not allow initializers, and SPIR-V 1.4+ requires listed
// interfaces. They must be rehomed to module-scope Private variables.

// RUN: clspv %target %s -O3 -module-constants-in-storage-buffer -global-offset -std430-ubo-layout -spv-version=1.5 -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// The rehomed tables are Private variables carrying their initializers.
// CHECK: OpVariable %_ptr_Private__arr_uint_uint_4 Private %{{[0-9]+}}
// No rehomed table may remain a StorageBuffer variable with an initializer.
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
  uint u = 0;
  switch (x & 7) {
    case 0: u = 1u; break;
    case 1: u = 2u; break;
    case 2: u = 4u; break;
    case 3: u = 8u; break;
    case 4: u = 16u; break;
    case 5: u = 32u; break;
    case 6: u = 64u; break;
    case 7: u = 128u; break;
  }
  out[1] = u;
  uint v = 0;
  switch (x & 15) {
    case 0: v = 0x100u; break;
    case 1: v = 0x200u; break;
    case 2: v = 0x300u; break;
    case 3: v = 0x400u; break;
    case 4: v = 0x500u; break;
    case 5: v = 0x600u; break;
    case 6: v = 0x700u; break;
    case 7: v = 0x800u; break;
    case 8: v = 0x900u; break;
    case 9: v = 0xa00u; break;
    case 10: v = 0xb00u; break;
    case 11: v = 0xc00u; break;
    case 12: v = 0xd00u; break;
    case 13: v = 0xe00u; break;
    case 14: v = 0xf00u; break;
    case 15: v = 0x1000u; break;
  }
  out[2] = v;
}
