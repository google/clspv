; RUN: clspv-opt --passes=splat-arg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[x_in0:%[a-zA-Z0-9_.]+]] = insertelement <2 x half> {{.*}}, half %x, i32 0
; CHECK: [[x_shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <2 x half> [[x_in0]], <2 x half> {{.*}}, <2 x i32> zeroinitializer
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call spir_func <2 x half> @_Z4fmaxDv2_DhS_(<2 x half> %in, <2 x half> [[x_shuffle]])
; CHECK: ret <2 x half> [[call]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x half> @foo(half %x, <2 x half> %in) {
entry:
  %call = call <2 x half> @_Z4fmaxDv2_DhDh(<2 x half> %in, half %x)
  ret <2 x half> %call
}

declare <2 x half> @_Z4fmaxDv2_DhDh(<2 x half>, half)

