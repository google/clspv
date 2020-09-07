; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(float %val, float addrspace(1)* nocapture %out) {
entry:
  %call = tail call spir_func float @_Z5log1pf(float %val)
  ; CHECK: %0 = fadd float 1.000000e+00, %val
  ; CHECK: %1 = call float @_Z3logf(float %0)
  store float %call, float addrspace(1)* %out, align 4
  ret void
}

declare spir_func float @_Z5log1pf(float) #1
