// RUN: clspv %s -o %t.spv -spv-khr-fma=64,32,16 --print-before=spirv-producer &> %t.ll
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck %s < %t.ll --check-prefixes=CHECK-LLVM-IR

// CHECK-LLVM-IR: [[fma:%[^ ]+]] = tail call spir_func float @_Z3fmafff(float %a, float %b, float %c)
// CHECK-LLVM-IR-NEXT: store float [[fma]]
// CHECK-LLVM-IR-NEXT: ret void

// CHECK-COUNT-1: OpCapability FMAKHR
// CHECK-COUNT-1: OpExtension "SPV_KHR_fma"
// CHECK: [[fma:%[^ ]+]] = OpFmaKHR
// CHECK-NEXT: OpStore {{.*}} [[fma]]
// CHECK-NEXT: OpReturn

void kernel foo(float a, float b, float c, global float *o) { *o = fma(a, b, c); }
