// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// A 64-bit __local variable written as two 32-bit halves, through a pointer
// cast and through a union, and read as a whole. The store of the high half,
// at a constant offset inside the 64-bit scalar, used to reach an unreachable
// in GetIdxsForTyFromOffset. The variable, shared by both kernels, is lowered
// to two uint.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[ptr:%[^ ]+]] = OpTypePointer Workgroup [[uint]]
// CHECK: [[lo:%[^ ]+]] = OpVariable [[ptr]] Workgroup
// CHECK: [[hi:%[^ ]+]] = OpVariable [[ptr]] Workgroup

// CHECK: = OpFunction
// CHECK: OpStore [[lo]]
// CHECK: OpStore [[hi]]
// CHECK: OpControlBarrier
// CHECK: [[x_lo:%[^ ]+]] = OpLoad [[uint]] [[lo]]
// CHECK: [[x_hi:%[^ ]+]] = OpLoad [[uint]] [[hi]]
// CHECK: [[x:%[^ ]+]] = OpCompositeConstruct [[v2uint]] [[x_lo]] [[x_hi]]
// CHECK: OpBitcast [[ulong]] [[x]]

// CHECK: = OpFunction
// CHECK: OpStore [[lo]]
// CHECK: OpStore [[hi]]
// CHECK: OpControlBarrier
// CHECK: [[x_lo:%[^ ]+]] = OpLoad [[uint]] [[lo]]
// CHECK: [[x_hi:%[^ ]+]] = OpLoad [[uint]] [[hi]]
// CHECK: [[x:%[^ ]+]] = OpCompositeConstruct [[v2uint]] [[x_lo]] [[x_hi]]
// CHECK: OpBitcast [[ulong]] [[x]]

kernel void ptr_cast(global ulong *out, uint a, uint b) {
  local ulong x;
  if (get_local_id(0) == 0) {
    local uint *x32 = (local uint *)&x;
    x32[0] = a;
    x32[1] = b;
  }
  barrier(CLK_LOCAL_MEM_FENCE);
  out[get_global_id(0)] = x;
}

kernel void via_union(global ulong *out, uint a, uint b) {
  local union {
    ulong l;
    uint i[2];
  } x;
  if (get_local_id(0) == 0) {
    x.i[0] = a;
    x.i[1] = b;
  }
  barrier(CLK_LOCAL_MEM_FENCE);
  out[get_global_id(0)] = x.l;
}
