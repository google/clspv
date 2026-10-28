// RUN: clspv %s -o %t.spv --arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %s -o %t.spv --physical-storage-buffers --arch=spir64 -spv-version=1.5
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// p is loaded as int before the loop, and then advanced by a number of bytes
// that is a multiple of 4, sign-extended to 64 bits. The GEP advancing p must
// be upgraded to an i32 GEP from the known bits of its offset, so that the PHI
// of p is a pointer to uint.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: [[start:%[^ ]+]] = OpAccessChain [[ptr]]
// CHECK: OpLoad [[uint]] [[start]]
// CHECK: [[stride:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK: [[p:%[^ ]+]] = OpPhi [[ptr]] [[next:%[^ ]+]] {{%[^ ]+}} [[start]] {{%[^ ]+}}
// CHECK: [[next]] = OpPtrAccessChain [[ptr]] [[p]] [[stride]]
// CHECK: OpLoad [[uint]] [[next]]

kernel void foo(global int *in, global int *out, int stride, int n) {
  size_t gid = get_global_id(0);
  global int *p = in + gid;
  int s = *p;
  for (int i = 1; i < n; i++) {
    p = (global int *)((global char *)p + stride * 4);
    s += *p;
  }
  out[gid] = s;
}
