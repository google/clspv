// RUN: clspv %s -o %t.spv -cl-arm-integer-dot-product -spv-version=1.6
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInputAll
// CHECK: [[short:%[^ ]+]] = OpTypeInt 16 0
// CHECK: [[short2:%[^ ]+]] = OpTypeVector [[short]] 2
// CHECK: [[a:%[^ ]+]] = OpLoad [[short2]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[short2]]
// CHECK: [[dot:%[^ ]+]] = OpSDot {{.*}} [[a]] [[b]]
// CHECK: OpIAdd {{.*}} [[dot]]

void kernel foo(global int *out, global short2 *a, global short2 *b) {
    size_t gid = get_global_id(0);
    out[gid] = arm_dot_acc(a[gid], b[gid], out[gid]);
}
