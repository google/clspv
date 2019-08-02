// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(local uint2* A, float4 val, uint n) {
  vstorea_half4(val, n, ((local half*) A)+4);
  vstorea_half4_rte(val, n+1, ((local half*) A)+8);
  vstorea_half4_rte(val, n+2, ((local half*) A)+12);
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK-DAG: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_39]] [[_24]] 0 1
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_39]] [[_24]] 2 3
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_43]]
// CHECK: [[construct1:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_44]] [[_45]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_1]] [[_41]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_48]]
// CHECK: OpStore [[_49]] [[construct1]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_1]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_43]]
// CHECK: [[construct2:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_51]] [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_2]] [[_50]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_55]]
// CHECK: OpStore [[_56]] [[construct2]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_41]] [[_uint_2]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_43]]
// CHECK: [[construct3:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_58]] [[_59]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_3]] [[_57]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_62]]
// CHECK: OpStore [[_63]] [[construct3]]
