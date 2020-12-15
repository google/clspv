; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define <2 x float> @sincos_float2(<2 x float> %x, <2 x float>* %y) {
entry:
  %call = call spir_func <2 x float> @_Z6sincosDv2_fPU3AS0Dv2_f(<2 x float> %x, <2 x float>* %y)
  ret <2 x float> %call
}

declare spir_func <2 x float> @_Z6sincosDv2_fPU3AS0Dv2_f(<2 x float>, <2 x float>*)

; CHECK: [[sin:%[a-zA-Z0-9_.]+]] = call <2 x float> @llvm.sin.v2f32(<2 x float> %x)
; CHECK: [[cos:%[a-zA-Z0-9_.]+]] = call <2 x float> @llvm.cos.v2f32(<2 x float> %x)
; CHECK: store <2 x float> [[cos]], <2 x float>* %y, align 8
; CHECK: ret <2 x float> [[sin]]

