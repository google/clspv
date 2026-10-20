; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define float @rsqrt_float(float %x) {
entry:
  %call = call spir_func float @_Z5rsqrtf(float %x)
  ret float %call
}

declare spir_func float @_Z5rsqrtf(float)

; CHECK: [[sqrt:%[a-zA-Z0-9_.]+]] = call spir_func float @_Z4sqrtf(float %x)
; CHECK: [[div:%[a-zA-Z0-9_.]+]] = fdiv float 1.000000e+00, [[sqrt]]
; CHECK: ret float [[div]]
