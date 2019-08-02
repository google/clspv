// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global uint2* A, float4 val, uint n) {
  vstorea_half4(val, n, ((global half*) A)+4);
  vstorea_half4_rte(val, n+1, ((global half*) A)+8);
  vstorea_half4_rte(val, n+2, ((global half*) A)+12);
}


// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_38]] [[_22]] 0 1
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_38]] [[_22]] 2 3
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_41]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[construct1:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_43]] [[_44]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_1]] [[_40]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_47]]
// CHECK: OpStore [[_48]] [[construct1]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_40]] [[_uint_1]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_41]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[construct2:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_50]] [[_51]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_2]] [[_49]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_54]]
// CHECK: OpStore [[_55]] [[construct2]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_40]] [[_uint_2]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_41]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_uint]] {{.*}} PackHalf2x16 [[_42]]
// CHECK: [[construct3:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2uint]] [[_57]] [[_58]]
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_uint_3]] [[_56]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_61]]
// CHECK: OpStore [[_62]] [[construct3]]
