// RUN: clspv %s -o %t.spv -cl-arm-integer-dot-product -spv-version=1.6
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInput4x8Bit{{$}}
// CHECK: [[char:%[^ ]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[^ ]+]] = OpTypeVector [[char]] 4
// CHECK: [[a:%[^ ]+]] = OpLoad [[char4]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[char4]]
// CHECK: OpSDot {{.*}} [[a]] [[b]]

void kernel foo(global int *out, global char4 *a, global char4 *b) {
    size_t gid = get_global_id(0);
    out[gid] = arm_dot(a[gid], b[gid]);
}
