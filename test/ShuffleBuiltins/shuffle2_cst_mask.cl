// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int2 *srcA, global int2 *srcB, global int2 *dst) {
    *dst = shuffle2(*srcA, *srcB, (uint2)(1, 2));
}

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK: [[srcA_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[srcB_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[dst_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[srcA:%[^ ]+]] = OpLoad [[v2uint]] [[srcA_addr]]
// CHECK: [[srcB:%[^ ]+]] = OpLoad [[v2uint]] [[srcB_addr]]
// CHECK: [[shuffle:%[^ ]+]] = OpVectorShuffle [[v2uint]] [[srcA]] [[srcB]] 1 2
// CHECK: OpStore [[dst_addr]] [[shuffle]]
