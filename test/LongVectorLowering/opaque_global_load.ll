; RUN: clspv-opt --passes=long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: [[gv:@[a-zA-Z0-9_.]+]] = internal global [8 x i32] zeroinitializer
; CHECK: load [8 x i32], ptr [[gv]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@gv = internal global <8 x i32> zeroinitializer

define void @test() {
entry:
  %ld = load <8 x i32>, ptr @gv
  ret void
}
