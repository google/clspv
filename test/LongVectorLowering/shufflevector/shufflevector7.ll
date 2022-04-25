; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <3 x i32> @test() {
entry:
  %x = shufflevector
    <8 x i32> <i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8>,
    <8 x i32> zeroinitializer,
    <3 x i32> <i32 1, i32 4, i32 15>
  ret <3 x i32> %x
}

; CHECK: define spir_func <3 x i32> @test()
; CHECK: ret <3 x i32> <i32 2, i32 5, i32 0>
