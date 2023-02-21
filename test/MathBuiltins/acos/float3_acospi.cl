// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float3* A, float3 x)
{
  *A = acospi(x);
}
// CHECK-NOT: OpExtInst {{.*}} Acos
