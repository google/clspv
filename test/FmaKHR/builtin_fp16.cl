// RUN: clspv %s -o %t.spv -spv-khr-fma=64,32,16
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK-16

// RUN: clspv %s -o %t-no16.spv -spv-khr-fma=64,32
// RUN: spirv-dis %t-no16.spv -o %t-no16.spvasm
// RUN: spirv-val %t-no16.spv --target-env spv1.0
// RUN: FileCheck %s < %t-no16.spvasm --check-prefixes=CHECK-NO-16

// CHECK-16-COUNT-1: OpCapability FMAKHR
// CHECK-16-COUNT-1: OpExtension "SPV_KHR_fma"
// CHECK-16-COUNT-1: OpFmaKHR

// CHECK-NO-16-NOT: OpCapability FMAKHR
// CHECK-NO-16-NOT: OpExtension "SPV_KHR_fma"
// CHECK-NO-16-NOT: OpFmaKHR

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel foo(half a, half b, half c, global half *o) { *o = fma(a, b, c); }
