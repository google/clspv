; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: entry:
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr [100 x i32], ptr @.my_constant, i32 0, i32 7
; CHECK: phi ptr [ [[gep]], %entry ]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@.my_constant = global [100 x i32] zeroinitializer

define void @test(i32 %n, i32 %m) {
entry:
  br label %exit

exit:
  %phi = phi ptr [ getelementptr (i32, ptr @.my_constant, i32 7), %entry ]
  ret void
}
