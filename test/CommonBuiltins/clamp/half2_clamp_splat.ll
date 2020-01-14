; RUN: clspv-opt -SplatArg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[x_in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x half> undef, half %x, i32 0
; CHECK: [[x_shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[x_in0]], <2 x half> undef, <2 x i32> zeroinitializer
; CHECK: [[y_in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x half> undef, half %y, i32 0
; CHECK: [[y_shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[y_in0]], <2 x half> undef, <2 x i32> zeroinitializer
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call spir_func <2 x half> @_Z5clampDv2_DhS_S_(<2 x half> %in, <2 x half> [[x_shuffle]], <2 x half> [[y_shuffle]])
; CHECK: ret <2 x half> [[call]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x half> @foo(half %x, half %y, <2 x half> %in) {
entry:
  %call = call <2 x half> @_Z5clampDv2_DhDhDh(<2 x half> %in, half %x, half %y)
  ret <2 x half> %call
}

declare <2 x half> @_Z5clampDv2_DhDhDh(<2 x half>, half, half)
