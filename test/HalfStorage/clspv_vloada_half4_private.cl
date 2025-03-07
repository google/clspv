// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, uint2 v, uint2 w, uint n) {
  uint2 arr[2] = {v, w};
  A[0] = __clspv_vloada_half4(n, &arr[0]);
  A[1] = __clspv_vloada_half4(0, &v);
}
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: OpStore
// CHECK: OpStore
// CHECK-64: [[_convert_long:%[0-9a-zA-Z_]+]] = OpUConvert [[_ulong]]
// CHECK-64: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}} [[_convert_long]]
// CHECK-32: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} {{.*}}
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_48]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_49]] 0
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_49]] 1
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_50]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_51]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_52]] [[_53]] 0 1 2 3
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_uint_0]]
// CHECK: OpStore [[_39]] [[_54]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_57]] [[_58]] 0 1 2 3
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_60]] [[_59]]
