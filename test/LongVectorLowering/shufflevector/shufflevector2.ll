; RUN: clspv-opt --LongVectorLowering --instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <3 x float> @test(<8 x float> %a, <8 x float> %b) {
entry:
  %x = shufflevector <8 x float> %a, <8 x float> %b, <3 x i32> <i32 1, i32 4, i32 15>
  ret <3 x float> %x
}

; CHECK: @test(
; CHECK-SAME: [[FLOAT8:\[8 x float\]]] [[A:%[^ ]+]],
; CHECK-SAME: [[FLOAT8]] [[B:%[^ ]+]])
; CHECK-DAG: [[S0:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 1
; CHECK-DAG: [[S1:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 4
; CHECK-DAG: [[S2:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 7
; CHECK-DAG: [[TMP0:%[^ ]+]] = insertelement <3 x float> undef, float [[S0]], i64 0
; CHECK-DAG: [[TMP1:%[^ ]+]] = insertelement <3 x float> [[TMP0]], float [[S1]], i64 1
; CHECK-DAG: [[TMP2:%[^ ]+]] = insertelement <3 x float> [[TMP1]], float [[S2]], i64 2
; CHECK: ret <3 x float> [[TMP2]]
