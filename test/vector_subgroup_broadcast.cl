// RUN: clspv %s -o %t.spv --spv-version=1.3
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.3

// CHECK: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK: [[load:%[^ ]+]] = OpLoad [[float4]]
// CHECK: OpGroupNonUniformBroadcast [[float4]] {{.*}} [[load]]

kernel void foo(global float4 *buffer) {
    sub_group_broadcast(*buffer, 0u);
}
