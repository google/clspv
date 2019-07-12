// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b, global int4* c)
{
  *a = frexp(*b, c);
}

// CHECK: [[_1:%[0-9a-zA-Z_]+]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK: [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain
// CHECK: [[_23:%[0-9a-zA-Z_]+]] = OpAccessChain
// CHECK: [[_24:%[0-9a-zA-Z_]+]] = OpAccessChain
// CHECK: [[_25:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_23]]
// CHECK: [[_26:%[0-9a-zA-Z_]+]] = OpExtInst [[_v4float]] [[_1]] Frexp [[_25]] [[_24]]
// CHECK: OpStore [[_22]] [[_26]]
