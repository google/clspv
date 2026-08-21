// RUN: clspv %target %s -o %t.flush.spv -denorm-flush-to-zero=32
// RUN: spirv-dis -o %t2.flush.spvasm %t.flush.spv
// RUN: FileCheck %s --check-prefix=CHECK-FLUSH < %t2.flush.spvasm
// RUN: spirv-val --target-env spv1.4 %t.flush.spv

// RUN: clspv %target %s -o %t.preserve.spv -denorm-preserve=32
// RUN: spirv-dis -o %t2.preserve.spvasm %t.preserve.spv
// RUN: FileCheck %s --check-prefix=CHECK-PRESERVE < %t2.preserve.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve.spv

// CHECK-FLUSH: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-FLUSH-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-FLUSH: %[[LOADB:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK-FLUSH: %[[CMP:[a-zA-Z0-9_]*]] = OpFOrdLessThan
// CHECK-FLUSH: %[[SEL:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT_TYPE_ID]] %[[CMP]]
// CHECK-FLUSH: %[[OP:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] NMax %[[SEL]]
// CHECK-FLUSH: OpStore {{.*}} %[[OP]]

// CHECK-PRESERVE: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-PRESERVE-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-PRESERVE-DAG: %[[CST1:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 1
// CHECK-PRESERVE: %[[LOADB:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK-PRESERVE: %[[OP:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] NMax %[[LOADB]] %[[CST1]]
// CHECK-PRESERVE: OpStore {{.*}} %[[OP]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* a, global float* b)
{
  *a = fmax(*b, 1.0f);
}
