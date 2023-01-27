// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void boo(__global float* outDest) {
  *outDest = 1.0f;
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(__global uint* outDest) {
  ((global int*)outDest)[1] = 1;
  boo(outDest);
}
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[float_1:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1
// CHECK-DAG: [[float_const:%[a-zA-Z0-9_]+]] = OpConstant [[float]]
// CHECK-NOT: OpFunctionCall
// CHECK: OpStore {{.*}} [[float_const]]
// CHECK: OpStore {{.*}} [[float_1]]
// CHECK-NOT: OpFunctionCall
