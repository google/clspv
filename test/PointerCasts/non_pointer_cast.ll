; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; Ensure the pass doesn't crash on this input and properly simplifies the cast.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test(float %x) {
entry:
  %y = bitcast float %x to i32
  %z = bitcast i32 %y to <2 x i16>
  ret void
}

; CHECK-LABEL: @test
; CHECK-SAME: (float [[X:%[^ ]+]])
; CHECK: [[Y:%[^ ]+]] = bitcast float [[X]] to <2 x i16>
; CHECK-NOT: bitcast
