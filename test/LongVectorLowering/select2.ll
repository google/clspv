; RUN: clspv-opt --LongVectorLowering --early-cse --instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x float> @test(i1 %cond, <8 x float> %a, <8 x float> %b) {
entry:
  ; This is not derived from a regular OpenCL select overload.
  %value = select i1 %cond, <8 x float> %a, <8 x float> %b
  ret <8 x float> %value
}

; CHECK: define spir_func
; CHECK-SAME: [[FLOAT8:{ float, float, float, float, float, float, float, float }]]
; CHECK-SAME: @test(
; CHECK-SAME: i1 [[COND:%[^ ]+]],
; CHECK-SAME: [[FLOAT8]] [[A:%[^ ]+]],
; CHECK-SAME: [[FLOAT8]] [[B:%[^ ]+]]) {

; There should only be one select, but for compatibility with the SPIR-V
; producer it is scalarised.

; CHECK-DAG:  [[A_0:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 0
; CHECK-DAG:  [[A_1:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 1
; CHECK-DAG:  [[A_2:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 2
; CHECK-DAG:  [[A_3:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 3
; CHECK-DAG:  [[A_4:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 4
; CHECK-DAG:  [[A_5:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 5
; CHECK-DAG:  [[A_6:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 6
; CHECK-DAG:  [[A_7:%[^ ]+]] = extractvalue [[FLOAT8]] [[A]], 7

; CHECK-DAG:  [[B_0:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 0
; CHECK-DAG:  [[B_1:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 1
; CHECK-DAG:  [[B_2:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 2
; CHECK-DAG:  [[B_3:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 3
; CHECK-DAG:  [[B_4:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 4
; CHECK-DAG:  [[B_5:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 5
; CHECK-DAG:  [[B_6:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 6
; CHECK-DAG:  [[B_7:%[^ ]+]] = extractvalue [[FLOAT8]] [[B]], 7

; CHECK-DAG:  [[SELECT_0:%[^ ]+]] = select i1 [[COND]], float [[A_0]], float [[B_0]]
; CHECK-DAG:  [[SELECT_1:%[^ ]+]] = select i1 [[COND]], float [[A_1]], float [[B_1]]
; CHECK-DAG:  [[SELECT_2:%[^ ]+]] = select i1 [[COND]], float [[A_2]], float [[B_2]]
; CHECK-DAG:  [[SELECT_3:%[^ ]+]] = select i1 [[COND]], float [[A_3]], float [[B_3]]
; CHECK-DAG:  [[SELECT_4:%[^ ]+]] = select i1 [[COND]], float [[A_4]], float [[B_4]]
; CHECK-DAG:  [[SELECT_5:%[^ ]+]] = select i1 [[COND]], float [[A_5]], float [[B_5]]
; CHECK-DAG:  [[SELECT_6:%[^ ]+]] = select i1 [[COND]], float [[A_6]], float [[B_6]]
; CHECK-DAG:  [[SELECT_7:%[^ ]+]] = select i1 [[COND]], float [[A_7]], float [[B_7]]

; CHECK-DAG:  [[TMP_0:%[^ ]+]] = insertvalue [[FLOAT8]] undef,     float [[SELECT_0]], 0
; CHECK-DAG:  [[TMP_1:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_0]], float [[SELECT_1]], 1
; CHECK-DAG:  [[TMP_2:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_1]], float [[SELECT_2]], 2
; CHECK-DAG:  [[TMP_3:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_2]], float [[SELECT_3]], 3
; CHECK-DAG:  [[TMP_4:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_3]], float [[SELECT_4]], 4
; CHECK-DAG:  [[TMP_5:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_4]], float [[SELECT_5]], 5
; CHECK-DAG:  [[TMP_6:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_5]], float [[SELECT_6]], 6
; CHECK-DAG:  [[VALUE:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_6]], float [[SELECT_7]], 7

; CHECK-NEXT: ret [[FLOAT8]] [[VALUE]]
