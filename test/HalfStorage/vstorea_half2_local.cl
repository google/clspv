// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(local uint* A, float2 val, uint n) {
  vstorea_half2(val, n, (local half*) A);
  vstorea_half2_rte(val, n+1, (local half*) A);
  vstorea_half2_rtz(val, n+2, (local half*) A);
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_v2float]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_36]]
// CHECK: OpStore [[_38]] [[_37]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_1]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_39]]
// CHECK: OpStore [[_41]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_36]] [[_uint_2]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_42]]
// CHECK: OpStore [[_44]] [[_43]]
