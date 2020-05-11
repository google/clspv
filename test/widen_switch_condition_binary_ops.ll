; RUN: clspv-opt -UndoTruncatedSwitchCondition %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @subf(i32 %x, i32 %y) {
entry:
  ; CHECK-LABEL subf
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 %mul, 7
  ; CHECK-NEXT: [[sub:%[a-zA-Z0-9_]+]] = sub i32 4, [[and]]
  ; CHECK-NEXT: [[sub_mask:%[a-zA-Z0-9_]+]] = and i32 [[sub]], 7
  ; CHECK-NEXT: switch i32 [[sub_mask]], label %default [
  ; CHECK-NEXT:   i32 1, label %one_label
  ; CHECK-NEXT:   i32 2, label %two_label
  ; CHECK-NEXT:   i32 3, label %three_label
  ; CHECK-NEXT:   i32 4, label %four_label
  %mul = mul i32 %x, %y
  %trunc = trunc i32 %mul to i3
  %sub = sub nuw i3 -4, %trunc
  switch i3 %sub, label %default [
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

define spir_kernel void @addf(i32 %x, i32 %y) {
entry:
  ; CHECK-LABEL addf
  ; CHECK: [[and:%[a-zA-Z0-9_]+]] = and i32 %mul, 31
  ; CHECK-NEXT: [[add:%[a-zA-Z0-9_]+]] = add i32 16, [[and]]
  ; CHECK-NEXT: [[add_mask:%[a-zA-Z0-9_]+]] = and i32 [[add]], 31
  ; CHECK-NEXT: switch i32 [[add_mask]], label %default [
  ; CHECK-NEXT:   i32 1, label %one_label
  ; CHECK-NEXT:   i32 2, label %two_label
  ; CHECK-NEXT:   i32 3, label %three_label
  ; CHECK-NEXT:   i32 16, label %sixteen_label
  %mul = mul i32 %x, %y
  %trunc = trunc i32 %mul to i5
  %add = add nuw i5 -16, %trunc
  switch i5 %add, label %default [
    i5 1, label %one_label
    i5 2, label %two_label
    i5 3, label %three_label
    i5 -16, label %sixteen_label
  ]

default:
  br label %exit

one_label:
  br label %exit

two_label:
  br label %exit

three_label:
  br label %exit

sixteen_label:
  br label %exit

exit:
  ret void
}

