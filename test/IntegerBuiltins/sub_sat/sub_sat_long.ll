
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by sub_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i64 @sub_sat_long(i64 %a, i64 %b) {
entry:
 %call = call i64 @_Z7sub_satll(i64 %a, i64 %b)
 ret i64 %call
}

declare i64 @_Z7sub_satll(i64, i64)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub i64 %a, %b
; CHECK: [[b_lt_0:%[a-zA-Z0-9_.]+]] = icmp slt i64 %b, 0
; CHECK: [[sub_gt_a:%[a-zA-Z0-9_.]+]] = icmp sgt i64 [[sub]], %a
; CHECK: [[sub_lt_a:%[a-zA-Z0-9_.]+]] = icmp slt i64 [[sub]], %a
; CHECK: [[neg_clamp:%[a-zA-Z0-9_.]+]] = select i1 [[sub_lt_a]], i64 9223372036854775807, i64 [[sub]]
; CHECK: [[pos_clamp:%[a-zA-Z0-9_.]+]] = select i1 [[sub_gt_a]], i64 -9223372036854775808, i64 [[sub]]
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[b_lt_0]], i64 [[neg_clamp]], i64 [[pos_clamp]]
; CHECK: ret i64 [[sel]]
