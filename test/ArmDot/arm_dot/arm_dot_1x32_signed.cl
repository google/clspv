// RUN: clspv %s -o %t.spv -cl-arm-integer-dot-product -spv-version=1.6
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInput4x8Bit{{$}}
// CHECK-DAG: [[int:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char4:%[^ ]+]] = OpTypeVector [[char]] 4
// CHECK: OpLoad [[int]]
// CHECK: [[a:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[a_bitcast:%[^ ]+]] = OpBitcast [[char4]] [[a]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[b_bitcast:%[^ ]+]] = OpBitcast [[char4]] [[b]]
// CHECK: OpSDot {{.*}} [[a_bitcast]] [[b_bitcast]]

void kernel foo(global int *out, global int *a, global int *b) {
    size_t gid = get_global_id(0);
    out[gid] = arm_dot(as_char4(a[gid]), as_char4(b[gid]));
}
