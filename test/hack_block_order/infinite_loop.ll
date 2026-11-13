; RUN: clspv-opt -hack-block-order --passes=reorder-basic-blocks %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: loop:
; CHECK: latch:
; CHECK: exit:

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_kernel void @foo(i1 %c) {
entry:
  br i1 %c, label %preheader, label %exit

preheader:
  br label %loop

loop:
  br label %latch

latch:
  br label %loop

exit:
  ret void
}
