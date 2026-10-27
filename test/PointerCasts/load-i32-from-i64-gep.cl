// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The buffer is accessed as uint, so the load of the low half of in[i] through
// (uint *)(in + i) must use index 2 * i.

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[gid:%[^ ]+]] = OpLoad [[uint]]
// CHECK: [[lo_idx:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[gid]] %uint_1
// CHECK: OpAccessChain {{%[^ ]+}} {{%[^ ]+}} %uint_0 [[lo_idx]]
// CHECK: [[hi_idx:%[^ ]+]] = OpBitwiseOr [[uint]] [[lo_idx]] %uint_1
// CHECK: OpAccessChain {{%[^ ]+}} {{%[^ ]+}} %uint_0 [[hi_idx]]

kernel void foo(global const ulong *in, global uint *out) {
  size_t i = get_global_id(0);
  uint lo = *(global const uint *)(in + i);
  uint hi = ((global const uint *)in)[2 * i + 1];
  out[i] = lo + hi;
}
