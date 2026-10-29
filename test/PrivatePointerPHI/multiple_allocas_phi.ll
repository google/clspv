; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; %a and %b are merged into a single alloca, so that the PHI of pointers to
; either of them can be lowered into a PHI of indices.

; CHECK: entry:
; CHECK-NEXT: [[alloca:%[^ ]+]] = alloca [2 x i32], align 4
; CHECK-NEXT: [[a:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 0
; CHECK-NEXT: store i32 0, ptr [[a]], align 4
; CHECK-NEXT: [[b:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 1
; CHECK-NEXT: store i32 0, ptr [[b]], align 4

; CHECK: loop:
; CHECK: [[phi:%[^ ]+]] = phi i32 [ 0, %entry ], [ 1, %loop ]
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 [[phi]]
; CHECK: store i32 %ld, ptr [[gep]], align 4

; CHECK: exit:
; CHECK-NEXT: [[a2:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 0
; CHECK-NEXT: [[va:%[^ ]+]] = load i32, ptr [[a2]], align 4
; CHECK-NEXT: [[b2:%[^ ]+]] = getelementptr inbounds [2 x i32], ptr [[alloca]], i32 0, i32 1
; CHECK-NEXT: [[vb:%[^ ]+]] = load i32, ptr [[b2]], align 4
; CHECK-NEXT: sub i32 [[va]], [[vb]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define void @test(ptr addrspace(1) %in, ptr addrspace(1) %out) {
entry:
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  store i32 0, ptr %a, align 4
  store i32 0, ptr %b, align 4
  br label %loop

loop:
  %first = phi i1 [ true, %entry ], [ false, %loop ]
  %ptr = phi ptr [ %a, %entry ], [ %b, %loop ]
  %idx = phi i32 [ 0, %entry ], [ 1, %loop ]
  %gep = getelementptr i32, ptr addrspace(1) %in, i32 %idx
  %ld = load i32, ptr addrspace(1) %gep, align 4
  store i32 %ld, ptr %ptr, align 4
  br i1 %first, label %loop, label %exit

exit:
  %va = load i32, ptr %a, align 4
  %vb = load i32, ptr %b, align 4
  %sub = sub i32 %va, %vb
  store i32 %sub, ptr addrspace(1) %out, align 4
  ret void
}
