; RUN: clspv-opt %s --passes=spirv-producer -producer-out-file %t.spv -o %t.ll 2>&1 | FileCheck %s
; CHECK: error: loops must have a single exit and latch block

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define spir_func void @multi_exit(i1 %c1, i1 %c2) {
entry:
  br label %loop.header

loop.header:                                      ; preds = %loop.latch, %entry
  br i1 %c1, label %loop.latch, label %exit1

loop.latch:                                       ; preds = %loop.header
  br i1 %c2, label %loop.header, label %exit2

exit1:                                            ; preds = %loop.header
  ret void

exit2:                                            ; preds = %loop.latch
  ret void
}
