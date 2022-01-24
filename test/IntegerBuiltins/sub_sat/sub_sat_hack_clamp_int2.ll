
; RUN: clspv-opt -ReplaceOpenCLBuiltin -hack-clamp-width %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by sub_sat_hack_clamp_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <2 x i32> @sub_sat_int2(<2 x i32> %a, <2 x i32> %b) {
entry:
 %call = call <2 x i32> @_Z7sub_satDv2_iS_(<2 x i32> %a, <2 x i32> %b)
 ret <2 x i32> %call
}

declare <2 x i32> @_Z7sub_satDv2_iS_(<2 x i32>, <2 x i32>)

; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub <2 x i32> %a, %b
; CHECK: [[b_lt_0:%[a-zA-Z0-9_.]+]] = icmp slt <2 x i32> %b, zeroinitializer
; CHECK: [[sub_gt_a:%[a-zA-Z0-9_.]+]] = icmp sgt <2 x i32> [[sub]], %a
; CHECK: [[sub_lt_a:%[a-zA-Z0-9_.]+]] = icmp slt <2 x i32> [[sub]], %a
; CHECK: [[neg_clamp:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[sub_lt_a]], <2 x i32> <i32 2147483647, i32 2147483647>, <2 x i32> [[sub]]
; CHECK: [[pos_clamp:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[sub_gt_a]], <2 x i32> <i32 -2147483648, i32 -2147483648>, <2 x i32> [[sub]]
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <2 x i1> [[b_lt_0]], <2 x i32> [[neg_clamp]], <2 x i32> [[pos_clamp]]
; CHECK: ret <2 x i32> [[sel]]
