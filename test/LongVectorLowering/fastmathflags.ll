; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

; TODO cover fcmp and select

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare <8 x float> @llvm.fmuladd.v8f32(<8 x float>, <8 x float>, <8 x float>)

define spir_func <8 x float> @test(<8 x float> %x, <8 x float> %y, <8 x float> %z) {
entry:
  %a = fadd fast <8 x float> %x, %y
  %b = fneg nnan <8 x float> %a
  %c = fsub ninf <8 x float> %b, %z
  %d = fmul nsz <8 x float> %c, %a
  %e = fdiv arcp contract <8 x float> %d, %b
  %f = frem reassoc <8 x float> %e, %c
  %g = call fast <8 x float> @llvm.fmuladd.v8f32(<8 x float> %d, <8 x float> %e, <8 x float> %f)
  ret <8 x float> %g
}

; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast
; CHECK: fadd fast

; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan
; CHECK: fneg nnan

; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf
; CHECK: fsub ninf

; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz
; CHECK: fmul nsz

; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract
; CHECK: fdiv arcp contract

; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc
; CHECK: frem reassoc

; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
; CHECK: call fast float @llvm.fmuladd.f32
