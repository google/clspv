; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)
; CHECK: call float @_Z11clspv.fractf(float 0.000000e+00)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  %call = call <16 x float> @_Z11clspv.fractDv16_f(<16 x float> zeroinitializer)
  ret void
}

declare <16 x float> @_Z11clspv.fractDv16_f(<16 x float>)

