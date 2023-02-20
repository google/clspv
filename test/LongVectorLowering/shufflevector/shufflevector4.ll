; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <8 x float> @test(<8 x float> %a) {
entry:
  %x = shufflevector <8 x float> %a, <8 x float> poison, <8 x i32> <i32 0, i32 1, i32 2, i32 poison, i32 poison, i32 15, i32 14, i32 13>
  ret <8 x float> %x
}

; CHECK: define spir_func [[FLOAT8:\[8 x float\]]]
; CHECK-SAME: @test([[FLOAT8]] [[A:%[^ ]+]])
; CHECK: ret [[FLOAT8]] [[A]]
