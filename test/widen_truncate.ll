; RUN: clspv-opt -UndoTruncatedSwitchCondition %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(float addrspace(1)* nocapture %output, i32 %arg) {
entry:
  ; CHECK-LABEL foo
  ; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i32 %arg, 3
  ; CHECK-NEXT: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[and]], 2
  ; CHECK-NEXT: [[sel1:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]],
  ; CHECK-NEXT: [[cmp:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[and]], 1
  ; CHECK-NEXT: [[sel:%[a-zA-Z0-9_.]+]] = select i1 [[cmp]],
  %trunc = trunc i32 %arg to i2
  %switch.selectcmp = icmp eq i2 %trunc, -2
  %switch.select = select i1 %switch.selectcmp, float 4.000000e+00, float 0.000000e+00
  %switch.selectcmp2 = icmp eq i2 %trunc, 1
  %switch.select3 = select i1 %switch.selectcmp2, float 2.000000e+00, float %switch.select
  %arrayidx = getelementptr inbounds float, float addrspace(1)* %output, i32 %arg
  store float %switch.select3, float addrspace(1)* %arrayidx, align 4
  ret void
}

