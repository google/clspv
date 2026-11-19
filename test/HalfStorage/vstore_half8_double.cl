// RUN: clspv %target %s --long-vector -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void test(global half *a, double8 b, uint c) {
  vstore_half8(b, c, a);
  vstorea_half8_rtz(b, c + 1u, a);
}

// CHECK-DAG: OpCapability Float64
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-COUNT-4: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: OpCompositeConstruct [[uint4]]
// CHECK-COUNT-4: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: OpCompositeConstruct [[uint4]]
