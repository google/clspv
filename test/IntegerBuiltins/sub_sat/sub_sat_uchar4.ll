
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by sub_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <4 x i8> @sub_sat_uchar4(<4 x i8> %a, <4 x i8> %b) {
entry:
 %call = call <4 x i8> @_Z7sub_satDv4_hS_(<4 x i8> %a, <4 x i8> %b)
 ret <4 x i8> %call
}

declare <4 x i8> @_Z7sub_satDv4_hS_(<4 x i8>, <4 x i8>)

; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call { <4 x i8>, <4 x i8> } @_Z8spirv.op.150.Dv4_hDv4_h(i32 150, <4 x i8> %a, <4 x i8> %b)
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue { <4 x i8>, <4 x i8> } [[call]], 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue { <4 x i8>, <4 x i8> } [[call]], 1
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq <4 x i8> [[ex1]], zeroinitializer
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select <4 x i1> [[cmp]], <4 x i8> [[ex0]], <4 x i8> zeroinitializer
; CHECK: ret <4 x i8> [[sel]]
