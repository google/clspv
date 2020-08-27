; RUN: clspv-opt %s -Scalarize -o %t.ll -hack-phis
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s = type { i32 }

define void @constant_struct(%s %in) {
entry:
  br i1 undef, label %if, label %exit

if:
  br label %exit

exit:
  %phi = phi %s [ %in, %entry ], [ { i32 1 }, %if ]
  ret void
}

; CHECK: entry:
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue %s %in, 0
; CHECK: exit:
; CHECK-NOT: phi %s
; CHECK: [[phi:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex]], %entry ], [ 1, %if ]
; CHECK: insertvalue %s zeroinitializer, i32 [[phi]], 0
