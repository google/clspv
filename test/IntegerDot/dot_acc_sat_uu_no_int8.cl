// RUN: clspv %s -o %t.spv -spv-version=1.6 --enable-feature-macros=__opencl_c_integer_dot_product_input_4x8bit -cl-std=CL3.0 -int8=0
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG: OpCapability DotProduct{{$}}
// CHECK-DAG: OpCapability DotProductInput4x8BitPacked
// CHECK-DAG: [[int:%[^ ]+]] = OpTypeInt 32 0
// CHECK: OpLoad [[int]]
// CHECK: OpLoad [[int]]
// CHECK: [[a:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[int]]
// CHECK: [[acc:%[^ ]+]] = OpLoad [[int]]
// CHECK: OpUDotAccSat {{.*}} [[a]] [[b]] [[acc]] PackedVectorFormat4x8Bit

void kernel foo(global int *out, global uchar4 *a, global uchar4 *b) {
    size_t gid = get_global_id(0);
    out[gid] = dot_acc_sat(a[gid], b[gid], out[gid]);
}
