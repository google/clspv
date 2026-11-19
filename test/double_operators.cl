// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,VEC3 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -vec3-to-vec4 %s -o %t.novec3.spv
// RUN: spirv-dis -o %t3.spvasm %t.novec3.spv
// RUN: FileCheck %s < %t3.spvasm
// RUN: FileCheck %s --check-prefix=NOVEC3 < %t3.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.novec3.spv

// CHECK-DAG: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[v4double:%[a-zA-Z0-9_]+]] = OpTypeVector [[double]] 4
// CHECK-DAG: [[v4bool:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// VEC3-DAG: [[v3double:%[a-zA-Z0-9_]+]] = OpTypeVector [[double]] 3
// CHECK-DAG: OpFAdd [[double]]
// CHECK-DAG: OpFSub [[double]]
// CHECK-DAG: OpFMul [[double]]
// CHECK-DAG: OpFDiv [[double]]
// CHECK-DAG: OpFNegate [[double]]
// CHECK-DAG: OpFOrdEqual [[bool]]
// CHECK-DAG: OpFUnordNotEqual [[bool]]
// CHECK-DAG: OpFOrdLessThan [[bool]]
// CHECK-DAG: OpFOrdLessThanEqual [[bool]]
// CHECK-DAG: OpFOrdGreaterThan [[bool]]
// CHECK-DAG: OpFOrdGreaterThanEqual [[bool]]
// CHECK-DAG: OpSelect [[double]]
// CHECK-DAG: OpFAdd [[v4double]]
// CHECK-DAG: OpFOrdLessThan [[v4bool]]
// VEC3-DAG: OpFAdd [[v3double]]

// NOVEC3: [[novec3_double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// NOVEC3-NOT: OpTypeVector [[novec3_double]] 3
// NOVEC3: [[novec3_v4double:%[a-zA-Z0-9_]+]] = OpTypeVector [[novec3_double]] 4
// NOVEC3-NOT: OpTypeVector [[novec3_double]] 3
// NOVEC3-COUNT-2: OpFAdd [[novec3_v4double]]

kernel void test_scalar(global double *out, global int *cmp, double a,
                        double b, double c) {
  out[0] = a + b;
  out[1] = a - b;
  out[2] = a * b;
  out[3] = a / b;
  out[4] = -a;
  out[5] = (a > c) ? a : c;
  cmp[0] = (a == b);
  cmp[1] = (a != c);
  cmp[2] = (a < b);
  cmp[3] = (b <= c);
  cmp[4] = (b > c);
  cmp[5] = (a >= c);
}

kernel void test_vectors(global double2 *o2, global double3 *o3,
                         global double4 *o4, global long4 *cmp4, double2 a2,
                         double3 a3, double4 a4, double4 b4) {
  *o2 = a2 * 2.0 - a2;
  *o3 = a3 + 1.0;
  *o4 = (a4 + b4) / (a4 - b4);
  *cmp4 = (a4 < b4);
}
