; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %a, ptr addrspace(3) %b, i32 %n) {
entry:
  %cast = getelementptr [4 x [8 x i32]], ptr addrspace(3) %b, i32 0
  %gep = getelementptr i32, ptr addrspace(3) %cast, i32 %n
  %ld = load i32, ptr addrspace(3) %gep
  store i32 %ld, ptr addrspace(1) %a, align 4
  ret void
}

; CHECK: [[div32:%[^ ]+]] = lshr i32 %n, 5
; CHECK: [[rem32:%[^ ]+]] = and i32 %n, 31
; CHECK: [[div8:%[^ ]+]] = lshr i32 [[rem32]], 3
; CHECK: [[rem8:%[^ ]+]] = and i32 [[rem32]], 7
; CHECK: [[gep:%[^ ]+]] = getelementptr [4 x [8 x i32]], ptr addrspace(3) %cast, i32 [[div32]], i32 [[div8]], i32 [[rem8]]
; CHECK: [[ld:%[^ ]+]] = load i32, ptr addrspace(3) [[gep]], align 4
; CHECK: store i32 [[ld]], ptr addrspace(1) %a, align 4

