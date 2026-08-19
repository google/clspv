; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; Libclc function: should NOT be decomposed into fmul + fadd
define float @test_clc_mad_float(float %a, float %b, float %c) {
; CHECK-LABEL: @test_clc_mad_float
; CHECK: %call = call spir_func float @_Z9__clc_madfff(float %a, float %b, float %c)
; CHECK: ret float %call
  %call = call spir_func float @_Z9__clc_madfff(float %a, float %b, float %c)
  ret float %call
}

; Regular OpenCL mad: SHOULD be decomposed into fmul + fadd
define float @test_regular_mad_float(float %a, float %b, float %c) {
; CHECK-LABEL: @test_regular_mad_float
; CHECK: [[mul:%[a-zA-Z0-9_.]+]] = fmul float %a, %b
; CHECK: [[add:%[a-zA-Z0-9_.]+]] = fadd float [[mul]], %c
; CHECK: ret float [[add]]
  %call = call spir_func float @_Z3madfff(float %a, float %b, float %c)
  ret float %call
}

declare spir_func float @_Z9__clc_madfff(float, float, float)
declare spir_func float @_Z3madfff(float, float, float)
