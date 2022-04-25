; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func <8 x i1> @test(<8 x i32> %a) {
entry:
  %cmp = icmp slt <8 x i32> %a, zeroinitializer
  ret <8 x i1> %cmp
}

; CHECK-NOT: <8 x i32>

; CHECK-LABEL: @test
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32
; CHECK: icmp slt i32

; CHECK-NOT: <8 x i32>
