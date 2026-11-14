// RUN: clspv %target -hack-scf %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s --implicit-check-not=OpSGreaterThan --implicit-check-not=OpSLessThan --implicit-check-not=SMin --implicit-check-not=SMax --implicit-check-not=SClamp < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[uchar_sign:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 128
// CHECK-DAG: %[[bool:[0-9a-zA-Z_]+]] = OpTypeBool
// CHECK-DAG: %[[ulong_sign:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 9223372036854775808
// CHECK-DAG: %[[uint_sign:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2147483648
// CHECK-DAG: %[[v4uint_sign:[0-9a-zA-Z_]+]] = OpConstantComposite %[[v4uint]] %[[uint_sign]] %[[uint_sign]] %[[uint_sign]] %[[uint_sign]]
// CHECK-DAG: %[[v4bool:[0-9a-zA-Z_]+]] = OpTypeVector %[[bool]] 4
// CHECK: OpBitwiseXor %[[uchar]] {{.*}} %[[uchar_sign]]
// CHECK: OpBitwiseXor %[[uchar]] {{.*}} %[[uchar_sign]]
// CHECK: OpUGreaterThan %[[bool]]
// CHECK: OpBitwiseXor %[[ulong]] {{.*}} %[[ulong_sign]]
// CHECK: OpBitwiseXor %[[ulong]] {{.*}} %[[ulong_sign]]
// CHECK: OpULessThan %[[bool]]
// CHECK: OpBitwiseXor %[[v4uint]] {{.*}} %[[v4uint_sign]]
// CHECK: OpBitwiseXor %[[v4uint]] {{.*}} %[[v4uint_sign]]
// CHECK: OpULessThan %[[v4bool]]
// CHECK: OpBitwiseXor %[[v4uint]] {{.*}} %[[v4uint_sign]]
// CHECK: OpBitwiseXor %[[v4uint]] {{.*}} %[[v4uint_sign]]
// CHECK: OpULessThan %[[v4bool]]

kernel void foo(global uchar *uc, global char *c1, global char *c2,
                global long *l1, global long *l2,
                global int4 *v4, global int4 *v4_lo, global int4 *v4_hi) {
  *uc = abs_diff(*c1, *c2);
  *l1 = max(*l1, *l2);
  *v4 = clamp(*v4, *v4_lo, *v4_hi);
}
