; RUN: clspv-opt %s -o %t.ll --passes=replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @fshr_i8(ptr addrspace(1) %out, i8 %a, i8 %b, i8 %c) {
entry:
  %result = call i8 @llvm.fshr.i8(i8 %a, i8 %b, i8 %c)
  store i8 %result, ptr addrspace(1) %out
  ret void
}

declare i8 @llvm.fshr.i8(i8, i8, i8)

; CHECK-NOT: llvm.fshr
; CHECK: [[and:%[0-9a-zA-Z_.]+]] = and i8 %c, 7
; CHECK: [[sub:%[0-9a-zA-Z_.]+]] = sub i8 8, [[and]]
; CHECK: [[and2:%[0-9a-zA-Z_.]+]] = and i8 [[sub]], 7
; CHECK: [[shl:%[0-9a-zA-Z_.]+]] = shl i8 %a, [[and2]]
; CHECK: [[lshr:%[0-9a-zA-Z_.]+]] = lshr i8 %b, [[and]]
; CHECK: [[or:%[0-9a-zA-Z_.]+]] = or i8 [[lshr]], [[shl]]
; CHECK: store i8 [[or]], ptr addrspace(1) %out



define void @fshr_i16(ptr addrspace(1) %out, i16 %a, i16 %b, i16 %c) {
entry:
  %result = call i16 @llvm.fshr.i16(i16 %a, i16 %b, i16 %c)
  store i16 %result, ptr addrspace(1) %out
  ret void
}

declare i16 @llvm.fshr.i16(i16, i16, i16)

; CHECK-NOT: llvm.fshr
; CHECK: [[and:%[0-9a-zA-Z_.]+]] = and i16 %c, 15
; CHECK: [[sub:%[0-9a-zA-Z_.]+]] = sub i16 16, [[and]]
; CHECK: [[and2:%[0-9a-zA-Z_.]+]] = and i16 [[sub]], 15
; CHECK: [[shl:%[0-9a-zA-Z_.]+]] = shl i16 %a, [[and2]]
; CHECK: [[lshr:%[0-9a-zA-Z_.]+]] = lshr i16 %b, [[and]]
; CHECK: [[or:%[0-9a-zA-Z_.]+]] = or i16 [[lshr]], [[shl]]
; CHECK: store i16 [[or]], ptr addrspace(1) %out



define void @fshr_i32(ptr addrspace(1) %out, i32 %a, i32 %b, i32 %c) {
entry:
  %result = call i32 @llvm.fshr.i32(i32 %a, i32 %b, i32 %c)
  store i32 %result, ptr addrspace(1) %out
  ret void
}

declare i32 @llvm.fshr.i32(i32, i32, i32)

; CHECK-NOT: llvm.fshr
; CHECK: [[and:%[0-9a-zA-Z_.]+]] = and i32 %c, 31
; CHECK: [[sub:%[0-9a-zA-Z_.]+]] = sub i32 32, [[and]]
; CHECK: [[and2:%[0-9a-zA-Z_.]+]] = and i32 [[sub]], 31
; CHECK: [[shl:%[0-9a-zA-Z_.]+]] = shl i32 %a, [[and2]]
; CHECK: [[lshr:%[0-9a-zA-Z_.]+]] = lshr i32 %b, [[and]]
; CHECK: [[or:%[0-9a-zA-Z_.]+]] = or i32 [[lshr]], [[shl]]
; CHECK: store i32 [[or]], ptr addrspace(1) %



define void @fshr_i64(ptr addrspace(1) %out, i64 %a, i64 %b, i64 %c) {
entry:
  %result = call i64 @llvm.fshr.i64(i64 %a, i64 %b, i64 %c)
  store i64 %result, ptr addrspace(1) %out
  ret void
}

declare i64 @llvm.fshr.i64(i64, i64, i64)

; CHECK-NOT: llvm.fshr
; CHECK: [[and:%[0-9a-zA-Z_.]+]] = and i64 %c, 63
; CHECK: [[sub:%[0-9a-zA-Z_.]+]] = sub i64 64, [[and]]
; CHECK: [[and2:%[0-9a-zA-Z_.]+]] = and i64 [[sub]], 63
; CHECK: [[shl:%[0-9a-zA-Z_.]+]] = shl i64 %a, [[and2]]
; CHECK: [[lshr:%[0-9a-zA-Z_.]+]] = lshr i64 %b, [[and]]
; CHECK: [[or:%[0-9a-zA-Z_.]+]] = or i64 [[lshr]], [[shl]]
; CHECK: store i64 [[or]], ptr addrspace(1) %out