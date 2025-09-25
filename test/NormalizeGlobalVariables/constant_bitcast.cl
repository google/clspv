// b/445660270 https://github.com/google/clspv/issues/1524
// XFAIL: *
// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

#define X 4 //33
#define Y 17 //33

__constant int data[X][Y] = {
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
    {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,},
    };

kernel void foo(global int* in, global int* out, int x, int y) {
  *out = *in + data[x][y];
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 4
// CHECK-DAG: [[int17:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 17
// CHECK-DAG: [[int1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK-DAG: [[array17:%[a-zA-Z0-9_]+]] = OpTypeArray [[int]] [[int17]]
// CHECK-DAG: [[array4:%[a-zA-Z0-9_]+]] = OpTypeArray [[array17]] [[int4]]
// CHECK: [[c0:%[a-zA-Z0-9_]+]] = OpConstantComposite [[array17]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]]
// CHECK: [[c1:%[a-zA-Z0-9_]+]] = OpConstantComposite [[array17]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int0]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]]
// CHECK: [[c2:%[a-zA-Z0-9_]+]] = OpConstantNull [[array17]]
// CHECK: [[c3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[array17]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]] [[int1]]
// CHECK: [[c:%[a-zA-Z0-9_]+]] = OpConstantComposite [[array4]]
// CHECK: OpVariable {{.*}} Private [[c]]
