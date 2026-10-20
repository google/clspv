; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define half @sqrt_half(half %x) {
entry:
  %call = call spir_func half @_Z4sqrtDh(half %x)
  ret half %call
}

declare spir_func half @_Z4sqrtDh(half)

; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = fpext half %x to float
; CHECK: [[sqrt:%[a-zA-Z0-9_.]+]] = call spir_func float @_Z4sqrtf(float [[ext]])
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = fptrunc float [[sqrt]] to half
; CHECK: ret half [[trunc]]
