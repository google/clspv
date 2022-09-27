// RUN: clspv %target %s -o %t
// RUN: spirv-dis %t -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t

kernel void foo(global int* in, global int* out) {
  local int scratch[32];
  int gid = get_global_id(0);
  scratch[gid] = in[gid];
  work_group_barrier(CLK_LOCAL_MEM_FENCE);
  out[gid] = scratch[gid];
}

//     CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_264:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 264
//     CHECK: OpControlBarrier [[uint_2]] [[uint_2]] [[uint_264]]
