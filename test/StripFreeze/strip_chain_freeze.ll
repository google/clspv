; RUN: clspv-opt %s -o %t.ll -StripFreeze
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-NOT: freeze i32
; CHECK: ret i32 %in
define i32 @foo(i32 %in) {
entry:
  %freeze1 = freeze i32 %in
  %freeze2 = freeze i32 %freeze1
  ret i32 %freeze2
}

