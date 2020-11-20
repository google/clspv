// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int2:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 2
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
// CHECK-DAG: [[sign_mask2:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int2]] [[sign_mask]] [[sign_mask]]
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
// CHECK-DAG: [[rest_mask2:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int2]] [[rest_mask]] [[rest_mask]]
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool2:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 2
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float2:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK-DAG: [[halfway2:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float2]] [[halfway]] [[halfway]]
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float2]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[float2]] [[ext_inst]] FAbs [[ld]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[float2]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[float2]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[float2]] [[ext_inst]] Fract [[fabs]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool2]] [[fract]] [[halfway2]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[float2]] [[gte]] [[ceil]] [[floor]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int2]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int2]] [[cast]] [[sign_mask2]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int2]] [[sel]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int2]] [[cast]] [[rest_mask2]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int2]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float2]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float2* a, global float2* b)
{
  *a = round(*b);
}
