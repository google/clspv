; RUN: clspv-opt %s --passes=spirv-producer -producer-out-file %t.spv -o %t.ll 2>&1 | FileCheck %s
; CHECK: error: loops must have a single exit and latch block

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_func void @multi_latch(i1 %c1, i1 %c2) {
entry:
  br label %loop.header

loop.header:                                      ; preds = %latch1, %latch2, %entry
  br i1 %c1, label %latch1, label %latch2

latch1:                                           ; preds = %loop.header
  br i1 %c2, label %loop.header, label %exit

latch2:                                           ; preds = %loop.header
  br label %loop.header

exit:                                             ; preds = %latch1
  ret void
}
