; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t
;
; This test doesn't involve long-vectors, the pass should not modify the IR.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <2 x i32> @test() {
entry:
  %x = shufflevector <2 x i32> undef, <2 x i32> undef, <2 x i32> zeroinitializer
  ret <2 x i32> %x
}

; CHECK-LABEL: @test
; CHECK: %x = shufflevector <2 x i32> undef, <2 x i32> undef, <2 x i32> zeroinitializer
