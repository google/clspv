; RUN: clspv-opt %s -o %t.ll --passes=long-vector-lowering
; RUN: FileCheck %s < %t.ll

; CHECK-NOT: <8 x float>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  br label %loop

loop:
  %phi_a = phi <8 x float> [ zeroinitializer, %entry ], [ %next_a, %loop ]
  %phi_b = phi <8 x float> [ zeroinitializer, %entry ], [ %next_b, %loop ]
  %mul = fmul <8 x float> %phi_a, %phi_b
  %next_a = fadd <8 x float> %mul, zeroinitializer
  %next_b = fadd <8 x float> %mul, zeroinitializer
  br i1 undef, label %loop, label %exit

exit:
  ret void
}
