; RUN: clspv-opt --passes=fixup-structured-cfg %s -o %t
; RUN: FileCheck %s < %t

; CHECK-LABEL: @foo
; CHECK: inner:
; CHECK-NEXT: br i1 undef, label %inner, label %[[new:[a-zA-Z0-9_]+]]
; CHECK: [[new]]:
; CHECK-NEXT: br label %outer_latch
; CHECK: outer_latch:
; CHECK-NEXT: phi i32 [ 0, %[[new]] ], [ 1, %outer ]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(i32 %x) {
entry:
  br label %outer

outer:
  br i1 undef, label %inner, label %outer_latch

inner:
  br i1 undef, label %inner, label %outer_latch

outer_latch:
  %phi = phi i32 [ 0, %inner ], [ 1, %outer ]
  br i1 undef, label %outer, label %exit

exit:
  ret void
}

