; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare <8 x i32> @llvm.smax.v8i32(<8 x i32>, <8 x i32>)

define spir_func <8 x i32> @test(<8 x i32> %a, <8 x i32> %b) {
entry:
  %x = call <8 x i32> @llvm.smax.v8i32(<8 x i32> %a, <8 x i32> %b)
  ret <8 x i32> %x
}

; CHECK-NOT: declare <8 x i32> @llvm.smax.v8i32

; CHECK-LABEL: @test
; CHECK-COUNT-8: @llvm.smax.i32

; CHECK-NOT: declare <8 x i32> @llvm.fmuladd.v8i32
