; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(<3 x float> %val, <3 x float> addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func <3 x float> @_Z5log1pDv3_f(<3 x float> %val)
  ; CHECK: %0 = fadd <3 x float> <float 1.000000e+00, float 1.000000e+00, float 1.000000e+00>, %val
  ; CHECK: %1 = call <3 x float> @_Z3logDv3_f(<3 x float> %0)
  store <3 x float> %call, <3 x float> addrspace(1)* %out, align 16
  ret void
}

declare spir_func <3 x float> @_Z5log1pDv3_f(<3 x float>) #1
