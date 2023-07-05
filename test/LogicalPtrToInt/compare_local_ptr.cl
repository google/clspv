// RUN: clspv %s -o %t.spv
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: spirv-dis %t.spv -o %t.spvasm

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK: OpStore {{.*}} [[uint0]]

void kernel foo(global uint *a, local uint *b) {
    *a = (b == NULL);
}
