// RUN: clspv %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// The load of in[j] makes clspv type the buffer as ulong. The uint at the
// dynamic byte offset 8 * j + 4 from &in[i] is the high half of in[i + j]. It
// is loaded as component 1, not 0, of in[i + j]: the remainder of the offset
// divided by the size of a ulong must not be dropped.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK: [[a:%[^ ]+]] = OpLoad [[ulong]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[ulong]]
// CHECK: [[b_vec:%[^ ]+]] = OpBitcast [[v2uint]] [[b]]
// CHECK: [[b_hi:%[^ ]+]] = OpCompositeExtract [[uint]] [[b_vec]] 1
// CHECK: [[a_lo:%[^ ]+]] = OpUConvert [[uint]] [[a]]
// CHECK: OpIAdd [[uint]] [[b_hi]] [[a_lo]]

kernel void foo(global ulong *in, global uint *out, uint i, uint j) {
  global char *p = (global char *)&in[i];
  ulong a = in[j];
  uint b_hi = *(global uint *)(p + (8 * j + 4));
  *out = b_hi + (uint)a;
}
