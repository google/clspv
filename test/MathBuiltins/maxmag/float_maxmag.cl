// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.preserve.spv -denorm-preserve=32
// RUN: spirv-dis -o %t2.preserve.spvasm %t.preserve.spv
// RUN: FileCheck %s --check-prefix=CHECK-PRESERVE < %t2.preserve.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMax
// CHECK: OpStore {{.*}}

// CHECK-PRESERVE: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-PRESERVE-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-PRESERVE: %[[LOAD0:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK-PRESERVE: %[[LOAD1:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK-PRESERVE: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMax %[[LOAD0]] %[[LOAD1]]
// CHECK-PRESERVE: OpStore {{.*}}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b, global float* out)
{
  *out = maxmag(*a, *b);
}
