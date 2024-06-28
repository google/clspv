// RUN: clspv %target %s -o %t2.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t2.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// RUN: clspv %target %s -o %t2.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t2.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// CHECK-DAG: [[uint:%[0-9a-zA-Z_]*]] = OpTypeInt 32
// CHECK-64-DAG: [[ulong:%[0-9a-zA-Z_]*]] = OpTypeInt 64
// CHECK-DAG: [[uint_0:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 1{{$}}
// CHECK-DAG: [[uint_2:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint_12:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 12
// CHECK-64-DAG: [[ulong_1:%[0-9a-zA-Z_]*]] = OpConstant [[ulong]] 1{{$}}
// CHECK-64-DAG: [[ulong_2:%[0-9a-zA-Z_]*]] = OpConstant [[ulong]] 2
// CHECK-64-DAG: [[ulong_12:%[0-9a-zA-Z_]*]] = OpConstant [[ulong]] 12
// CHECK-DAG: [[float:%[0-9a-zA-Z_]*]] = OpTypeFloat 32
// CHECK-32: [[in_mulx4:%[0-9a-zA-Z_]*]] = OpIMul [[uint]] {{.*}} [[uint_12]]
// CHECK-32: [[in_mul:%[0-9a-zA-Z_]*]] = OpShiftRightLogical [[uint]] [[in_mulx4]] [[uint_2]]
// CHECK-64: [[in_mulx4:%[0-9a-zA-Z_]*]] = OpIMul [[ulong]] {{.*}} [[ulong_12]]
// CHECK-64: [[in_mul:%[0-9a-zA-Z_]*]] = OpShiftRightLogical [[ulong]] [[in_mulx4]] [[ulong_2]]
// CHECK: [[load0_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[in_mul]]
// CHECK: [[x0:%[0-9a-zA-Z_]*]] = OpLoad [[float]] [[load0_addr]]
// CHECK-32: [[load1_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[uint]] [[in_mul]] [[uint_1]]
// CHECK-64: [[load1_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[ulong]] [[in_mul]] [[ulong_1]]
// CHECK: [[load1_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[load1_offset]]
// CHECK: [[x1:%[0-9a-zA-Z_]*]] = OpLoad [[float]] [[load1_addr]]
// CHECK-32: [[load2_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[uint]] [[in_mul]] [[uint_2]]
// CHECK-64: [[load2_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[ulong]] [[in_mul]] [[ulong_2]]
// CHECK: [[load2_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[load2_offset]]
// CHECK: [[x2:%[0-9a-zA-Z_]*]] = OpLoad [[float]] [[load2_addr]]
// CHECK: [[x10:%[0-9a-zA-Z_]*]] = OpFAdd [[float]] [[x0]] [[x1]]
// CHECK: [[StoreVal:%[0-9a-zA-Z_]*]] = OpFAdd [[float]] [[x10]] [[x2]]
// CHECK: [[StoreAddr:%[0-9a-zA-Z_]*]] = OpAccessChain
// CHECK: OpStore [[StoreAddr]] [[StoreVal]]

kernel void test(global float *out, global float3 *in) {
  uint gid = get_global_id(0);
  float3 x = vload3(gid, (global float *)in);
  out[gid] = x[0] + x[1] + x[2];
}
