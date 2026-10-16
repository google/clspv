// A rehomed lookup table must keep its Private pointer: bitcasting it to a
// PhysicalStorageBuffer pointer would be invalid SPIR-V.

// RUN: clspv %target %s -physical-storage-buffers -arch=spirv64 -O2 -global-offset -std430-ubo-layout -module-constants-in-storage-buffer -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK: OpVariable %_ptr_Private__arr_uint_uint_4 Private %{{[0-9]+}}
// CHECK-NOT: OpBitcast %_ptr_PhysicalStorageBuffer %{{[0-9]+}}

kernel void repro(global int* out, int seed) {
  uint t = 0;
  switch (seed & 3) {
    case 0: t = 0u; break;
    case 1: t = 16777216u; break;
    case 2: t = 65536u; break;
    case 3: t = 256u; break;
  }
  out[3] = t;
}
