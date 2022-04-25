; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x float> @test(<8 x float> %a, <8 x float> %b) {
entry:
  %add = fadd <8 x float> %a, %b
  ret <8 x float> %add
}

; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
; CHECK: fadd
