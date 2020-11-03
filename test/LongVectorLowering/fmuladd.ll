; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare <8 x half> @llvm.fmuladd.v8f16(<8 x half>, <8 x half>, <8 x half>) #1

define spir_func <8 x half> @test(<8 x half> %a, <8 x half> %b, <8 x half> %c) {
entry:
  %x = call <8 x half> @llvm.fmuladd.v8f16(<8 x half> %a, <8 x half> %b, <8 x half> %c)
  ret <8 x half> %x
}

attributes #1 = { nounwind readnone speculatable willreturn }

; CHECK-NOT: declare <8 x half> @llvm.fmuladd.v8f16

; CHECK-LABEL: @test
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16
; CHECK: @llvm.fmuladd.f16

; CHECK-NOT: declare <8 x half> @llvm.fmuladd.v8f16
