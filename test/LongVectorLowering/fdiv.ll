; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <16 x float> @test(<16 x float> %a, <16 x float> %b) {
entry:
  %add = fdiv <16 x float> %a, %b
  ret <16 x float> %add
}

; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
; CHECK: fdiv
