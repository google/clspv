; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; CHECK: loop:
; CHECK-NEXT: [[phi:%[^ ]+]] = phi i32 [ 0, %entry ], [ [[add:%[^ ]+]], %inner_loop ]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [64 x i32], ptr %alloca, i32 0, i32 [[phi]]
; CHECK: load i32, ptr [[gep]], align 4
; CHECK: [[inner_add:%[^ ]+]] = add i32 1, [[phi]]
; CHECK: [[add]] = add i32 1, [[phi]]

; CHECK: inner_loop:
; CHECK-NEXT: [[phi:%[^ ]+]] = phi i32 [ [[inner_add]], %loop ], [ [[inner_loop_add:%[^ ]+]], %inner_loop ]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [64 x i32], ptr %alloca, i32 0, i32 [[phi]]
; CHECK: load i32, ptr [[gep]], align 4
; CHECK: [[inner_loop_add]] = add i32 1, [[phi]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  %alloca = alloca [64 x i32]
  br label %loop

loop:
  %phi = phi ptr [ %alloca, %entry ], [ %gep, %inner_loop ]
  %count = phi i32 [ 0, %entry ], [ %next, %inner_loop ]
  %load = load i32, ptr %phi
  %gep = getelementptr i32, ptr %phi, i32 1
  %next = add i32 %count, 1
  %cmp = icmp eq i32 %next, 64
  br i1 %cmp, label %exit, label %inner_loop

inner_loop:
  %inner_phi = phi ptr [ %gep, %loop ], [ %inner_gep, %inner_loop]
  %inner_count = phi i32 [ 0, %loop ], [ %inner_next, %inner_loop ]
  %inner_load = load i32, ptr %inner_phi
  %inner_gep = getelementptr i32, ptr %inner_phi, i32 1
  %inner_next = add i32 %inner_count, 2
  %inner_cmp = icmp eq i32 %inner_next, 64
  br i1 %inner_cmp, label %loop, label %inner_loop

exit:
  ret void
}
