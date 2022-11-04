// RUN: clspv %target --long-vector %s -o %t.spv -cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] Atanh

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float8* a, global float8* b)
{
  *a = atanh(*b);
}
