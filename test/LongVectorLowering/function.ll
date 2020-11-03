; RUN: clspv-opt --LongVectorLowering --early-cse --instcombine %s -o %t
; RUN: FileCheck %s < %t

; Test that function arguments and return types can be lowered;
; also cover function calls.
; Rely on CSE and InstCombine to simplify the generated IR.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; @foo doesn't require any lowering
define spir_func i32 @foo() {
  ret i32 42
}

; @id requires lowering for parameter and return types
define spir_func <8 x float> @id(<8 x float> %x) {
  ret <8 x float> %x
}

; @test1 requires lowering for parameter and return types, and call instruction.
; Ensures metadata is preserved.
define spir_func <8 x float> @test1(<8 x float> %x) !info !0 {
  %y = call spir_func <8 x float> @id(<8 x float> %x), !info !0
  ret <8 x float> %y
}

; @test2 requires lowering for return type, but not for call instruction.
define spir_func <8 x i32> @test2(i32 %a) {
  %b = call spir_func i32 @foo()
  %c = add i32 %a, %b
  %d = insertelement <8 x i32> undef, i32 %c, i32 0
  %e = shufflevector <8 x i32> %d, <8 x i32> undef, <8 x i32> zeroinitializer
  ret <8 x i32> %e
}

!0 = !{!"some metadata"}

; CHECK-NOT: <8 x float>
; CHECK-NOT: <8 x i32>
;
; CHECK-LABEL: define spir_func
; CHECK-SAME: [[INT8:{ i32, i32, i32, i32, i32, i32, i32, i32 }]]
; CHECK-SAME: @test2(i32 {{%[^ ]+}})
; CHECK-NEXT: call spir_func i32 @foo()
; CHECK: ret [[INT8]] {{%[^ ]+}}
;
; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT8:{ float, float, float, float, float, float, float, float }]]
; CHECK-SAME: @test1([[FLOAT8]] [[X:%[^ ]+]])
; CHECK-SAME: !info [[MD:![0-9]+]]
; CHECK-NEXT: [[Y:%[^ ]+]] = call spir_func [[FLOAT8]] @id([[FLOAT8]] [[X]])
; CHECK-SAME: !info [[MD]]
; CHECK-NEXT: ret [[FLOAT8]] [[Y]]
;
; CHECK-LABEL: define spir_func
; CHECK-SAME: [[FLOAT8]] @id([[FLOAT8]] [[X:%[^ ]+]])
; CHECK-NEXT: ret [[FLOAT8]] [[X]]
;
; CHECK: [[MD]] = !{!"some metadata"}
