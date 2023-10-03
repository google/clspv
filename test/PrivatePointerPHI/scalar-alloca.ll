; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; CHECK: entry:
; CHECK-NEXT: [[alloca:%[^ ]+]] = alloca i32, align 4

; CHECK: [[phi:%[^ ]+]] = phi i32 [ 0, %entry ], [ undef, %if ]
; CHECK: load i32, ptr [[alloca]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  %alloca = alloca i32, align 4
  br label %if

if:
  %phi = phi ptr [ undef, %if ], [ %alloca, %entry ]
  %load = load i32, ptr %phi
  %cmp = icmp eq i32 %load, 32
  br i1 %cmp, label %exit, label %if

exit:
  ret void
}
