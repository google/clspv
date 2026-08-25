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
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin
// CHECK: OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin
// CHECK: %[[RES:[a-zA-Z0-9_]*]] = OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: OpStore {{.*}}

// CHECK-PRESERVE: %[[EXT_INST:[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-PRESERVE-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-PRESERVE-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-PRESERVE: %[[LOAD0:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-PRESERVE: %[[LOAD1:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK-PRESERVE: %[[E0_0:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD0]] 0
// CHECK-PRESERVE: %[[E1_0:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD1]] 0
// CHECK-PRESERVE: %[[M0:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin %[[E0_0]] %[[E1_0]]
// CHECK-PRESERVE: %[[E0_1:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD0]] 1
// CHECK-PRESERVE: %[[E1_1:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD1]] 1
// CHECK-PRESERVE: %[[M1:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin %[[E0_1]] %[[E1_1]]
// CHECK-PRESERVE: %[[E0_2:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD0]] 2
// CHECK-PRESERVE: %[[E1_2:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD1]] 2
// CHECK-PRESERVE: %[[M2:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin %[[E0_2]] %[[E1_2]]
// CHECK-PRESERVE: %[[E0_3:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD0]] 3
// CHECK-PRESERVE: %[[E1_3:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[FLOAT_TYPE_ID]] %[[LOAD1]] 3
// CHECK-PRESERVE: %[[M3:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_TYPE_ID]] %[[EXT_INST]] FMin %[[E0_3]] %[[E1_3]]
// CHECK-PRESERVE: %[[RES:[a-zA-Z0-9_]*]] = OpCompositeConstruct %[[FLOAT_VECTOR_TYPE_ID]] %[[M0]] %[[M1]] %[[M2]] %[[M3]]
// CHECK-PRESERVE: OpStore {{.*}}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b, global float4* out)
{
  *out = minmag(*a, *b);
}
