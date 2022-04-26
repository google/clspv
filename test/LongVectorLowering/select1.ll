; RUN: clspv-opt --passes=replace-opencl-builtin,long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare spir_func <8 x float> @_Z6selectDv8_fS_Dv8_i(<8 x float>, <8 x float>, <8 x i32>)

define spir_func <8 x float> @test(<8 x i32> %cond, <8 x float> %a, <8 x float> %b) {
entry:
  ; This is a valid OpenCL C select overload.
  %value = call spir_func <8 x float> @_Z6selectDv8_fS_Dv8_i(<8 x float> %a, <8 x float> %b, <8 x i32> %cond)
  ret <8 x float> %value
}

; CHECK: define spir_func
; CHECK-SAME: [[FLOAT8:\[8 x float\]]]
; CHECK-SAME: @test(
; CHECK-SAME: [[INT8:\[8 x i32\]]] [[COND:%[^ ]+]],
; CHECK-SAME: [[FLOAT8]] [[A:%[^ ]+]],
; CHECK-SAME: [[FLOAT8]] [[B:%[^ ]+]]) {

; CHECK-DAG:  [[COND_0:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 0
; CHECK-DAG:  [[COND_1:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 1
; CHECK-DAG:  [[COND_2:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 2
; CHECK-DAG:  [[COND_3:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 3
; CHECK-DAG:  [[COND_4:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 4
; CHECK-DAG:  [[COND_5:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 5
; CHECK-DAG:  [[COND_6:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 6
; CHECK-DAG:  [[COND_7:%[^ ]+]] = extractvalue [[INT8]] [[COND]], 7

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

; CHECK-DAG:  [[CMP_0:%[^ ]+]] = icmp slt i32 [[COND_0]], 0
; CHECK-DAG:  [[CMP_1:%[^ ]+]] = icmp slt i32 [[COND_1]], 0
; CHECK-DAG:  [[CMP_2:%[^ ]+]] = icmp slt i32 [[COND_2]], 0
; CHECK-DAG:  [[CMP_3:%[^ ]+]] = icmp slt i32 [[COND_3]], 0
; CHECK-DAG:  [[CMP_4:%[^ ]+]] = icmp slt i32 [[COND_4]], 0
; CHECK-DAG:  [[CMP_5:%[^ ]+]] = icmp slt i32 [[COND_5]], 0
; CHECK-DAG:  [[CMP_6:%[^ ]+]] = icmp slt i32 [[COND_6]], 0
; CHECK-DAG:  [[CMP_7:%[^ ]+]] = icmp slt i32 [[COND_7]], 0

; CHECK-DAG:  [[SELECT_0:%[^ ]+]] = select i1 [[CMP_0]], float [[B_0]], float [[A_0]]
; CHECK-DAG:  [[SELECT_1:%[^ ]+]] = select i1 [[CMP_1]], float [[B_1]], float [[A_1]]
; CHECK-DAG:  [[SELECT_2:%[^ ]+]] = select i1 [[CMP_2]], float [[B_2]], float [[A_2]]
; CHECK-DAG:  [[SELECT_3:%[^ ]+]] = select i1 [[CMP_3]], float [[B_3]], float [[A_3]]
; CHECK-DAG:  [[SELECT_4:%[^ ]+]] = select i1 [[CMP_4]], float [[B_4]], float [[A_4]]
; CHECK-DAG:  [[SELECT_5:%[^ ]+]] = select i1 [[CMP_5]], float [[B_5]], float [[A_5]]
; CHECK-DAG:  [[SELECT_6:%[^ ]+]] = select i1 [[CMP_6]], float [[B_6]], float [[A_6]]
; CHECK-DAG:  [[SELECT_7:%[^ ]+]] = select i1 [[CMP_7]], float [[B_7]], float [[A_7]]

; CHECK-DAG:  [[TMP_0:%[^ ]+]] = insertvalue [[FLOAT8]] undef,     float [[SELECT_0]], 0
; CHECK-DAG:  [[TMP_1:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_0]], float [[SELECT_1]], 1
; CHECK-DAG:  [[TMP_2:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_1]], float [[SELECT_2]], 2
; CHECK-DAG:  [[TMP_3:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_2]], float [[SELECT_3]], 3
; CHECK-DAG:  [[TMP_4:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_3]], float [[SELECT_4]], 4
; CHECK-DAG:  [[TMP_5:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_4]], float [[SELECT_5]], 5
; CHECK-DAG:  [[TMP_6:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_5]], float [[SELECT_6]], 6
; CHECK-DAG:  [[VALUE:%[^ ]+]] = insertvalue [[FLOAT8]] [[TMP_6]], float [[SELECT_7]], 7

; CHECK:  ret [[FLOAT8]] [[VALUE]]
