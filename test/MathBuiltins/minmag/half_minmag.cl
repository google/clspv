// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.flush.spv -denorm-flush-to-zero=16,64
// RUN: spirv-dis -o %t2.flush.spvasm %t.flush.spv
// RUN: FileCheck %s --check-prefix=CHECK-FLUSH < %t2.flush.spvasm
// RUN: spirv-val --target-env spv1.4 %t.flush.spv

// CHECK: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK: %[[LOAD0:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK: %[[LOAD1:[a-zA-Z0-9_]*]] = OpLoad %[[HALF_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[HALF_TYPE_ID]] %[[EXT_INST]] FMin %[[LOAD0]] %[[LOAD1]]
// CHECK: OpStore {{.*}}

// CHECK-FLUSH: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-FLUSH-DAG: %[[HALF_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 16
// CHECK-FLUSH: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[HALF_TYPE_ID]] %[[EXT_INST]] FMin
// CHECK-FLUSH: OpStore {{.*}}

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global half* a, global half* b, global half* out)
{
  *out = minmag(*a, *b);
}
