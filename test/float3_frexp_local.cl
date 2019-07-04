// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 3
// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[UINT_VECTOR_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[UINT_TYPE_ID]] 3
// CHECK: %[[LOCAL_VAR_ID:[a-zA-Z0-9_]*]] = OpVariable {{.*}} Workgroup
// CHECK: %[[LOADB_ID:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_VECTOR_TYPE_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT_VECTOR_TYPE_ID]] {{.*}} Frexp %[[LOADB_ID]] %[[LOCAL_VAR_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]
// CHECK: %[[LOAD_LOCAL_VAR_ID:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_VECTOR_TYPE_ID]] %[[LOCAL_VAR_ID]]
// CHECK: OpStore{{.*}} %[[LOAD_LOCAL_VAR_ID]]

typedef float float3 __attribute__((ext_vector_type(3)));
typedef int int3 __attribute__((ext_vector_type(3)));

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float3* a, global float3* b, global int3* c)
{
  local int3 temp_c;
  *a = frexp(*b, &temp_c); 
  *c = temp_c;
}
