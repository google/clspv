// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float* A, global float* B, float x)
{
  float z;
  *A = fract(x, &z);
  *B = z;
}
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_float_1:%[a-zA-Z0-9_]+]] = OpConstant [[_float]] {{1|0.99999}}
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpLoad [[_float]]
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Floor [[_29]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] Fract [[_29]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpExtInst [[_float]] [[_1]] FMin [[_31]] [[_float_1]]
// CHECK: OpStore {{.*}} [[_32]]
// CHECK: OpStore {{.*}} [[_30]]
