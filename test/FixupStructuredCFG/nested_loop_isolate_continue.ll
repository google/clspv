; RUN: clspv-opt --passes=fixup-structured-cfg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: @foo
; CHECK: inner:
; CHECK-NEXT: br i1 undef, label %inner, label %[[inner_exit:[a-zA-Z0-9_.]+]]
; CHECK: [[inner_exit]]:
; CHECK-NEXT: br label %middle_latch
; CHECK: middle_latch:
; CHECK-NEXT: br i1 undef, label %middle, label %[[middle_exit:[a-zA-Z0-9_.]+]]
; CHECK: [[middle_exit]]:
; CHECK-NEXT: br label %outer_latch
; CHECK: outer_latch:
; CHECK-NEXT: br i1 undef, label %outer, label %exit

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @foo() {
entry:
  br label %outer

outer:
  br label %middle

middle:
  br label %inner

inner:
  br i1 undef, label %inner, label %middle_latch

middle_latch:
  br i1 undef, label %middle, label %outer_latch

outer_latch:
  br i1 undef, label %outer, label %exit

exit:
  ret void
}
