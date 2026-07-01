// RUN: clspv %s -o %t.preserve.spv -denorm-preserve=16,32,64
// RUN: spirv-dis %t.preserve.spv -o %t.preserve.spvasm
// RUN: FileCheck %s --check-prefix=PRESERVE < %t.preserve.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve.spv

// RUN: clspv %s -o %t.flush.spv -denorm-flush-to-zero=16,32,64
// RUN: spirv-dis %t.flush.spv -o %t.flush.spvasm
// RUN: FileCheck %s --check-prefix=FLUSH < %t.flush.spvasm
// RUN: spirv-val --target-env spv1.4 %t.flush.spv

// RUN: clspv %s -o %t.none.spv
// RUN: spirv-dis %t.none.spv -o %t.none.spvasm
// RUN: FileCheck %s --check-prefix=NONE < %t.none.spvasm
// RUN: spirv-val %t.none.spv

// RUN: clspv %s -o %t.preserve14.spv -denorm-preserve=16,32,64 -spv-version 1.4
// RUN: spirv-dis %t.preserve14.spv -o %t.preserve14.spvasm
// RUN: FileCheck %s --check-prefix=PRESERVE14 < %t.preserve14.spvasm
// RUN: spirv-val --target-env spv1.4 %t.preserve14.spv

// PRESERVE: OpCapability DenormPreserve
// PRESERVE: OpExtension "SPV_KHR_float_controls"
// PRESERVE: OpExecutionMode {{.*}} DenormPreserve 16
// PRESERVE: OpExecutionMode {{.*}} DenormPreserve 32
// PRESERVE: OpExecutionMode {{.*}} DenormPreserve 64

// FLUSH: OpCapability DenormFlushToZero
// FLUSH: OpExtension "SPV_KHR_float_controls"
// FLUSH: OpExecutionMode {{.*}} DenormFlushToZero 16
// FLUSH: OpExecutionMode {{.*}} DenormFlushToZero 32
// FLUSH: OpExecutionMode {{.*}} DenormFlushToZero 64

// NONE-NOT: OpCapability DenormPreserve
// NONE-NOT: OpCapability DenormFlushToZero
// NONE-NOT: OpExtension "SPV_KHR_float_controls"
// NONE-NOT: OpExecutionMode {{.*}} DenormPreserve
// NONE-NOT: OpExecutionMode {{.*}} DenormFlushToZero

// PRESERVE14: OpCapability DenormPreserve
// PRESERVE14-NOT: OpExtension "SPV_KHR_float_controls"
// PRESERVE14: OpExecutionMode {{.*}} DenormPreserve 16
// PRESERVE14: OpExecutionMode {{.*}} DenormPreserve 32
// PRESERVE14: OpExecutionMode {{.*}} DenormPreserve 64

void kernel foo(global int *input, global float *output)
{
    uint gid = get_global_id(0);
    output[gid] = input[gid];
}
