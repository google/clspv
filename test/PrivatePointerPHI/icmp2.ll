; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; CHECK: entry:
; CHECK-NEXT: [[alloca:%[^ ]+]] = alloca [64 x i32]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [64 x i32], ptr [[alloca]], i32 0, i32 0
; CHECK: [[ptrtoint:%[^ ]+]] = ptrtoint ptr [[gep]] to i32
; CHECK: [[add_entry:%[^ ]+]] = add i32 %m, %n

; CHECK: [[phi:%[^ ]+]] = phi i32 [ [[add_entry]], %else ], [ [[add_loop:%[^ ]+]], %loop ], [ [[add_entry]], %if ]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [64 x i32], ptr [[alloca]], i32 0, i32 [[phi]]
; CHECK: load i32, ptr [[gep]], align 4
; CHECK: [[add_loop]] = add i32 1, [[phi]]
; CHECK: [[icmp:%[^ ]+]] = icmp eq i32 [[phi]], [[ptrtoint]]
; CHECK: br i1 [[icmp]], label %exit, label %loop

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test(i32 %n, i32 %m) {
entry:
  %alloca = alloca [64 x i32]
  %ptrtoint = ptrtoint ptr %alloca to i32
  %pregep0 = getelementptr i32, ptr %alloca, i32 %m
  %pregep = getelementptr i32, ptr %pregep0, i32 %n
  %test = icmp ne i32 %n, 0
  br i1 %test, label %else, label %if

else:
  br label %loop

if:
  br label %loop

loop:
  %phi = phi ptr [ %pregep, %else ], [ %pregep, %if ], [ %gep, %loop ]
  %load = load i32, ptr %phi
  %gep = getelementptr i32, ptr %phi, i32 1
  %inttoptr = inttoptr i32 %ptrtoint to ptr
  %cmp = icmp eq ptr %phi, %inttoptr
  br i1 %cmp, label %exit, label %loop

exit:
  ret void
}
