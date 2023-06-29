// RUN: clspv %s -o %t.spv -rounding-mode-rte=16,32,64 -spv-version 1.4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val --target-env spv1.4 %t.spv
// RUN: FileCheck %s < %t.spvasm

// CHECK: OpCapability RoundingModeRTE
// CHECK-NOT: OpExtension "SPV_KHR_float_controls"
// CHECK: OpExecutionMode {{.*}} RoundingModeRTE 16
// CHECK: OpExecutionMode {{.*}} RoundingModeRTE 32
// CHECK: OpExecutionMode {{.*}} RoundingModeRTE 64


void kernel foo(global int *input, global float *output)
{
    uint gid = get_global_id(0);
    output[gid] = input[gid];
}
