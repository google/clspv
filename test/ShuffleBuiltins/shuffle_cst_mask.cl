// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int2 *src, global int2 *dst) {
    *dst = shuffle(*src, (uint2)(1, 0));
}

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0

// CHECK: [[src_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[dst_addr:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK: [[src:%[^ ]+]] = OpLoad [[v2uint]] [[src_addr]]
// CHECK: [[shuffle:%[^ ]+]] = OpVectorShuffle [[v2uint]] [[src]] [[src]] 1 0
// CHECK: OpStore [[dst_addr]] [[shuffle]]
