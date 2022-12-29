// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float2* A, float2 x)
{
  *A = asinpi(x);
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[_float]] 2
// CHECK: [[LOAD_ID:%[a-zA-Z0-9_]+]] = OpCompositeExtract
// CHECK-NOT: OpExtInst {{%[a-zA-Z0-9_]+}} {{%[a-zA-Z0-9_]+}} Acos
// CHECK: [[OP_ID:%[a-zA-Z0-9_]*]] = OpFunctionCall [[_v2float]] {{%[a-zA-Z0-9_]+}} [[LOAD_ID]]
// CHECK: OpStore {{.*}} [[OP_ID]]
// CHECK: OpFunction
// CHECK: OpLabel
