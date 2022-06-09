; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(i64 addrspace(1)* %a, [4 x [8 x i32]] addrspace(3)* %b, i32 %n) {
entry:
  %cast = bitcast [4 x [8 x i32]] addrspace(3)* %b to i64 addrspace(3)*
  %gep = getelementptr i64, i64 addrspace(3)* %cast, i32 %n
  %ld = load i64, i64 addrspace(3)* %gep
  store i64 %ld, i64 addrspace(1)* %a, align 8
  ret void
}

; CHECK: [[mul_n:%[^ ]+]] = shl i32 %n, 1
; CHECK: [[div32:%[^ ]+]] = lshr i32 [[mul_n]], 5
; CHECK: [[rem32:%[^ ]+]] = and i32 [[mul_n]], 31
; CHECK: [[div8:%[^ ]+]] = lshr i32 [[rem32]], 3
; CHECK: [[rem8:%[^ ]+]] = and i32 [[rem32]], 7
; CHECK: [[gep1:%[^ ]+]] = getelementptr [4 x [8 x i32]], [4 x [8 x i32]] addrspace(3)* %b, i32 [[div32]], i32 [[div8]], i32 [[rem8]]
; CHECK: [[ld1:%[^ ]+]] = load i32, i32 addrspace(3)* [[gep1]], align 4
; CHECK: [[rem8p:%[^ ]+]] = add i32 [[rem8]], 1
; CHECK: [[gep2:%[^ ]+]] = getelementptr [4 x [8 x i32]], [4 x [8 x i32]] addrspace(3)* %b, i32 [[div32]], i32 [[div8]], i32 [[rem8p]]
; CHECK: [[ld2:%[^ ]+]] = load i32, i32 addrspace(3)* [[gep2]], align 4
; CHECK: [[ins0:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[ld1]], i32 0
; CHECK: [[ins1:%[^ ]+]] = insertelement <2 x i32> [[ins0]], i32 [[ld2]], i32 1
; CHECK: [[bitcast:%[^ ]+]] = bitcast <2 x i32> [[ins1]] to i64
; CHECK: store i64 [[bitcast]], i64 addrspace(1)* %a, align 8
