// RUN: clspv %s -o %t2.spv
// RUN: spirv-dis -o %t2.spvasm %t2.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

// CHECK-DAG: [[uint:%[0-9a-zA-Z_]*]] = OpTypeInt 32
// CHECK-DAG: [[uint_0:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[0-9a-zA-Z_]*]] = OpConstant [[uint]] 3
// CHECK-DAG: [[float:%[0-9a-zA-Z_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[0-9a-zA-Z_]*]] = OpTypeVector [[float]] 4
// CHECK: [[in_mul:%[0-9a-zA-Z_]*]] = OpIMul [[uint]] {{.*}} [[uint_3]]
// CHECK: [[load0_shift:%[0-9a-zA-Z_]*]] = OpShiftRightLogical [[uint]] [[in_mul]] [[uint_2]]
// CHECK: [[load0_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[load0_shift]]
// CHECK: [[load0:%[0-9a-zA-Z_]*]] = OpLoad [[float4]] [[load0_addr]]
// CHECK: [[load0_idx:%[0-9a-zA-Z_]*]] = OpBitwiseAnd [[uint]] [[in_mul]] [[uint_3]]
// CHECK: [[x0:%[0-9a-zA-Z_]*]] = OpVectorExtractDynamic [[float]] [[load0]] [[load0_idx]]
// CHECK: [[load1_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[uint]] [[in_mul]] [[uint_1]]
// CHECK: [[load1_shift:%[0-9a-zA-Z_]*]] = OpShiftRightLogical [[uint]] [[load1_offset]] [[uint_2]]
// CHECK: [[load1_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[load1_shift]]
// CHECK: [[load1:%[0-9a-zA-Z_]*]] = OpLoad [[float4]] [[load1_addr]]
// CHECK: [[load1_idx:%[0-9a-zA-Z_]*]] = OpBitwiseAnd [[uint]] [[load1_offset]] [[uint_3]]
// CHECK: [[x1:%[0-9a-zA-Z_]*]] = OpVectorExtractDynamic [[float]] [[load1]] [[load1_idx]]
// CHECK: [[load2_offset:%[0-9a-zA-Z_]*]] = OpIAdd [[uint]] [[in_mul]] [[uint_2]]
// CHECK: [[load2_shift:%[0-9a-zA-Z_]*]] = OpShiftRightLogical [[uint]] [[load2_offset]] [[uint_2]]
// CHECK: [[load2_addr:%[0-9a-zA-Z_]*]] = OpAccessChain {{.*}} [[uint_0]] [[load2_shift]]
// CHECK: [[load2:%[0-9a-zA-Z_]*]] = OpLoad [[float4]] [[load2_addr]]
// CHECK: [[load2_idx:%[0-9a-zA-Z_]*]] = OpBitwiseAnd [[uint]] [[load2_offset]] [[uint_3]]
// CHECK: [[x2:%[0-9a-zA-Z_]*]] = OpVectorExtractDynamic [[float]] [[load2]] [[load2_idx]]
// CHECK: [[x10:%[0-9a-zA-Z_]*]] = OpFAdd [[float]] [[x0]] [[x1]]
// CHECK: [[StoreVal:%[0-9a-zA-Z_]*]] = OpFAdd [[float]] [[x2]] [[x10]]
// CHECK: [[StoreAddr:%[0-9a-zA-Z_]*]] = OpAccessChain
// CHECK: OpStore [[StoreAddr]] [[StoreVal]]

kernel void test(global float *out, global float3 *in) {
  uint gid = get_global_id(0);
  float3 x = vload3(gid, (global float *)in);
  out[gid] = x[0] + x[1] + x[2];
}
