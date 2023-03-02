// RUN: clspv %target %s -o %t.spv -hack-inserts -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { float a, b, c, d; } S;

S boo(S in) {
  in.a = 0.0f;
  in.c = 2.0f;
  in.b = 1.0f;
  in.d = 3.0f;
  return in;
}


kernel void foo(global S* data, float f) {
  data[0] = boo(data[1]);
}

// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK-DAG:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK-DAG:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK-DAG:  [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK-DAG:  OpStore {{.*}} [[_float_0]]
// CHECK-DAG:  OpStore {{.*}} [[_float_1]]
// CHECK-DAG:  OpStore {{.*}} [[_float_2]]
// CHECK-DAG:  OpStore {{.*}} [[_float_3]]
