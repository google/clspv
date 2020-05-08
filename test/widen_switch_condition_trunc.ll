; RUN: clspv-opt -UndoTruncatedSwitchCondition %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @truncf(i32 %x) {
entry:
  ; CHECK-LABEL trunc
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 %x, 7
  ; CHECK-NEXT: switch i32 [[and]], label %default [
  ; CHECK-NEXT:   i32 1, label %one_label
  ; CHECK-NEXT:   i32 2, label %two_label
  ; CHECK-NEXT:   i32 3, label %three_label
  ; CHECK-NEXT:   i32 4, label %four_label
  %trunc = trunc i32 %x to i3
  switch i3 %trunc, label %default [
    i3 1, label %one_label
    i3 2, label %two_label
    i3 3, label %three_label
    i3 -4, label %four_label
  ]

default:
  br label %exit

one_label:
  br label %exit

two_label:
  br label %exit

three_label:
  br label %exit

four_label:
  br label %exit

exit:
  ret void
}
