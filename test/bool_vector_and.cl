// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(float4 a, float4 b, float4 c, float4 d, global int4 *o)
{
    int4 ab = (a <= b);
    int4 cd = (c > d);
    *o = (ab && cd);
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[int4:%[a-zA-Z0-9_]+]] = OpTypeVector [[int]] 4
// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[bool4:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 4
// CHECK: [[less:%[a-zA-Z0-9_]+]] = OpFOrdLessThanEqual [[bool4]]
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpFOrdGreaterThan [[bool4]]
// CHECK: [[and:%[a-zA-Z0-9_]+]] = OpLogicalAnd [[bool4]] [[greater]] [[less]]
// CHECK: OpSelect [[int4]] [[and]]
