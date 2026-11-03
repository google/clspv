// RUN: clspv %s -o %t.spv --physical-storage-buffers --arch=spir64 -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// src[k] and dst[k] are accessed as ulong, which does not divide the 12 bytes
// of T, so ReplacePointerBitcastPass downgrades src and dst to GEPs of uint,
// and then dst to a GEP of uchar to store dst[k].b[4]. With
// --physical-storage-buffers, the GEP of src[k].b[4] is not downgraded along
// with src. As data is then accessed as uchar, src is replaced, and the GEP of
// src[k].b[4] must be folded into it.

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong_8:%[^ ]+]] = OpConstant [[ulong]] 8
// CHECK-DAG: [[ulong_12:%[^ ]+]] = OpConstant [[ulong]] 12
// CHECK: [[data:%[^ ]+]] = OpConvertUToPtr
// CHECK: [[i:%[^ ]+]] = OpUConvert [[ulong]]
// CHECK: OpUConvert [[ulong]]
// CHECK: [[k:%[^ ]+]] = OpUConvert [[ulong]]
// CHECK: [[src_k:%[^ ]+]] = OpIAdd [[ulong]] [[k]] [[i]]
// CHECK: [[src_k_off:%[^ ]+]] = OpIMul [[ulong]] [[src_k]] [[ulong_12]]
// CHECK: [[src_c_off:%[^ ]+]] = OpIAdd [[ulong]] [[src_k_off]] [[ulong_8]]
// CHECK: [[src_c:%[^ ]+]] = OpPtrAccessChain {{%[^ ]+}} [[data]] [[src_c_off]]
// CHECK: [[c:%[^ ]+]] = OpLoad [[uchar]] [[src_c]] Aligned 1
// CHECK: OpStore {{%[^ ]+}} [[c]] Aligned 1

typedef struct {
  int a;
  char b[5];
} T;

kernel void foo(global T *data, uint i, uint j, uint k) {
  global T *src = data + i;
  global T *dst = data + j;
  ulong w = *(global ulong *)&src[k];
  char c = src[k].b[4];
  *(global ulong *)&dst[k] = w;
  dst[k].b[4] = c;
}
