; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(<2 x float> %val, <2 x float> addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func <2 x float> @_Z5log1pDv2_f(<2 x float> %val)
  ; CHECK: %0 = fadd <2 x float> <float 1.000000e+00, float 1.000000e+00>, %val
  ; CHECK: %1 = call <2 x float> @llvm.log.v2f32(<2 x float> %0)
  store <2 x float> %call, <2 x float> addrspace(1)* %out, align 8
  ret void
}

declare spir_func <2 x float> @_Z5log1pDv2_f(<2 x float>) #1
