; RUN: clspv-opt --passes=undo-truncate-to-odd-integer %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i8 @multiple_trunc(i8 %a, i8 %b) {
entry:
  ; CHECK-LABEL multiple_trunc
  ; CHECK: [[and_a:%[a-zA-Z0-9_.]+]] = and i8 %a, 3
  ; CHECK-NEXT: [[and_b:%[a-zA-Z0-9_.]+]] = and i8 %b, 3
  ; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = mul i8 [[and_a]], [[and_b]]
  ; CHECK-NEXT: [[and:%[a-zA-Z0-9_.]+]] = and i8 [[mul]], 3
  ; CHECK-NEXT: ret i8 [[and]]
  %trunc_a = trunc i8 %a to i2
  %trunc_b = trunc i8 %b to i2
  %mul = mul i2 %trunc_a, %trunc_b
  %zext = zext i2 %mul to i8
  ret i8 %zext
}

