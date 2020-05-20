; RUN: clspv-opt -UndoTruncateToOddInteger %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @ret_i32a(i32 %a, i8 %b) {
entry:
  ; CHECK-LABEL ret_i32a
  ; CHECK: [[trunc_a:%[a-zA-Z0-9_.]+]] = trunc i32 %a to i8
  ; CHECK-NEXT: [[and_a:%[a-zA-Z0-9_.]+]] = and i8 [[trunc_a]], 3
  ; CHECK-NEXT: [[and_b:%[a-zA-Z0-9_.]+]] = and i8 %b, 3
  ; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = mul i8 [[and_a]], [[and_b]]
  ; CHECK-NEXT: [[and:%[a-zA-Z0-9_.]+]] = and i8 [[mul]], 3
  ; CHECK-NEXT: [[zext:%[a-zA-Z0-9_.]+]] = zext i8 [[and]] to i32
  ; CHECK-NEXT: ret i32 [[zext]]
  %trunc_a = trunc i32 %a to i2
  %trunc_b = trunc i8 %b to i2
  %mul = mul i2 %trunc_a, %trunc_b
  %zext = zext i2 %mul to i32
  ret i32 %zext
}

define i8 @ret_i8a(i32 %a, i8 %b) {
entry:
  ; CHECK-LABEL ret_i8a
  ; CHECK: [[trunc_a:%[a-zA-Z0-9_.]+]] = trunc i32 %a to i8
  ; CHECK-NEXT: [[and_a:%[a-zA-Z0-9_.]+]] = and i8 [[trunc_a]], 3
  ; CHECK-NEXT: [[and_b:%[a-zA-Z0-9_.]+]] = and i8 %b, 3
  ; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = mul i8 [[and_a]], [[and_b]]
  ; CHECK-NEXT: [[and:%[a-zA-Z0-9_.]+]] = and i8 [[mul]], 3
  ; CHECK-NEXT: ret i8 [[and]]
  %trunc_a = trunc i32 %a to i2
  %trunc_b = trunc i8 %b to i2
  %mul = mul i2 %trunc_a, %trunc_b
  %zext = zext i2 %mul to i8
  ret i8 %zext
}

define i32 @ret_i32b(i8 %a, i32 %b) {
entry:
  ; CHECK-LABEL ret_i32b
  ; CHECK: [[zext_a:%[a-zA-Z0-9_.]+]] = zext i8 %a to i32
  ; CHECK-NEXT: [[and_a:%[a-zA-Z0-9_.]+]] = and i32 [[zext_a]], 3
  ; CHECK-NEXT: [[and_b:%[a-zA-Z0-9_.]+]] = and i32 %b, 3
  ; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 [[and_a]], [[and_b]]
  ; CHECK-NEXT: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[mul]], 3
  ; CHECK-NEXT: ret i32 [[and]]
  %trunc_a = trunc i8 %a to i2
  %trunc_b = trunc i32 %b to i2
  %mul = mul i2 %trunc_a, %trunc_b
  %zext = zext i2 %mul to i32
  ret i32 %zext
}

define i8 @ret_i8b(i8 %a, i32 %b) {
entry:
  ; CHECK-LABEL ret_i8a
  ; CHECK: [[zext_a:%[a-zA-Z0-9_.]+]] = zext i8 %a to i32
  ; CHECK-NEXT: [[and_a:%[a-zA-Z0-9_.]+]] = and i32 [[trunc_a]], 3
  ; CHECK-NEXT: [[and_b:%[a-zA-Z0-9_.]+]] = and i32 %b, 3
  ; CHECK-NEXT: [[mul:%[a-zA-Z0-9_.]+]] = mul i32 [[and_a]], [[and_b]]
  ; CHECK-NEXT: [[and:%[a-zA-Z0-9_.]+]] = and i32 [[mul]], 3
  ; CHECK-NEXT: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i32 [[and]] to i8
  ; CHECK-NEXT: ret i8 [[trunc]]
  %trunc_a = trunc i8 %a to i2
  %trunc_b = trunc i32 %b to i2
  %mul = mul i2 %trunc_a, %trunc_b
  %zext = zext i2 %mul to i8
  ret i8 %zext
}

