; RUN: clspv-opt --LongVectorLowering --instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <8 x float> @test(<8 x float> %a) {
entry:
  %x = shufflevector <8 x float> %a, <8 x float> undef, <8 x i32> <i32 0, i32 1, i32 2, i32 undef, i32 undef, i32 15, i32 14, i32 13>
  ret <8 x float> %x
}

; CHECK: define spir_func [[FLOAT8:{ float, float, float, float, float, float, float, float }]]
; CHECK-SAME: @test([[FLOAT8]] [[A:%[^ ]+]])
; CHECK-DAG: [[S0:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 0
; CHECK-DAG: [[S1:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 1
; CHECK-DAG: [[S2:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 2
; CHECK-DAG: [[TMP0:%[^ ]+]] = insertvalue [[FLOAT8]] undef, float [[S0]], 0
; CHECK-DAG: [[TMP1:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP0]], float [[S1]], 1
; CHECK-DAG: [[TMP2:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP1]], float [[S2]], 2
; CHECK-DAG: [[TMP3:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP2]], float undef, 3
; CHECK-DAG: [[TMP4:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP3]], float undef, 4
; CHECK-DAG: [[TMP5:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP4]], float undef, 5
; CHECK-DAG: [[TMP6:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP5]], float undef, 6
; CHECK-DAG: [[TMP7:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP6]], float undef, 7
; CHECK: ret [[FLOAT8]] [[TMP7]]
