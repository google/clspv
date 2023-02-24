; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <8 x float> @test(<3 x float> %a, <3 x float> %b) {
entry:
  %x = shufflevector <3 x float> %a, <3 x float> %b, <8 x i32> <i32 0, i32 1, i32 2, i32 poison, i32 poison, i32 5, i32 4, i32 3>
  ret <8 x float> %x
}

; CHECK: define spir_func [[FLOAT8:\[8 x float\]]]
; CHECK-SAME: @test(<3 x float> [[A:%[^ ]+]], <3 x float> [[B:%[^ ]+]])
; CHECK-DAG: [[S0:%[^ ]+]] = extractelement <3 x float> [[A]], i64 0
; CHECK-DAG: [[S1:%[^ ]+]] = extractelement <3 x float> [[A]], i64 1
; CHECK-DAG: [[S2:%[^ ]+]] = extractelement <3 x float> [[A]], i64 2
; CHECK-DAG: [[S5:%[^ ]+]] = extractelement <3 x float> [[B]], i64 2
; CHECK-DAG: [[S6:%[^ ]+]] = extractelement <3 x float> [[B]], i64 1
; CHECK-DAG: [[S7:%[^ ]+]] = extractelement <3 x float> [[B]], i64 0
; CHECK-DAG: [[TMP0:%[^ ]+]] = insertvalue [[FLOAT8]] poison, float [[S0]], 0
; CHECK-DAG: [[TMP1:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP0]], float [[S1]], 1
; CHECK-DAG: [[TMP2:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP1]], float [[S2]], 2
; CHECK-DAG: [[TMP5:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP2]], float [[S5]], 5
; CHECK-DAG: [[TMP6:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP5]], float [[S6]], 6
; CHECK-DAG: [[TMP7:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP6]], float [[S7]], 7
; CHECK: ret [[FLOAT8]] [[TMP7]]
