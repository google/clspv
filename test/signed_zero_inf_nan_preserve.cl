// RUN: clspv %s -o %t.preserve.spv -signed-zero-inf-nan-preserve=16,32,64
// RUN: spirv-dis %t.preserve.spv -o %t.preserve.spvasm
// RUN: FileCheck %s --check-prefix=PRESERVE < %t.preserve.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve.spv

// RUN: clspv %s -o %t.none.spv
// RUN: spirv-dis %t.none.spv -o %t.none.spvasm
// RUN: FileCheck %s --check-prefix=NONE < %t.none.spvasm
// RUN: spirv-val %t.none.spv

// RUN: clspv %s -o %t.preserve14.spv -signed-zero-inf-nan-preserve=16,32,64 -spv-version 1.4
// RUN: spirv-dis %t.preserve14.spv -o %t.preserve14.spvasm
// RUN: FileCheck %s --check-prefix=PRESERVE14 < %t.preserve14.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve14.spv

// PRESERVE: OpCapability SignedZeroInfNanPreserve
// PRESERVE: OpExtension "SPV_KHR_float_controls"
// PRESERVE: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 16
// PRESERVE: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 32
// PRESERVE: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 64

// NONE-NOT: OpCapability SignedZeroInfNanPreserve
// NONE-NOT: OpExtension "SPV_KHR_float_controls"
// NONE-NOT: OpExecutionMode {{.*}} SignedZeroInfNanPreserve

// PRESERVE14: OpCapability SignedZeroInfNanPreserve
// PRESERVE14-NOT: OpExtension "SPV_KHR_float_controls"
// PRESERVE14: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 16
// PRESERVE14: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 32
// PRESERVE14: OpExecutionMode {{.*}} SignedZeroInfNanPreserve 64

void kernel foo(global int *input, global float *output)
{
    uint gid = get_global_id(0);
    output[gid] = input[gid];
}
