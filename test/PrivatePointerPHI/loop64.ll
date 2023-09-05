; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; CHECK: loop:
; CHECK-NEXT: [[phi:%[^ ]+]] = phi i64 [ 0, %entry ], [ [[add:%[^ ]+]], %loop ]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [64 x i32], ptr %alloca, i32 0, i64 [[phi]]
; CHECK: load i32, ptr [[gep]], align 4
; CHECK: [[add]] = add i64 1, [[phi]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define void @test() {
entry:
  %alloca = alloca [64 x i32]
  br label %loop

loop:
  %phi = phi ptr [ %alloca, %entry ], [ %gep, %loop ]
  %count = phi i32 [ 0, %entry ], [ %next, %loop ]
  %load = load i32, ptr %phi
  %gep = getelementptr i32, ptr %phi, i32 1
  %next = add i32 %count, 1
  %cmp = icmp eq i32 %next, 64
  br i1 %cmp, label %exit, label %loop

exit:
  ret void
}
