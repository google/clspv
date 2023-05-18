// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(local uint* A, float2 val, uint n) {
  vstorea_half2(val, n, (local half*) A);
  vstorea_half2_rte(val, n+1, (local half*) A);
  vstorea_half2_rtz(val, n+2, (local half*) A);
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2

// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK-64: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] {{.*}}
// CHECK-32: [[_38:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] {{.*}}
// CHECK: OpStore [[_38]] [[_37]]

// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK-64: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]]
// CHECK-32: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]]
// CHECK: OpStore [[_41]] [[_40]]

// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_34]]
// CHECK-64: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]]
// CHECK-32: [[_44:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]]
// CHECK: OpStore [[_44]] [[_43]]
