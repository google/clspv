// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %s -o %t.spv --physical-storage-buffers --arch=spir64 -spv-version=1.5
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// p is loaded as int and is the start of a loop over its bytes.

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uchar]]
// CHECK: [[c:%[^ ]+]] = OpPhi [[ptr]] [[next:%[^ ]+]] {{%[^ ]+}} {{%[^ ]+}} {{%[^ ]+}}
// CHECK: OpLoad [[uchar]] [[c]]
// CHECK: [[next]] = OpPtrAccessChain [[ptr]] [[c]] %uint_1

kernel void foo(global const int *in, global int *out, int n) {
  size_t gid = get_global_id(0);
  global const int *p = in + gid;
  int x = *p;
  int s = 0;
  global const char *c = (global const char *)p;
  for (int i = 0; i < n; i++, c++)
    s += *c;
  out[gid] = x + s;
}
