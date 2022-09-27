// Test the -hack-inserts option.
// Check that we can remove partial chains of insertvalue
// to avoid OpCompositeInsert entirely.

// RUN: clspv %target %s -o %t.spv -hack-inserts -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


typedef struct { float a, b, c, d; } S;

__attribute__((noinline))
S boo(float a) {
  S result = {0.0f}; // Produces const-aggregate-zero
  result.a = a;
  result.c = a+2.0f;
  result.b = a+1.0f;
  // Skip filling in result.d
  return result;
}


kernel void foo(global S* data, float f) {
  *data = boo(f);
}
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[__struct_2:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]] [[_float]] [[_float]] [[_float]]
// CHECK-DAG: [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK-DAG: [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK: [[_30:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[_float]]
// CHECK: [[_32:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_30]] [[_float_2]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpFAdd [[_float]] [[_30]] [[_float_1]]
// CHECK: [[_34:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_30]] [[_33]] [[_32]] [[_float_0]]
// CHECK: OpReturnValue [[_34]]
