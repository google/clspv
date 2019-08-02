// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// The __clspv_vloada_half4 is like vloada_half4 but the pointer argument
// is pointer to uint2.

kernel void foo(global float4* A, global float4* B, uint n) {
  // Demonstrate fully general indexing.
  A[0] = __clspv_vloada_half4(n, (global uint2*)B);
  // The zero case optimizes quite nicely.
  A[1] = __clspv_vloada_half4(0, (global uint2*)B);
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_21:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_36:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_35]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_36]]
// CHECK: [[_38:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_34]] [[_uint_1]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_38]] [[_uint_1]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_37]] [[_39]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_37]] [[_42]]
// CHECK: [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_40]] [[_43]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[construct]]
// CHECK: [[_46:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_45]] 0
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_45]] 1
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_46]]
// CHECK: [[_49:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_47]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_48]] [[_49]] 0 1 2 3
// CHECK: OpStore [[_32]] [[_50]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_51]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_52]] [[_21]] 0 1
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_53]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_54]] 0
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_54]] 1
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_55]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_56]]
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_57]] [[_58]] 0 1 2 3
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_60]] [[_59]]
