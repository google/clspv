; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define float @expm1_float(float %x) {
entry:
  %call = call spir_func float @_Z5expm1f(float %x)
  ret float %call
}

declare spir_func float @_Z5expm1f(float %x)

; CHECK: [[exp:%[a-zA-Z0-9_.]+]] = call float @llvm.exp.f32(float %x)
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = fsub float [[exp]], 1.000000e+00
; CHECK: ret float [[sub]]
