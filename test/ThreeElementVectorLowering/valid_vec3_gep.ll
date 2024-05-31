; RUN: clspv-opt %s -o %t.ll --passes=three-element-vector-lowering
; RUN: FileCheck %s < %t.ll

; CHECK:  getelementptr inbounds <3 x i32>, ptr %a, i32 2, i32 2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test1(ptr %a) {
entry:
  %gep = getelementptr inbounds <3 x i32>, ptr %a, i32 2, i32 2
  ret void
}
