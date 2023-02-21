// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global float* A, float x)
{
  *A = acospi(x);
}
// CHECK-DAG: [[_float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK: [[_27:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_float]]
// CHECK-NOT: OpExtInst {{%[a-zA-Z0-9_]+}} {{%[a-zA-Z0-9_]+}} Acos
// CHECK: OpStore {{.*}}
