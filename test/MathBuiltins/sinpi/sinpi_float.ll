; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define float @sinpi_float(float %x) {
entry:
  %call = call spir_func float @_Z5sinpif(float %x)
  ret float %call
}

declare spir_func float @_Z5sinpif(float)

; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = fmul float %x, 0x400921FB60000000
; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call float @llvm.sin.f32(float [[mul]])

