; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t
;
; LongVectorLoweringPass is known to generate many intermediate instructions.
; We rely on the InstCombine pass to remove them and simplify this test case.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"


define spir_func <8 x i32> @test(<3 x i32> %a) {
entry:
  %x = shufflevector
    <3 x i32> %a,
    <3 x i32> <i32 1, i32 2, i32 3>,
    <8 x i32> <i32 0, i32 1, i32 2, i32 undef, i32 undef, i32 5, i32 4, i32 3>
  ret <8 x i32> %x
}

; CHECK: define spir_func [[INT8:\[8 x i32\]]]
; CHECK-SAME: @test(<3 x i32> [[A:%[^ ]+]])
; CHECK-DAG: [[S0:%[^ ]+]] = extractelement <3 x i32> [[A]], i64 0
; CHECK-DAG: [[S1:%[^ ]+]] = extractelement <3 x i32> [[A]], i64 1
; CHECK-DAG: [[S2:%[^ ]+]] = extractelement <3 x i32> [[A]], i64 2
; CHECK-DAG: [[TMP0:%[^ ]+]] = insertvalue [[INT8]] undef, i32 [[S0]], 0
; CHECK-DAG: [[TMP1:%[^ ]+]] = insertvalue [[INT8]] [[TMP0]], i32 [[S1]], 1
; CHECK-DAG: [[TMP2:%[^ ]+]] = insertvalue [[INT8]] [[TMP1]], i32 [[S2]], 2
; CHECK-DAG: [[TMP3:%[^ ]+]] = insertvalue [[INT8]] [[TMP2]], i32 undef,  3
; CHECK-DAG: [[TMP4:%[^ ]+]] = insertvalue [[INT8]] [[TMP3]], i32 undef,  4
; CHECK-DAG: [[TMP5:%[^ ]+]] = insertvalue [[INT8]] [[TMP4]], i32 3, 5
; CHECK-DAG: [[TMP6:%[^ ]+]] = insertvalue [[INT8]] [[TMP5]], i32 2, 6
; CHECK-DAG: [[TMP7:%[^ ]+]] = insertvalue [[INT8]] [[TMP6]], i32 1, 7
; CHECK: ret [[INT8]] [[TMP7]]
