// RUN: clspv %s -o %t.spv --physical-storage-buffers --arch=spir64 -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// As in gep_from_replaced_gep.cl, but src[k].b[2] and dst[k].b[2] are accessed
// as ushort. The ushort load through the GEP of src[k].b[2], which is folded
// into the replaced GEP of src, is replaced along with it, so the bytes at
// offsets 6 and 7 of src[k] are copied to dst[k]. It is not also replaced on
// its own, as a load of the uchar that the GEP of src[k].b[2] points to, which
// could leave the GEP of src in place and copy the bytes at offsets 4 and 5
// instead, depending on the order in which both were replaced.

// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ulong_6:%[^ ]+]] = OpConstant [[ulong]] 6
// CHECK-DAG: [[ulong_7:%[^ ]+]] = OpConstant [[ulong]] 7
// CHECK-DAG: [[ulong_12:%[^ ]+]] = OpConstant [[ulong]] 12
// CHECK: [[data:%[^ ]+]] = OpConvertUToPtr
// CHECK: [[i:%[^ ]+]] = OpUConvert [[ulong]]
// CHECK: [[j:%[^ ]+]] = OpUConvert [[ulong]]
// CHECK: [[dst_off:%[^ ]+]] = OpIMul [[ulong]] [[j]] [[ulong_12]]
// CHECK: [[k:%[^ ]+]] = OpUConvert [[ulong]]
// CHECK: [[src_k:%[^ ]+]] = OpIAdd [[ulong]] [[k]] [[i]]
// CHECK: [[src_k_off:%[^ ]+]] = OpIMul [[ulong]] [[src_k]] [[ulong_12]]
// CHECK: [[src_6_off:%[^ ]+]] = OpIAdd [[ulong]] [[src_k_off]] [[ulong_6]]
// CHECK: [[src_6:%[^ ]+]] = OpPtrAccessChain {{%[^ ]+}} [[data]] [[src_6_off]]
// CHECK: [[byte_6:%[^ ]+]] = OpLoad [[uchar]] [[src_6]] Aligned 1
// CHECK: [[src_7_off:%[^ ]+]] = OpIAdd [[ulong]] [[src_k_off]] [[ulong_7]]
// CHECK: [[src_7:%[^ ]+]] = OpPtrAccessChain {{%[^ ]+}} [[data]] [[src_7_off]]
// CHECK: [[byte_7:%[^ ]+]] = OpLoad [[uchar]] [[src_7]] Aligned 1
// CHECK: [[k_off:%[^ ]+]] = OpIMul [[ulong]] [[k]] [[ulong_12]]
// CHECK: [[k_6_off:%[^ ]+]] = OpIAdd [[ulong]] [[k_off]] [[ulong_6]]
// CHECK: [[dst_6_off:%[^ ]+]] = OpIAdd [[ulong]] [[dst_off]] [[k_6_off]]
// CHECK: [[dst_6:%[^ ]+]] = OpPtrAccessChain {{%[^ ]+}} [[data]] [[dst_6_off]]
// CHECK: [[k_7_off:%[^ ]+]] = OpIAdd [[ulong]] [[k_off]] [[ulong_7]]
// CHECK: [[dst_7_off:%[^ ]+]] = OpIAdd [[ulong]] [[dst_off]] [[k_7_off]]
// CHECK: [[dst_7:%[^ ]+]] = OpPtrAccessChain {{%[^ ]+}} [[data]] [[dst_7_off]]
// CHECK: OpStore [[dst_6]] [[byte_6]] Aligned 1
// CHECK: OpStore [[dst_7]] [[byte_7]] Aligned 1

typedef struct {
  int a;
  char b[5];
} T;

kernel void foo(global T *data, uint i, uint j, uint k) {
  global T *src = data + i;
  global T *dst = data + j;
  ulong w = *(global ulong *)&src[k];
  ushort s = *(global ushort *)&src[k].b[2];
  *(global ulong *)&dst[k] = w;
  *(global ushort *)&dst[k].b[2] = s;
}
