// RUN: clspv %target %s -o %t.spv
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
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float3:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 3
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK-DAG: [[halfway4:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float4]] [[halfway]] [[halfway]]
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float4]]
// CHECK: [[ld_shuffle:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float3]] [[ld]]
// CHECK: [[fabs:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] FAbs [[ld_shuffle]]
// CHECK: [[fabs_shuffle:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float4]] [[fabs]]
// CHECK: [[ceil:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] Ceil [[fabs]]
// CHECK: [[ceil_shuffle:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float4]] [[ceil]]
// CHECK: [[floor:%[a-zA-Z0-9_]+]] = OpExtInst [[float3]] [[ext_inst]] Floor [[fabs]]
// CHECK: [[floor_shuffle:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float4]] [[floor]]
// CHECK: [[fract:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Fract [[fabs_shuffle]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool4]] [[fract]] [[halfway4]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[float4]] [[gte]] [[ceil_shuffle]] [[floor_shuffle]]
// CHECK: [[sel_shuffle:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float3]] [[sel]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int3]] [[ld_shuffle]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int3]] [[cast]] [[sign_mask3]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int3]] [[sel_shuffle]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int3]] [[cast]] [[rest_mask3]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int3]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float3]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = round(*b);
}
