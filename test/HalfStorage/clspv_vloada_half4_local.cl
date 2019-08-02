// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global float4* A, local float4* B, uint n) {
  A[0] = __clspv_vloada_half4(n, (local uint2*)B);
  A[1] = __clspv_vloada_half4(0, (local uint2*)B);
}
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_v2uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 2
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_27:%[0-9a-zA-Z_]+]] = OpUndef [[_v4float]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_39:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK: [[_40:%[0-9a-zA-Z_]+]] = OpShiftRightLogical [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B:%[0-9a-zA-Z_]+]] [[_40]]
// CHECK: [[_42:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_41]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpBitwiseAnd [[_uint]] [[_39]] [[_uint_1]]
// CHECK: [[_44:%[0-9a-zA-Z_]+]] = OpShiftLeftLogical [[_uint]] [[_43]] [[_uint_1]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_42]] [[_44]]
// CHECK: [[_47:%[0-9a-zA-Z_]+]] = OpIAdd [[_uint]] [[_44]] [[_uint_1]]
// CHECK: [[_48:%[0-9a-zA-Z_]+]] = OpVectorExtractDynamic [[_float]] [[_42]] [[_47]]
// CHECK: [[construct:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[_v2float]] [[_45]] [[_48]]
// CHECK: [[_50:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[construct]]
// CHECK: [[_51:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_50]] 0
// CHECK: [[_52:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_50]] 1
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_51]]
// CHECK: [[_54:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_52]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_53]] [[_54]] 0 1 2 3
// CHECK: OpStore [[_37]] [[_55]]
// CHECK: [[_56:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]]
// CHECK: [[_57:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_56]]
// CHECK: [[_58:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v2float]] [[_57]] [[_27]] 0 1
// CHECK: [[_59:%[0-9a-zA-Z_]+]] = OpBitcast [[_v2uint]] [[_58]]
// CHECK: [[_60:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_59]] 0
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_59]] 1
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_60]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[_61]]
// CHECK: [[_64:%[0-9a-zA-Z_]+]] = OpVectorShuffle [[_v4float]] [[_62]] [[_63]] 0 1 2 3
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A]] [[_uint_0]] [[_uint_1]]
// CHECK: OpStore [[_65]] [[_64]]
