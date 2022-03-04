// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int2 *src, global uint2 *mask, global int2 *dst) {
    *dst = shuffle(*src, *mask);
}

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK: [[uint_2:%[^ ]+]] = OpConstant [[uint]] 2

// CHECK: [[src_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[mask_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[dst_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[src:%[^ ]+]] = OpLoad [[v2uint]] [[src_addr]]
// CHECK: [[mask:%[^ ]+]] = OpLoad [[v2uint]] [[mask_addr]]
// CHECK: [[dst:%[^ ]+]] = OpUndef [[v2uint]]

// CHECK: [[mask0:%[^ ]+]] = OpCompositeExtract [[uint]] [[mask]] 0
// CHECK: [[mask0mod:%[^ ]+]] = OpUMod [[uint]] [[mask0]] [[uint_2]]
// CHECK: [[src0:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[src]] [[mask0mod]]
// CHECK: [[dst0:%[^ ]+]] = OpCompositeInsert [[v2uint]] [[src0]] [[dst]] 0

// CHECK: [[mask1:%[^ ]+]] = OpCompositeExtract [[uint]] [[mask]] 1
// CHECK: [[mask1mod:%[^ ]+]] = OpUMod [[uint]] [[mask1]] [[uint_2]]
// CHECK: [[src1:%[^ ]+]] = OpVectorExtractDynamic [[uint]] [[src]] [[mask1mod]]
// CHECK: [[dst1:%[^ ]+]] = OpCompositeInsert [[v2uint]] [[src1]] [[dst0]] 1

// CHECK: OpStore [[dst_addr]] [[dst1]]
