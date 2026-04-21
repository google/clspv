// RUN: clspv %s -o %t.spv -spv-khr-fma=32 --print-before=spirv-producer &> %t.ll
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck %s < %t.ll --check-prefixes=CHECK-LLVM-IR

// CHECK-LLVM-IR: [[fma:%[^ ]+]] = tail call float @llvm.fmuladd.f32(float %a, float %b, float %c)
// CHECK-LLVM-IR-NEXT: store float [[fma]]
// CHECK-LLVM-IR-NEXT: ret void

// CHECK-COUNT-1: OpCapability FMAKHR
// CHECK-COUNT-1: OpExtension "SPV_KHR_fma"
// CHECK: [[fma:%[^ ]+]] = OpFmaKHR
// CHECK-NEXT: OpStore {{.*}} [[fma]]
// CHECK-NEXT: OpReturn

void kernel foo(float a, float b, float c, global float *o) { *o = a * b + c; }
