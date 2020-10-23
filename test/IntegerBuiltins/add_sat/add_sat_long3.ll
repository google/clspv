
; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by add_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x i64> @add_sat_long3(<3 x i64> %a, <3 x i64> %b) {
entry:
 %call = call <3 x i64> @_Z7add_satDv3_lS_(<3 x i64> %a, <3 x i64> %b)
 ret <3 x i64> %call
}

declare <3 x i64> @_Z7add_satDv3_lS_(<3 x i64>, <3 x i64>)

; CHECK: [[add:%[a-zA-Z0-9_.]+]] = add <3 x i64> %a, %b
; CHECK: [[a_lt0:%[a-zA-Z0-9_.]+]] = icmp slt <3 x i64> %a, zeroinitializer
; CHECK: [[b_lt0:%[a-zA-Z0-9_.]+]] = icmp slt <3 x i64> %b, zeroinitializer
; CHECK: [[both_neg:%[a-zA-Z0-9_.]+]] = and <3 x i1> [[a_lt0]], [[b_lt0]]
; CHECK: [[a_ge0:%[a-zA-Z0-9_.]+]] = xor <3 x i1> [[a_lt0]], <i1 true, i1 true, i1 true>
; CHECK: [[b_ge0:%[a-zA-Z0-9_.]+]] = xor <3 x i1> [[b_lt0]], <i1 true, i1 true, i1 true>
; CHECK: [[both_pos:%[a-zA-Z0-9_.]+]] = and <3 x i1> [[a_ge0]], [[b_ge0]]
; CHECK: [[add_ge0:%[a-zA-Z0-9_.]+]] = icmp sge <3 x i64> [[add]], zeroinitializer
; CHECK: [[add_lt0:%[a-zA-Z0-9_.]+]] = icmp slt <3 x i64> [[add]], zeroinitializer
; CHECK: [[pos_clamp:%[a-zA-Z0-9_.]+]] = select <3 x i1> [[add_lt0]], <3 x i64> <i64 9223372036854775807, i64 9223372036854775807, i64 9223372036854775807>, <3 x i64> [[add]]
; CHECK: [[neg_clamp:%[a-zA-Z0-9_.]+]] = select <3 x i1> [[add_ge0]], <3 x i64> <i64 -9223372036854775808, i64 -9223372036854775808, i64 -9223372036854775808>, <3 x i64> [[add]]
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <3 x i1> [[both_neg]], <3 x i64> [[neg_clamp]], <3 x i64> [[add]]
; CHECK: [[sel2:%[a-zA-Z0-9_.]+]] = select <3 x i1> [[both_pos]], <3 x i64> [[pos_clamp]], <3 x i64> [[sel]]
; CHECK: ret <3 x i64> [[sel2]]
