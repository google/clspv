// Test the -hack-inserts option.
// Check that we can remove partial chains of insertvalue
// to avoid OpCompositeInsert entirely.

// RUN: clspv %target %s -o %t.spv -hack-inserts -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { float a, b, c, d; } S;

__attribute__((noinline))
S boo(S in) {
  in.c = 2.0f;
  in.b = 1.0f;
  return in;
}


kernel void foo(global S* data, float f) {
  data[0] = boo(data[1]);
}


// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[__struct_2:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_float]] [[_float]] [[_float]] [[_float]]
// CHECK-DAG:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK-DAG:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionParameter [[__struct_2]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_29]] 3
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_float]] [[_29]] 0
// CHECK:  [[_33:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_2]] [[_32]] [[_float_1]] [[_float_2]] [[_31]]
// CHECK:  OpReturnValue [[_33]]
