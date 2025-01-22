; RUN: clspv-opt --passes=fixup-structured-cfg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: entry:
; CHECK-NEXT: br label %[[new_header:[a-zA-Z0-9_.]+]]
; CHECK: [[new_header]]:
; CHECK-NEXT: phi i32 [ 0, %entry ], [ 1, %[[cont:[a-zA-Z0-9_.]+]] ]
; CHECK-NEXT: br label %loop
; CHECK: loop:
; CHECK-NEXT: br i1 undef, label %then, label %[[pre_cont:[a-zA-Z0-9_.]+]]
; CHECK: then:
; CHECK-NEXT: br label %[[pre_cont]]
; CHECK: [[pre_cont]]:
; CHECK: call void @_Z8spirv.op.224
; CHECK-NEXT: br i1 undef, label %[[cont]], label %exit
; CHECK: [[cont]]:
; CHECK-NEXT: br label %[[new_header]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test() {
entry:
  br label %loop

loop:
  %0 = phi i32 [ 0, %entry ], [ 1, %cont ]
  br i1 undef, label %then, label %cont

then:
  br label %cont

cont:
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #0
  br i1 undef, label %loop, label %exit

exit:
  ret void
}

attributes #0 = { convergent }

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) #0

