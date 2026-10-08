// When a pointer value is emitted with a logical storage class (for example
// a Private variable produced by rehoming) but the consumer expects a
// PhysicalStorageBuffer pointer, the producer used to emit an OpBitcast
// with a logical pointer operand, which is invalid SPIR-V. It must keep the
// value's own pointer type instead.

// RUN: clspv %target %s -physical-storage-buffers -arch=spir64 -O2 -global-offset -std430-ubo-layout -module-constants-in-storage-buffer -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// The rehomed lookup table is a Private variable carrying its initializer.
// CHECK: OpVariable %_ptr_Private__arr_uint_uint_4 Private %{{[0-9]+}}
// No bitcast may reinterpret a logical pointer as physical.
// CHECK-NOT: OpBitcast %_ptr_PhysicalStorageBuffer %{{[0-9]+}}

typedef struct inner_t {
  int h[4];
  int w0[4];
  int w1[4];
  int w2[4];
  int w3[4];
  int len;
} inner_t;

typedef struct outer_t {
  inner_t ipad;
  inner_t opad;
} outer_t;

kernel void repro(global int* out, int seed) {
  // Dense switch so SimplifyCFG creates a lookup table at -O2 (see
  // switch_table_global_constant.cl).
  uint t = 0;
  switch (seed & 3) {
    case 0: t = 0u; break;
    case 1: t = 16777216u; break;
    case 2: t = 65536u; break;
    case 3: t = 256u; break;
  }
  out[3] = t;
  outer_t c;
  c.opad.w0[0] = seed;
  c.opad.w0[1] = seed + 1;
  c.opad.w0[2] = seed + 2;
  c.opad.w0[3] = seed + 3;
  c.opad.len = seed + 4;
  int (*p)[4] = &c.opad.w0;
  int i = seed & 3;
  (*p)[i] = (*p)[i] + 1;
  out[0] = (*p)[0] + c.opad.len;
  out[1] = c.ipad.h[seed & 3];
}
