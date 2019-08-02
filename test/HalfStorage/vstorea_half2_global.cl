// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global uint* A, float2 val, uint n) {
  vstorea_half2(val, n, (global half*) A);
  vstorea_half2_rte(val, n+1, (global half*) A);
  vstorea_half2_rtz(val, n+2, (global half*) A);
}

// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_32]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_34]]
// CHECK: OpStore [[_36]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_32]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_37]]
// CHECK: OpStore [[_39]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_34]] [[_uint_2]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_32]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_40]]
// CHECK: OpStore [[_42]] [[_41]]
