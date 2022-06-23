; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; CHECK: getelementptr [8 x i32], ptr %alloca, i32 0, i32 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  %alloca = alloca <8 x i32>, align 32
  %gep = getelementptr <8 x i32>, ptr %alloca, i32 0, i32 1
  ret void
}
