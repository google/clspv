; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define <2 x half> @rsqrt_half2(<2 x half> %x) {
entry:
  %call = call spir_func <2 x half> @_Z5rsqrtDv2_Dh(<2 x half> %x)
  ret <2 x half> %call
}

declare spir_func <2 x half> @_Z5rsqrtDv2_Dh(<2 x half>)

; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = fpext <2 x half> %x to <2 x float>
; CHECK: [[sqrt:%[a-zA-Z0-9_.]+]] = call spir_func <2 x float> @_Z4sqrtDv2_f(<2 x float> [[ext]])
; CHECK: [[div:%[a-zA-Z0-9_.]+]] = fdiv <2 x float> splat (float 1.000000e+00), [[sqrt]]
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = fptrunc <2 x float> [[div]] to <2 x half>
; CHECK: ret <2 x half> [[trunc]]
