// RUN: clspv %s -o %t.spv -cl-arm-integer-dot-product -spv-version=1.6 -int8=0
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInput4x8BitPacked
// CHECK-DAG: [[int:%[^ ]+]] = OpTypeInt 32 0
// CHECK: OpLoad [[int]]
// CHECK: [[a:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[dot:%[^ ]+]] = OpSDot {{.*}} [[a]] [[b]] PackedVectorFormat4x8Bit
// CHECK: OpIAdd {{.*}} [[dot]]

void kernel foo(global int *out, global int *a, global int *b) {
    size_t gid = get_global_id(0);
    out[gid] = arm_dot_acc(as_char4(a[gid]), as_char4(b[gid]), out[gid]);
}
