// RUN: clspv %s -o %t.spv -spv-version=1.6 --enable-feature-macros=__opencl_c_integer_dot_product_input_4x8bit -cl-std=CL3.0
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInput4x8Bit{{$}}
// CHECK: [[char:%[^ ]+]] = OpTypeInt 8 0
// CHECK: [[char4:%[^ ]+]] = OpTypeVector [[char]] 4
// CHECK: [[a:%[^ ]+]] = OpLoad [[char4]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[char4]]
// CHECK: OpSUDot {{.*}} [[a]] [[b]]

void kernel foo(global int *out, global char4 *a, global uchar4 *b) {
    size_t gid = get_global_id(0);
    out[gid] = dot(a[gid], b[gid]);
}
