; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x i32> @test(<8 x i32> %xs) {
  %a = extractelement <8 x i32> %xs, i32 0
  %b = extractelement <8 x i32> %xs, i32 1
  %tmp = insertelement <8 x i32> %xs, i32 %a, i32 1
  %ret = insertelement <8 x i32> %tmp, i32 %b, i32 0
  ret <8 x i32> %ret
}

; CHECK-LABEL: @test
; CHECK-SAME: ([[INT8:\[8 x i32\]]] [[XS:%[^ ]+]])
; CHECK-DAG: [[A:%[^ ]+]] = extractvalue [[INT8]] [[XS]], 0
; CHECK-DAG: [[B:%[^ ]+]] = extractvalue [[INT8]] [[XS]], 1
; CHECK-DAG: insertvalue {{.*}} i32 [[A]], 1
; CHECK-DAG: insertvalue {{.*}} i32 [[B]], 0
