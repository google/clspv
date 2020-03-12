; RUN: clspv-opt --RemoveUnusedArguments %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: @bar(float [[y:%[a-zA-Z0-9_.]+]]) {
; CHECK: ret float [[y]]

define float @bar(float %x, float %y, float %z) {
entry:
  ret float %y
}

