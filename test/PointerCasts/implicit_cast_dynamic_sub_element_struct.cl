// RUN: clspv %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// p points to data[i], so clspv types it as a pointer to T. The accesses
// through p are at dynamic byte offsets that are not multiples of the size of
// T, so they cannot be expressed as indices of T without keeping the
// remainder:
// - ulong_store: v is stored at byte 12 * i + 8 * j, as two uints. Indexing T
//   with j instead of 8 * j / 12 stored it at byte 12 * i + 12 * j.
// - char_store: c is stored at byte 12 * i + 12 * j + 8, i.e. to
//   data[i + j].b[4]. Dropping the remainder 8 stored it to data[i + j].a.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_8:%[^ ]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[uint_12:%[^ ]+]] = OpConstant [[uint]] 12
// CHECK-DAG: [[ulong_1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-DAG: [[ulong_3:%[^ ]+]] = OpConstant [[ulong]] 3
// CHECK-DAG: [[ulong_12:%[^ ]+]] = OpConstant [[ulong]] 12

// ulong_store: uint indices 3 * i + 2 * j and 3 * i + 2 * j + 1.
// CHECK: = OpFunction
// CHECK: [[i:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK: [[i3:%[^ ]+]] = OpIMul [[ulong]] [[i]] [[ulong_3]]
// CHECK: [[j:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK: [[j2:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[j]] [[ulong_1]]
// CHECK: [[lo_idx:%[^ ]+]] = OpIAdd [[ulong]] [[i3]] [[j2]]
// CHECK: [[lo_ptr:%[^ ]+]] = Op{{(Ptr)?}}AccessChain {{.*}} [[lo_idx]]
// CHECK: OpStore [[lo_ptr]]
// CHECK: [[j2_1:%[^ ]+]] = OpBitwiseOr [[ulong]] [[j2]] [[ulong_1]]
// CHECK: [[hi_idx:%[^ ]+]] = OpIAdd [[ulong]] [[i3]] [[j2_1]]
// CHECK: [[hi_ptr:%[^ ]+]] = Op{{(Ptr)?}}AccessChain {{.*}} [[hi_idx]]
// CHECK: OpStore [[hi_ptr]]

// char_store: byte index 12 * i + (12 * j + 8).
// CHECK: = OpFunction
// CHECK: [[i:%[^ ]+]] = OpSConvert [[ulong]]
// CHECK: [[i12:%[^ ]+]] = OpIMul [[ulong]] [[i]] [[ulong_12]]
// CHECK: [[j12:%[^ ]+]] = OpIMul [[uint]] {{%[^ ]+}} [[uint_12]]
// CHECK: [[j12_8:%[^ ]+]] = OpIAdd [[uint]] [[j12]] [[uint_8]]
// CHECK: [[off:%[^ ]+]] = OpSConvert [[ulong]] [[j12_8]]
// CHECK: [[idx:%[^ ]+]] = OpIAdd [[ulong]] [[i12]] [[off]]
// CHECK: [[ptr:%[^ ]+]] = Op{{(Ptr)?}}AccessChain {{.*}} [[idx]]
// CHECK: OpStore [[ptr]] {{%[^ ]+}} Aligned 1

typedef struct {
  int a;
  char b[5];
} T;

kernel void ulong_store(global T *data, int i, int j, ulong v) {
  global char *p = (global char *)&data[i];
  *(global ulong *)(p + 8 * j) = v;
}

kernel void char_store(global T *data, int i, int j, char c) {
  global char *p = (global char *)&data[i];
  p[12 * j + 8] = c;
}
