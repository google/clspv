
; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by sub_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @sub_sat_int(i32 %a, i32 %b) {
entry:
 %call = call i32 @_Z7sub_satii(i32 %a, i32 %b)
 ret i32 %call
}

declare i32 @_Z7sub_satii(i32, i32)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub i32 %a, %b
; CHECK: [[b_lt_0:%[a-zA-Z0-9_.]+]] = icmp slt i32 %b, 0
; CHECK: [[sub_gt_a:%[a-zA-Z0-9_.]+]] = icmp sgt i32 [[sub]], %a
; CHECK: [[sub_lt_a:%[a-zA-Z0-9_.]+]] = icmp slt i32 [[sub]], %a
; CHECK: [[neg_clamp:%[a-zA-Z0-9_.]+]] = select i1 [[sub_lt_a]], i32 2147483647, i32 [[sub]]
; CHECK: [[pos_clamp:%[a-zA-Z0-9_.]+]] = select i1 [[sub_gt_a]], i32 -2147483648, i32 [[sub]]
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[b_lt_0]], i32 [[neg_clamp]], i32 [[pos_clamp]]
; CHECK: ret i32 [[sel]]
