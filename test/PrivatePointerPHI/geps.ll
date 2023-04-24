; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; CHECK: loop:
; CHECK-NEXT: [[phi16:%[^ ]+]] = phi i32 [ 0, %entry ], [ [[add16:%[^ ]+]], %loop ]
; CHECK-NEXT: [[phi32:%[^ ]+]] = phi i32 [ 0, %entry ], [ [[add32:%[^ ]+]], %loop ]
; CHECK: [[gep16:%[^ ]+]] = getelementptr inbounds [64 x i8], ptr %alloca, i32 0, i32 [[phi16]]
; CHECK: load i16, ptr [[gep16]], align 2
; CHECK: [[shl:%[^ ]+]] = shl i32 %n, 1
; CHECK: [[add16]] = add i32 [[phi16]], [[shl]]
; CHECK: [[gep32:%[^ ]+]] = getelementptr inbounds [64 x i8], ptr %alloca, i32 0, i32 [[phi32]]
; CHECK: load i32, ptr [[gep32]], align 4
; CHECK: [[shl:%[^ ]+]] = shl i32 %n, 2
; CHECK: [[add32]] = add i32 [[phi32]], [[shl]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(i32 %n) {
entry:
  %alloca = alloca [64 x i8]
  br label %loop

loop:
  %phi16 = phi ptr [ %alloca, %entry ], [ %gep16, %loop ]
  %phi32 = phi ptr [ %alloca, %entry ], [ %gep32, %loop ]
  %count = phi i32 [ 0, %entry ], [ %next, %loop ]
  %load16 = load i16, ptr %phi16
  %gep16 = getelementptr i16, ptr %phi16, i32 %n
  %load32 = load i32, ptr %phi32
  %gep32 = getelementptr i32, ptr %phi32, i32 %n
  %next = add i32 %count, 1
  %cmp = icmp eq i32 %next, 64
  br i1 %cmp, label %exit, label %loop

exit:
  ret void
}
