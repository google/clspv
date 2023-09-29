; RUN: clspv-opt %s -o %t.ll --passes=fixup-structured-cfg
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define dso_local spir_kernel void @foo(i1 %cmp1, i1 %cmp2, i1 %cmp3) {
entry:
; CHECK: [[alloca:%[^ ]+]] = alloca i32, align 4
  %alloca = alloca i32, align 4
  br i1 %cmp1, label %b1, label %b2

; CHECK: b1:
; CHECK-NEXT: br
b1:
  %b1_phi = phi ptr [ undef, %entry ], [ %b2_phi, %b2 ]
  br i1 %cmp2, label %b2, label %exit

; CHECK: b2:
; CHECK-NEXT: br
b2:
  %b2_phi = phi ptr [ undef, %entry ], [ %b1_phi, %b1 ]
  br i1 %cmp3, label %b1, label %exit

; CHECK: exit:
; CHECK-NEXT: phi ptr [ undef, %b1 ], [ [[alloca]], %b2 ]
exit:
  %exit_phi = phi ptr [ %b1_phi, %b1 ], [ %alloca, %b2 ]
  ret void
}
