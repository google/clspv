// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint2* A, float4 val, uint n) {
  uint2 arr[64];
  half* cast = (private half*) arr;
  vstorea_half4(val, n, cast+4);
  vstorea_half4_rte(val, n+1, cast+8);
  vstorea_half4_rtz(val, n+2, cast+12);
  *A = *(uint2*) arr;
}
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_27:%[0-9a-zA-Z_]+]] = OpConstantNull
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[arr:%[0-9a-zA-Z_]+]] [[_uint_0]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_45]] [[_26]] 0 1
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_45]] [[_26]] 2 3
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_49]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_50]]
// CHECK: [[construct1:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_51]] [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_1]] [[_47]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[arr]] [[_55]]
// CHECK: OpStore [[_56]] [[construct1]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_47]] [[_uint_1]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_49]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_50]]
// CHECK: [[construct2:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_58]] [[_59]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_2]] [[_57]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[arr]] [[_62]]
// CHECK: OpStore [[_63]] [[construct2]]
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_47]] [[_uint_2]]
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_49]]
// CHECK: [[_66:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_50]]
// CHECK: [[construct3:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_65]] [[_66]]
// CHECK: [[_69:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_3]] [[_64]]
// CHECK: [[_70:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[arr]] [[_69]]
// CHECK: OpStore [[_70]] [[construct3]]
// CHECK: [[_71:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_48]]
