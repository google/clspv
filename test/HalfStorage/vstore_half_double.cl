// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-16 --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -no-16bit-storage=ssbo -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-NO16 --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -O0 -o %t.o0.spv
// RUN: spirv-val --target-env vulkan1.0 %t.o0.spv

kernel void test_scalar(global int *out_raw, local int *loc_raw, double v,
                        uint n) {
  int priv_raw[4] = {0, 0, 0, 0};
  global half *g = (global half *)out_raw;
  local half *l = (local half *)loc_raw;
  private half *p = (private half *)priv_raw;

  vstore_half(v, n, g);
  vstore_half_rte(v, n + 1u, g);
  vstore_half_rtz(v, n + 2u, g);
  vstore_half_rtp(v, n + 3u, l);
  vstore_half_rtn(v, n + 4u, p);
  out_raw[10] = loc_raw[0] + priv_raw[0];
}

// CHECK-DAG: OpCapability Float64
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-16-COUNT-5: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-NO16: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK-NO16: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK-NO16: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK-NO16: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-NO16: OpExtInst [[uint]] {{.*}} PackHalf2x16
