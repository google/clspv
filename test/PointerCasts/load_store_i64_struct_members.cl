// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -O0
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// SROA splits the copies into an i64 access to the first two members of T and
// an i32 access to the last one. As the size of T is not a multiple of the size
// of i64, the buffers are accessed as uint while keeping the stride of T.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK: [[gid:%[^ ]+]] = OpLoad [[uint]]
// CHECK: [[in_a_idx:%[^ ]+]] = OpIMul [[uint]] [[gid]] [[uint_3]]
// CHECK: [[in_a_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[in:%[^ ]+]] [[uint_0]] [[in_a_idx]]
// CHECK: [[a:%[^ ]+]] = OpLoad [[uint]] [[in_a_ptr]]
// CHECK: [[in_b_idx:%[^ ]+]] = OpIAdd [[uint]] [[uint_1]] [[in_a_idx]]
// CHECK: [[in_b_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[in]] [[uint_0]] [[in_b_idx]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[uint]] [[in_b_ptr]]
// CHECK: [[ab:%[^ ]+]] = OpCompositeConstruct {{%[^ ]+}} [[a]] [[b]]
// CHECK: [[word:%[^ ]+]] = OpBitcast [[ulong]] [[ab]]
// CHECK: [[in_c_mul:%[^ ]+]] = OpIMul [[uint]] [[gid]] [[uint_3]]
// CHECK: [[in_c_idx:%[^ ]+]] = OpIAdd [[uint]] [[in_c_mul]] [[uint_2]]
// CHECK: [[in_c_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[in]] [[uint_0]] [[in_c_idx]]
// CHECK: [[c:%[^ ]+]] = OpLoad [[uint]] [[in_c_ptr]]
// CHECK: [[add:%[^ ]+]] = OpIAdd [[ulong]] [[word]]
// CHECK: [[out_a_idx:%[^ ]+]] = OpIMul [[uint]] [[gid]] [[uint_3]]
// CHECK: [[split:%[^ ]+]] = OpBitcast {{%[^ ]+}} [[add]]
// CHECK: [[new_a:%[^ ]+]] = OpCompositeExtract [[uint]] [[split]] 0
// CHECK: [[new_b:%[^ ]+]] = OpCompositeExtract [[uint]] [[split]] 1
// CHECK: [[out_a_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out:%[^ ]+]] [[uint_0]] [[out_a_idx]]
// CHECK: OpStore [[out_a_ptr]] [[new_a]]
// CHECK: [[out_b_idx:%[^ ]+]] = OpIAdd [[uint]] [[uint_1]] [[out_a_idx]]
// CHECK: [[out_b_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out]] [[uint_0]] [[out_b_idx]]
// CHECK: OpStore [[out_b_ptr]] [[new_b]]
// CHECK: [[out_c_mul:%[^ ]+]] = OpIMul [[uint]] [[gid]] [[uint_3]]
// CHECK: [[out_c_idx:%[^ ]+]] = OpIAdd [[uint]] [[out_c_mul]] [[uint_2]]
// CHECK: [[out_c_ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[out]] [[uint_0]] [[out_c_idx]]
// CHECK: OpStore [[out_c_ptr]] [[c]]

typedef struct {
  uint a, b, c;
} T;

kernel void foo(global const T *in, global T *out) {
  size_t gid = get_global_id(0);
  T v = in[gid];
  ulong words[2] = {0, 0};
  __builtin_memcpy(words, &v, sizeof(T));
  words[0] += 1;
  __builtin_memcpy(&v, words, sizeof(T));
  out[gid] = v;
}
