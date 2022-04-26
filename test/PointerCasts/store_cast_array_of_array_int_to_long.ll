; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(i64 addrspace(1)* %a, [4 x [8 x i32]] addrspace(3)* %b, i32 %n) {
entry:
  %cast = bitcast [4 x [8 x i32]] addrspace(3)* %b to i64 addrspace(3)*
  %gep = getelementptr i64, i64 addrspace(3)* %cast, i32 %n
  %ld = load i64, i64 addrspace(1)* %a
  store i64 %ld, i64 addrspace(3)* %gep, align 8
  ret void
}

; CHECK: [[mul_n:%[^ ]+]] = mul i32 %n, 2
; CHECK: [[div32:%[^ ]+]] = udiv i32 [[mul_n]], 32
; CHECK: [[rem32:%[^ ]+]] = urem i32 [[mul_n]], 32
; CHECK: [[div8:%[^ ]+]] = udiv i32 [[rem32]], 8
; CHECK: [[rem8:%[^ ]+]] = urem i32 [[rem32]], 8
; CHECK: [[ld:%[^ ]+]] = load i64, i64 addrspace(1)* %a, align 8
; CHECK: [[lshr1:%[^ ]+]] = lshr i64 %ld, 0
; CHECK: [[trunc1:%[^ ]+]] = trunc i64 [[lshr1]] to i32
; CHECK: [[lshr2:%[^ ]+]] = lshr i64 %ld, 32
; CHECK: [[trunc2:%[^ ]+]] = trunc i64 [[lshr2]] to i32
; CHECK: [[gep1:%[^ ]+]] = getelementptr [4 x [8 x i32]], [4 x [8 x i32]] addrspace(3)* %b, i32 [[div32]], i32 [[div8]], i32 [[rem8]]
; CHECK: store i32 [[trunc1]], i32 addrspace(3)* [[gep1]], align 4
; CHECK: [[rem8p:%[^ ]+]] = add i32 [[rem8]], 1
; CHECK: [[gep2:%[^ ]+]] = getelementptr [4 x [8 x i32]], [4 x [8 x i32]] addrspace(3)* %b, i32 [[div32]], i32 [[div8]], i32 [[rem8p]]
; CHECK: store i32 [[trunc2]], i32 addrspace(3)* [[gep2]], align 4
