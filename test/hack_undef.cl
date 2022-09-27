// Test the -hack-undef option.
// It's a workaround for https://github.com/google/clspv/issues/95
// This test no longer is powerful due to zero-initizalization of allocas.

// RUN: clspv %target %s -o %t.spv -hack-undef
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float4* A)
{
  float4 value;
  value.w = 1111.0f;
  *A = value;
}

// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK-DAG: [[_float_0:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 0
// CHECK-DAG: [[_float_1111:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1111
// CHECK-DAG: [[_15:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_0]] [[_float_0]] [[_float_0]] [[_float_1111]]
// CHECK: OpStore {{.*}} [[_15]]
