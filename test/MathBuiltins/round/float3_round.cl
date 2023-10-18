// RUN: clspv %target %s -o %t.spv --use-native-builtins=fabs
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int3:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 3
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
// CHECK-DAG: [[sign_mask3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int3]] [[sign_mask]] [[sign_mask]] [[sign_mask]]
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
// CHECK-DAG: [[rest_mask3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int3]] [[rest_mask]] [[rest_mask]] [[rest_mask]]
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool3:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 3
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float3:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 3
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK-DAG: [[halfway3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float3]] [[halfway]] [[halfway]]
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float3]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] FAbs [[ld]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] Fract [[fabs]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool3]] [[fract]] [[halfway3]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[float3]] [[gte]] [[ceil]] [[floor]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int3]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int3]] [[cast]] [[sign_mask3]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int3]] [[sel]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int3]] [[cast]] [[rest_mask3]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int3]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float3]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = round(*b);
}
