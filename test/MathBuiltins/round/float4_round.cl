// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
// CHECK-DAG: [[sign_mask4:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int4]] [[sign_mask]] [[sign_mask]] [[sign_mask]] [[sign_mask]]
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
// CHECK-DAG: [[rest_mask4:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int4]] [[rest_mask]] [[rest_mask]] [[rest_mask]] [[rest_mask]]
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK-DAG: [[halfway4:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float4]] [[halfway]] [[halfway]]
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float4]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] FAbs [[ld]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Fract [[fabs]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool4]] [[fract]] [[halfway4]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[float4]] [[gte]] [[ceil]] [[floor]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int4]] [[cast]] [[sign_mask4]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]] [[sel]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int4]] [[cast]] [[rest_mask4]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int4]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float4]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float4* a, global float4* b)
{
  *a = round(*b);
}
