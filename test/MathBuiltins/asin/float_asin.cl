// RUN: clspv %target %s -o %t.spv --use-native-builtins=fabs
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FAbs
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Sqrt
// CHECK: OpStore

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b)
{
  *a = asin(*b);
}
