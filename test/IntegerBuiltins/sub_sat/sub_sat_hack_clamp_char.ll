
; RUN: clspv-opt -ReplaceOpenCLBuiltin -hack-clamp-width %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by sub_sat_test_gen.cpp.
; Please modify the that file and regenerate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i8 @sub_sat_char(i8 %a, i8 %b) {
entry:
 %call = call i8 @_Z7sub_satcc(i8 %a, i8 %b)
 ret i8 %call
}

declare i8 @_Z7sub_satcc(i8, i8)

; CHECK: [[sext_a:%[a-zA-Z0-9_.]+]] = sext i8 %a to i32
; CHECK: [[sext_b:%[a-zA-Z0-9_.]+]] = sext i8 %b to i32
; CHECK: [[sub:%[a-zA-Z0-9_.]+]] = sub nuw nsw i32 [[sext_a]], [[sext_b]]
; CHECK: [[clamp:%[a-zA-Z0-9_.]+]] = call i32 @_Z5clampiii(i32 [[sub]], i32 -128, i32 127)
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[clamp]] to i8
; CHECK: ret i8 [[trunc]]
