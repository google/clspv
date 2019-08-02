// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, global uint2* B, uint n) {
  A[0] = vloada_half4(n, (global half*)B);
  A[1] = vloada_half4(0, (global half*)B+2);
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_38]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_39]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 0
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_40]] 1
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_41]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_42]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_43]] [[_44]] 0 1 2 3
// CHECK: OpStore [[_36]] [[_45]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpSDiv [[_uint]] [[_uint_2]] [[_uint_4]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]] [[_46]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpLoad [[_v2uint]] [[_47]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_48]] 0
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_48]] 1
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_49]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_50]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_51]] [[_52]] 0 1 2 3
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_54]] [[_53]]
