; RUN: clspv-opt -FixupStructuredCFG %s -o %t
; RUN: FileCheck %s < %t

; CHECK-LABEL: @foo
; CHECK: inner1:
; CHECK-NEXT: br i1 undef, label %inner2, label %[[new:[a-zA-Z0-9_]+]]
; CHECK: inner2:
; CHECK-NEXT: br i1 undef, label %inner1, label %[[new]]
; CHECK: [[new]]:
; CHECK-NEXT: %[[phi:[a-zA-Z0-9_]+]] = phi i32 [ 1, %inner2 ], [ 0, %inner1 ]
; CHECK-NEXT: br label %outer_latch
; CHECK: outer_latch:
; CHECK-NEXT: phi i32 [ 2, %outer ], [ %[[phi]], %[[new]] ]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(i32 %x) {
entry:
  br label %outer

outer:
  br i1 undef, label %inner1, label %outer_latch

inner1:
  br i1 undef, label %inner2, label %outer_latch

inner2:
  br i1 undef, label %inner1, label %outer_latch

outer_latch:
  %phi = phi i32 [ 0, %inner1 ], [ 1, %inner2 ], [ 2, %outer ]
  br i1 undef, label %outer, label %exit

exit:
  ret void
}


