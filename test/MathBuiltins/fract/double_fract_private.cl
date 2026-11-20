// RUN: clspv %target -denorm-preserve=16,64 %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -denorm-preserve=16,64 %s -o %t3.spv --use-native-builtins=fract
// RUN: spirv-dis -o %t4.spvasm %t3.spv
// RUN: FileCheck %s < %t4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t3.spv

void kernel foo(global double* A, global double* B, double x)
{
  double z;
  *A = fract(x, &z);
  *B = z;
}
// The fract result is clamped to 0x1.fffffffffffffp-1, the largest double
// below 1.0.
// CHECK: [[_1:%[a-zA-Z0-9_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK-DAG: [[_double_1:%[a-zA-Z0-9_]+]] = OpConstant [[_double]] 0.99999999999999989
// CHECK: [[_30:%[a-zA-Z0-9_]+]] = OpExtInst [[_double]] [[_1]] Floor [[_29:%[a-zA-Z0-9_]+]]
// CHECK: [[_31:%[a-zA-Z0-9_]+]] = OpExtInst [[_double]] [[_1]] Fract [[_29]]
// CHECK: [[_32:%[a-zA-Z0-9_]+]] = OpExtInst [[_double]] [[_1]] NMin [[_31]] [[_double_1]]
// CHECK: OpStore {{.*}} [[_32]]
// CHECK: OpStore {{.*}} [[_30]]
