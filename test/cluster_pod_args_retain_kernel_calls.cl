// RUN: clspv --cluster-pod-kernel-args %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test_kernel_to_call(__global int *output, __global int *input, int where)
{
  for (int i=0; i<where; i++)
    output[get_global_id(0)] += input[i];
}

__kernel void test_call_kernel(__global int *src, __global int *dst, int c)
{
  int tid = get_global_id(0);
  test_kernel_to_call(dst, src, tid+c);
}

// Check that both the kernels still exist as entry points, and that they have
// some of the operations we'd expect in them (the fail state we're testing for
// is that the second entry point is completely empty save for an
// OpUnreachable).
// CHECK: OpEntryPoint GLCompute %[[first_kernel:[0-9a-zA-Z_]+]] "test_kernel_to_call"
// CHECK: OpEntryPoint GLCompute %[[second_kernel:[0-9a-zA-Z_]+]] "test_call_kernel"
// CHECK: %[[first_kernel]] = OpFunction %void
// CHECK: OpLoad
// CHECK: OpBranchConditional
// CHECK: OpStore
// CHECK: %[[second_kernel]] = OpFunction %void
// CHECK-NOT: OpUnreachable
// CHECK: OpLoad
// CHECK: OpBranchConditional
// CHECK: OpStore
