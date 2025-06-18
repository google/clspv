// RUN: clspv %target %s -o %t.spv -vec3-to-vec4 --use-native-builtins=fabs
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[ext_inst:%[a-zA-Z0-9_]*]] = OpExtInstImport "GLSL.std.450"
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[sign_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
// CHECK-DAG: [[sign_mask3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int4]] [[sign_mask]] [[sign_mask]] [[sign_mask]]
// CHECK-DAG: [[rest_mask:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
// CHECK-DAG: [[rest_mask3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[int4]] [[rest_mask]] [[rest_mask]] [[rest_mask]]
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK-DAG: [[float:%[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[a-zA-Z0-9_]*]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[undef4:%[a-zA-Z0-9_]*]] = OpUndef [[float4]]
// CHECK-DAG: [[halfway:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 0.5
// CHECK-DAG: [[halfway3:%[a-zA-Z0-9_]+]] = OpConstantComposite [[float4]] [[halfway]] [[halfway]] [[halfway]] [[halfway]]
// CHECK: [[ld:%[a-zA-Z0-9_]*]] = OpLoad [[float4]]
// CHECK: [[ld4:%[a-zA-Z0-9_]*]] = OpVectorShuffle [[float4]] [[ld]] [[undef4]] 0 1 2 4294967295
// CHECK: [[fabs4:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] FAbs [[ld4]]
// CHECK: [[ceil4:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Ceil [[fabs4]]
// CHECK: [[floor4:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Floor [[fabs4]]
// CHECK: [[fract4:%[a-zA-Z0-9_]+]] = OpExtInst [[float4]] [[ext_inst]] Fract [[fabs4]]
// CHECK: [[gte:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThanEqual [[bool4]] [[fract4]] [[halfway3]]
// CHECK: [[sel4:%[a-zA-Z0-9_]+]] = OpSelect [[float4]] [[gte]] [[ceil4]] [[floor4]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]] [[ld]]
// CHECK: [[sign:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int4]] [[cast]] [[sign_mask3]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[int4]] [[sel4]]
// CHECK: [[rest:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int4]] [[cast]] [[rest_mask3]]
// CHECK: [[combine:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[int4]] [[rest]] [[sign]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[float4]] [[combine]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b)
{
  *a = round(*b);
}
