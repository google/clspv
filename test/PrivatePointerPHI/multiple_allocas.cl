// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// SROA splits r into one alloca per element, and the store in the loop uses a
// PHI of pointers to either of them.

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[array:%[^ ]+]] = OpTypeArray [[uint]] [[uint_2]]
// CHECK-DAG: [[ptr_array:%[^ ]+]] = OpTypePointer Function [[array]]
// CHECK: [[r:%[^ ]+]] = OpVariable [[ptr_array]] Function
// CHECK: [[idx:%[^ ]+]] = OpPhi [[uint]] %uint_0 {{%[^ ]+}} %uint_1 {{%[^ ]+}}
// CHECK: [[ptr:%[^ ]+]] = OpAccessChain {{%[^ ]+}} [[r]] [[idx]]
// CHECK: OpStore [[ptr]]

kernel void foo(global const int *in, global int *out) {
  size_t gid = get_global_id(0);
  int r[2];
  for (int i = 0; i < 2; ++i) {
    barrier(CLK_GLOBAL_MEM_FENCE);
    r[i] = in[2 * gid + (size_t)i];
  }
  out[gid] = r[0] - r[1];
}
