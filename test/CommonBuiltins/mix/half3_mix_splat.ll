; RUN: clspv-opt --passes=splat-arg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[x_in0:%[a-zA-Z0-9_.]+]] = insertelement <3 x half> {{.*}}, half %x, i64 0
; CHECK: [[x_shuffle:%[a-zA-Z0-9_.]+]] = shufflevector <3 x half> [[x_in0]], <3 x half> {{.*}}, <3 x i32> zeroinitializer
; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call spir_func <3 x half> @_Z3mixDv3_DhS_S_(<3 x half> %in1, <3 x half> %in2, <3 x half> [[x_shuffle]])
; CHECK: ret <3 x half> [[call]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x half> @foo(half %x, <3 x half> %in1, <3 x half> %in2) {
entry:
  %call = call <3 x half> @_Z3mixDv3_DhS_Dh(<3 x half> %in1, <3 x half> %in2, half %x)
  ret <3 x half> %call
}

declare <3 x half> @_Z3mixDv3_DhS_Dh(<3 x half>, <3 x half>, half)

