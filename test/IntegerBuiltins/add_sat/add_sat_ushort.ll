
; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by add_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i16 @add_sat_ushort(i16 %a, i16 %b) {
entry:
 %call = call i16 @_Z7add_sattt(i16 %a, i16 %b)
 ret i16 %call
}

declare i16 @_Z7add_sattt(i16, i16)

; CHECK: [[call:%[a-zA-Z0-9_.]+]] = call { i16, i16 } @_Z8spirv.op.149.tt(i32 149, i16 %a, i16 %b)
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue { i16, i16 } [[call]], 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue { i16, i16 } [[call]], 1
; CHECK: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i16 [[ex1]], 0
; CHECK: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]], i16 [[ex0]], i16 -1
; CHECK: ret i16 [[sel]]
