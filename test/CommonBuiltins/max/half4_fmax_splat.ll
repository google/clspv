; RUN: clspv-opt -SplatArg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[x_in0:%[a-zA-Z0-9_.]+]] = insertelement <4 x half> {{.*}}, half %x, i32 0
; CHECK: [[x_shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <4 x half> [[x_in0]], <4 x half> {{.*}}, <4 x i32> zeroinitializer
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call spir_func <4 x half> @_Z4fmaxDv4_DhS_(<4 x half> %in, <4 x half> [[x_shuffle]])
; CHECK: ret <4 x half> [[call]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <4 x half> @foo(half %x, <4 x half> %in) {
entry:
  %call = call <4 x half> @_Z4fmaxDv4_DhDh(<4 x half> %in, half %x)
  ret <4 x half> %call
}

declare <4 x half> @_Z4fmaxDv4_DhDh(<4 x half>, half)

