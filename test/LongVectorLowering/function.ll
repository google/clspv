; RUN: clspv-opt --LongVectorLowering --early-cse --instcombine %s -o %t
; RUN: FileCheck %s < %t

; Test that function arguments and return types can be lowered.
; Rely on CSE and InstCombine to simplify the generated IR.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x float> @test(<8 x float> %x) !info !0 {
  ret <8 x float> %x
}

!0 = !{!"some metadata"}

; CHECK-NOT: <8 x float>
;
; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT8:{ float, float, float, float, float, float, float, float }]]
; CHECK-SAME: @test([[FLOAT8]] [[X:%[^ ]+]]) !info [[MD:![0-9]+]]
; CHECK-NEXT: ret [[FLOAT8]] [[X]]
;
; CHECK-NOT: <8 x float>
; CHECK-NOT: define
;
; CHECK: [[MD]] = !{!"some metadata"}
