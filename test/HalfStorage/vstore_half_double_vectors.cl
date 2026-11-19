// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-16,VEC3 --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -no-16bit-storage=ssbo -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-NO16,VEC3 --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -vec3-to-vec4 -o %t.novec3.spv
// RUN: spirv-dis -o %t.novec3.spvasm %t.novec3.spv
// RUN: FileCheck %s < %t.novec3.spvasm --check-prefixes=CHECK,CHECK-16,NOVEC3 --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.novec3.spv

kernel void test_vectors(global double2 *d2, global double3 *d3,
                         global double4 *d4, uint n, global int *out_raw) {
  global half *out = (global half *)out_raw;

  vstore_half2(*d2, n, out);
  vstore_half3_rte(*d3, n + 1u, out);
  vstore_half4_rtz(*d4, n + 2u, out);
  vstorea_half2_rtp(*d2, n + 3u, out);
  vstorea_half3_rtn(*d3, n + 4u, out);
  vstorea_half4(*d4, n + 5u, out);
}

// CHECK-DAG: OpCapability Float64
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[double:%[^ ]+]] = OpTypeFloat 64
// VEC3: OpTypeVector [[double]] 3
// NOVEC3-NOT: OpTypeVector [[double]] 3
// CHECK-16: [[ushort:%[^ ]+]] = OpTypeInt 16 0
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK-COUNT-2: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK: OpExtInst [[uint]] {{.*}} PackHalf2x16
// CHECK-16: OpUConvert [[ushort]]
// CHECK-NO16: OpAtomicXor [[uint]]
// CHECK-COUNT-2: OpExtInst [[uint]] {{.*}} PackHalf2x16
