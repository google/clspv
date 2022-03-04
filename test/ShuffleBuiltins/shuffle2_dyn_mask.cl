// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int2 *srcA, global int2 *srcB, global uint2 *mask, global int2 *dst) {
    *dst = shuffle2(*srcA, *srcB, *mask);
}

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_4:%[^ ]+]] = OpConstant [[uint]] 4

// CHECK: [[srcA_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[srcB_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[mask_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[dst_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[srcA:%[^ ]+]] = OpLoad [[v2uint]] [[srcA_addr]]
// CHECK: [[srcB:%[^ ]+]] = OpLoad [[v2uint]] [[srcB_addr]]
// CHECK: [[mask:%[^ ]+]] = OpLoad [[v2uint]] [[mask_addr]]
// CHECK: [[dst:%[^ ]+]] = OpUndef [[v2uint]]

// CHECK: [[mask0:%[^ ]+]] = OpCompositeExtract [[uint]] [[mask]] 0
// CHECK: [[mask0Mod:%[^ ]+]] = OpUMod [[uint]] [[mask0]] [[uint_2]]
// CHECK: [[srcA0:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[srcA]] [[mask0Mod]]
// CHECK: [[srcB0:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[srcB]] [[mask0Mod]]
// CHECK: [[mask0Mod2:%[^ ]+]] = OpUMod [[uint]] [[mask0]] [[uint_4]]
// CHECK: [[cmp0:%[^ ]+]] = OpUGreaterThanEqual [[bool]] [[mask0Mod2]] [[uint_2]]
// CHECK: [[src0:%[^ ]+]] = OpSelect [[uint]] [[cmp0]] [[srcB0]] [[srcA0]]
// CHECK: [[dst0:%[^ ]+]] = OpCompositeInsert [[v2uint]] [[src0]] [[dst]] 0

// CHECK: [[mask1:%[^ ]+]] = OpCompositeExtract [[uint]] [[mask]] 1
// CHECK: [[mask1Mod:%[^ ]+]] = OpUMod [[uint]] [[mask1]] [[uint_2]]
// CHECK: [[srcA1:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[srcA]] [[mask1Mod]]
// CHECK: [[srcB1:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[srcB]] [[mask1Mod]]
// CHECK: [[mask1Mod2:%[^ ]+]] = OpUMod [[uint]] [[mask1]] [[uint_4]]
// CHECK: [[cmp1:%[^ ]+]] = OpUGreaterThanEqual [[bool]] [[mask1Mod2]] [[uint_2]]
// CHECK: [[src1:%[^ ]+]] = OpSelect [[uint]] [[cmp1]] [[srcB1]] [[srcA1]]
// CHECK: [[dst1:%[^ ]+]] = OpCompositeInsert [[v2uint]] [[src1]] [[dst0]] 1

// CHECK: OpStore [[dst_addr]] [[dst1]]
